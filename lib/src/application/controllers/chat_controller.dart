import 'package:flutter/foundation.dart';

import '../models/app_error_notice.dart';
import 'app_error_controller.dart';
import '../../domain/models/chat_draft.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/gateway_config.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../infrastructure/util/openclaw_logger.dart';
import '../use_cases/send_chat_message_use_case.dart';

class ChatController extends ChangeNotifier {
  ChatController({
    ChatRepository? chatRepository,
    SendChatMessageUseCase? sendChatMessageUseCase,
    GatewayConfig Function()? configProvider,
    String Function()? sessionIdProvider,
    AppErrorController? appErrorController,
    bool isStub = false,
  })  : _chatRepository = chatRepository,
        _sendChatMessageUseCase = sendChatMessageUseCase,
        _configProvider = configProvider,
        _sessionIdProvider = sessionIdProvider,
        _appErrorController = appErrorController,
        _isStub = isStub;

  factory ChatController.fake() => ChatController(isStub: true);

  final ChatRepository? _chatRepository;
  final SendChatMessageUseCase? _sendChatMessageUseCase;
  final GatewayConfig Function()? _configProvider;
  final String Function()? _sessionIdProvider;
  final AppErrorController? _appErrorController;
  final bool _isStub;
  final List<ChatMessage> _messages = <ChatMessage>[];

  bool isSending = false;
  String? errorMessage;
  AppErrorNotice? errorNotice;

  bool get isStub => _isStub;

  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);

  Future<void> send(ChatDraft draft) async {
    if (!draft.hasSendableContent) {
      openClawLog('ChatController', 'send ignored: empty draft');
      return;
    }

    final normalized = draft.normalizedText;
    final shouldClearLocalHistory = _shouldClearLocalHistory(normalized);
    openClawLog(
      'ChatController',
      'send begin',
      fields: <String, Object?>{
        'messageLength': normalized.length,
        'attachmentCount': draft.attachments.length,
        'preview': truncateForLog(normalized, maxLength: 80),
        'clearLocalHistory': shouldClearLocalHistory,
      },
    );

    isSending = true;
    errorMessage = null;
    errorNotice = null;
    if (shouldClearLocalHistory) {
      _messages.clear();
    }
    _messages.add(
      ChatMessage(
        id: 'user-${_messages.length}',
        role: MessageRole.user,
        text: normalized,
        attachments: draft.attachments,
      ),
    );
    notifyListeners();

    final repository = _chatRepository;
    final sendChatMessageUseCase = _sendChatMessageUseCase;
    final configProvider = _configProvider;
    final sessionIdProvider = _sessionIdProvider;
    final hasUseCase = sendChatMessageUseCase != null && configProvider != null;
    final hasRepository = repository != null;
    final canUseRepository = hasRepository && sessionIdProvider != null;
    if (!hasUseCase && !canUseRepository) {
      openClawLog(
        'ChatController',
        'send skipped: missing send pathway',
        fields: <String, Object?>{
          'hasUseCase': hasUseCase,
          'hasRepository': hasRepository,
          'hasSessionIdProvider': sessionIdProvider != null,
        },
      );
      isSending = false;
      errorMessage = null;
      errorNotice = null;
      notifyListeners();
      return;
    }

    try {
      errorMessage = null;
      errorNotice = null;
      final stream = hasUseCase
          ? sendChatMessageUseCase.call(
              draft,
              config: configProvider(),
            )
          : repository!.sendMessage(
              draft,
              sessionId: sessionIdProvider!(),
            );

      await for (final message in stream) {
        openClawLog(
          'ChatController',
          'message update',
          fields: <String, Object?>{
            'id': message.id,
            'role': message.role.value,
            'isStreaming': message.isStreaming,
            'textLength': message.text.length,
          },
        );
        _upsertAssistantMessage(message);
      }
    } catch (error) {
      final rawReason = error.toString();
      _messages.removeWhere(
        (message) =>
            message.role == MessageRole.assistant &&
            message.isStreaming &&
            message.text.isEmpty,
      );
      errorMessage = rawReason;
      errorNotice = AppErrorNotice.fromRaw(
        id: _nextErrorId(),
        scope: AppErrorScope.chat,
        presentation: AppErrorPresentation.inline,
        rawMessage: rawReason,
        code: 'CHAT_SEND_FAILED',
      );
      if (errorNotice!.kind == AppErrorKind.unexpected) {
        _appErrorController?.publish(
          errorNotice!.copyWith(
            presentation: AppErrorPresentation.global,
          ),
        );
      }
      openClawLog(
        'ChatController',
        'send failed',
        fields: <String, Object?>{
          'error': rawReason,
        },
      );
      notifyListeners();
    } finally {
      isSending = false;
      openClawLog('ChatController', 'send end');
      notifyListeners();
    }
  }

  void _upsertAssistantMessage(ChatMessage message) {
    final index = _messages.indexWhere((entry) => entry.id == message.id);
    if (index == -1) {
      _messages.add(message);
    } else {
      _messages[index] = message;
    }
    notifyListeners();
  }

  void showInlineError({
    required AppErrorKind kind,
    required String rawMessage,
    String? code,
    bool reportGlobally = false,
  }) {
    errorMessage = rawMessage;
    errorNotice = AppErrorNotice.fromRaw(
      id: _nextErrorId(),
      scope: AppErrorScope.chat,
      presentation: AppErrorPresentation.inline,
      rawMessage: rawMessage,
      code: code,
      kind: kind,
    );
    if (reportGlobally) {
      _appErrorController?.publish(
        errorNotice!.copyWith(
          presentation: AppErrorPresentation.global,
        ),
      );
    }
    notifyListeners();
  }

  static bool _shouldClearLocalHistory(String normalizedText) {
    return normalizedText == '/new';
  }

  String _nextErrorId() {
    return _appErrorController?.nextId() ??
        'chat-error-${DateTime.now().microsecondsSinceEpoch}';
  }
}
