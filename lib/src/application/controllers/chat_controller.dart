import 'package:flutter/foundation.dart';

import '../../domain/models/chat_draft.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/gateway_config.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../infrastructure/util/failure_mapper.dart';
import '../../infrastructure/util/openclaw_logger.dart';
import '../use_cases/send_chat_message_use_case.dart';

class ChatController extends ChangeNotifier {
  ChatController({
    ChatRepository? chatRepository,
    SendChatMessageUseCase? sendChatMessageUseCase,
    GatewayConfig Function()? configProvider,
    String Function()? sessionIdProvider,
    bool isStub = false,
  })  : _chatRepository = chatRepository,
        _sendChatMessageUseCase = sendChatMessageUseCase,
        _configProvider = configProvider,
        _sessionIdProvider = sessionIdProvider,
        _isStub = isStub;

  factory ChatController.fake() => ChatController(isStub: true);

  final ChatRepository? _chatRepository;
  final SendChatMessageUseCase? _sendChatMessageUseCase;
  final GatewayConfig Function()? _configProvider;
  final String Function()? _sessionIdProvider;
  final bool _isStub;
  final List<ChatMessage> _messages = <ChatMessage>[];

  bool isSending = false;
  String? errorMessage;

  bool get isStub => _isStub;

  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);

  Future<void> send(ChatDraft draft) async {
    if (!draft.hasSendableContent) {
      openClawLog('ChatController', 'send ignored: empty draft');
      return;
    }

    final normalized = draft.normalizedText;
    openClawLog(
      'ChatController',
      'send begin',
      fields: <String, Object?>{
        'messageLength': normalized.length,
        'attachmentCount': draft.attachments.length,
        'preview': truncateForLog(normalized, maxLength: 80),
      },
    );

    isSending = true;
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
      notifyListeners();
      return;
    }

    try {
      errorMessage = null;
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
      _messages.removeWhere(
        (message) =>
            message.role == MessageRole.assistant &&
            message.isStreaming &&
            message.text.isEmpty,
      );
      errorMessage = mapGatewayFailure(
        code: 'CHAT_SEND_FAILED',
        reason: error.toString(),
      );
      openClawLog(
        'ChatController',
        'send failed',
        fields: <String, Object?>{
          'error': error.toString(),
          'mapped': errorMessage,
        },
      );
      _messages.add(
        ChatMessage(
          id: 'error-${_messages.length}',
          role: MessageRole.error,
          text: errorMessage!,
        ),
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
}
