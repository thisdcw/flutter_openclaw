import 'package:flutter/foundation.dart';

import '../models/app_error_notice.dart';
import 'app_error_controller.dart';
import '../../domain/models/chat_conversation_record.dart';
import '../../domain/models/chat_conversation_summary.dart';
import '../../domain/models/chat_draft.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/gateway_config.dart';
import '../../domain/models/chat_store_snapshot.dart';
import '../../domain/repositories/chat_conversation_store.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../infrastructure/util/openclaw_logger.dart';
import '../use_cases/send_chat_message_use_case.dart';

class ChatController extends ChangeNotifier {
  ChatController({
    ChatRepository? chatRepository,
    SendChatMessageUseCase? sendChatMessageUseCase,
    GatewayConfig Function()? configProvider,
    ChatConversationStore? conversationStore,
    ChatStoreSnapshot? initialSnapshot,
    AppErrorController? appErrorController,
    Future<void> Function(String sessionId)? activeSessionSync,
    bool isStub = false,
  }) : _chatRepository = chatRepository,
       _sendChatMessageUseCase = sendChatMessageUseCase,
       _configProvider = configProvider,
       _conversationStore = conversationStore,
       _conversationSummaries = List<ChatConversationSummary>.from(
         initialSnapshot?.conversationSummaries ??
             const <ChatConversationSummary>[],
       ),
       _activeConversation = initialSnapshot?.activeConversation,
       _appErrorController = appErrorController,
       _activeSessionSync = activeSessionSync,
       _isStub = isStub;

  factory ChatController.fake() => ChatController(isStub: true);

  final ChatRepository? _chatRepository;
  final SendChatMessageUseCase? _sendChatMessageUseCase;
  final GatewayConfig Function()? _configProvider;
  final ChatConversationStore? _conversationStore;
  final AppErrorController? _appErrorController;
  final Future<void> Function(String sessionId)? _activeSessionSync;
  final bool _isStub;
  final List<ChatConversationSummary> _conversationSummaries;
  ChatConversationRecord? _activeConversation;

  bool isSending = false;
  String? errorMessage;
  AppErrorNotice? errorNotice;

  bool get isStub => _isStub;

  List<ChatConversationSummary> get conversationSummaries =>
      List<ChatConversationSummary>.unmodifiable(_conversationSummaries);

  ChatConversationSummary? get activeConversationSummary =>
      _activeConversation?.summary;

  String get activeSessionId => _activeConversation?.summary.sessionId ?? '';

  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(
    _activeConversation?.messages ?? const <ChatMessage>[],
  );

  Future<void> createConversation() async {
    final store = _conversationStore;
    if (_isStub || store == null) {
      _replaceActiveConversation(
        ChatStoreSnapshot(
          activeConversation: ChatConversationRecord(
            summary: ChatConversationSummary(
              id: 'stub-conversation',
              sessionId: 'stub-session',
              title: 'New chat',
              previewText: '',
              updatedAtMs: DateTime.now().millisecondsSinceEpoch,
              messageCount: 0,
            ),
            messages: const <ChatMessage>[],
          ),
          conversationSummaries: const <ChatConversationSummary>[],
        ),
      );
      return;
    }
    final snapshot = await store.createConversation();
    _replaceActiveConversation(snapshot);
    await _syncActiveSession();
  }

  Future<void> switchConversation(String conversationId) async {
    final store = _conversationStore;
    if (store == null || _activeConversation?.summary.id == conversationId) {
      return;
    }
    final snapshot = await store.activateConversation(conversationId);
    _replaceActiveConversation(snapshot);
    await _syncActiveSession();
  }

  Future<void> renameConversationTitle({
    required String conversationId,
    required String title,
  }) async {
    final normalized = title.trim();
    if (normalized.isEmpty) {
      throw StateError('会话标题不能为空。');
    }
    final store = _conversationStore;
    if (_isStub || store == null) {
      final summaryIndex = _conversationSummaries.indexWhere(
        (summary) => summary.id == conversationId,
      );
      if (summaryIndex == -1) {
        return;
      }
      final updatedSummary = _conversationSummaries[summaryIndex].copyWith(
        title: _truncate(normalized, maxLength: 32),
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
        isTitleManuallyEdited: true,
      );
      _conversationSummaries[summaryIndex] = updatedSummary;
      if (_activeConversation?.summary.id == conversationId) {
        _activeConversation = _activeConversation?.copyWith(
          summary: updatedSummary,
        );
      }
      _replaceSummary(updatedSummary);
      notifyListeners();
      return;
    }
    final snapshot = await store.renameConversationTitle(
      conversationId: conversationId,
      title: normalized,
    );
    _replaceActiveConversation(snapshot);
  }

  Future<void> renameActiveConversationTitle(String title) async {
    final active = _activeConversation;
    if (active == null) {
      return;
    }
    await renameConversationTitle(
      conversationId: active.summary.id,
      title: title,
    );
  }

  Future<void> send(ChatDraft draft) async {
    if (!draft.hasSendableContent) {
      openClawLog('ChatController', 'send ignored: empty draft');
      return;
    }

    final normalized = draft.normalizedText;
    final shouldCreateFreshConversation = _shouldCreateFreshConversation(
      normalized,
    );
    openClawLog(
      'ChatController',
      'send begin',
      fields: <String, Object?>{
        'messageLength': normalized.length,
        'attachmentCount': draft.attachments.length,
        'preview': truncateForLog(normalized, maxLength: 80),
        'createFreshConversation': shouldCreateFreshConversation,
      },
    );

    if (shouldCreateFreshConversation) {
      await createConversation();
      return;
    }

    isSending = true;
    errorMessage = null;
    errorNotice = null;
    _upsertLocalMessage(
      ChatMessage(
        id: 'user-${DateTime.now().microsecondsSinceEpoch}',
        role: MessageRole.user,
        text: normalized,
        attachments: draft.attachments,
      ),
    );
    await _persistActiveConversation();
    notifyListeners();

    final repository = _chatRepository;
    final sendChatMessageUseCase = _sendChatMessageUseCase;
    final configProvider = _configProvider;
    final hasUseCase = sendChatMessageUseCase != null && configProvider != null;
    final hasRepository = repository != null && activeSessionId.isNotEmpty;
    if (!hasUseCase && !hasRepository) {
      openClawLog(
        'ChatController',
        'send skipped: missing send pathway',
        fields: <String, Object?>{
          'hasUseCase': hasUseCase,
          'hasRepository': hasRepository,
          'activeSessionId': activeSessionId,
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
      final sessionId = activeSessionId;
      final stream = hasUseCase
          ? sendChatMessageUseCase.call(
              draft,
              config: configProvider(),
              sessionId: sessionId,
            )
          : repository!.sendMessage(draft, sessionId: sessionId);

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
        await _persistActiveConversation();
      }
    } catch (error) {
      final rawReason = error.toString();
      _removeEmptyStreamingAssistantMessage();
      await _persistActiveConversation();
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
          errorNotice!.copyWith(presentation: AppErrorPresentation.global),
        );
      }
      openClawLog(
        'ChatController',
        'send failed',
        fields: <String, Object?>{'error': rawReason},
      );
      notifyListeners();
    } finally {
      isSending = false;
      openClawLog('ChatController', 'send end');
      notifyListeners();
    }
  }

  void _upsertLocalMessage(ChatMessage message) {
    final active = _requireActiveConversation();
    final nextMessages = <ChatMessage>[...active.messages, message];
    _activeConversation = active.copyWith(messages: nextMessages);
  }

  void _upsertAssistantMessage(ChatMessage message) {
    final active = _requireActiveConversation();
    final nextMessages = List<ChatMessage>.from(active.messages);
    final index = nextMessages.indexWhere((entry) => entry.id == message.id);
    if (index == -1) {
      nextMessages.add(message);
    } else {
      nextMessages[index] = message;
    }
    _activeConversation = active.copyWith(messages: nextMessages);
    notifyListeners();
  }

  void _removeEmptyStreamingAssistantMessage() {
    final active = _activeConversation;
    if (active == null) {
      return;
    }
    final nextMessages = active.messages
        .where(
          (message) =>
              !(message.role == MessageRole.assistant &&
                  message.isStreaming &&
                  message.text.isEmpty),
        )
        .toList(growable: false);
    _activeConversation = active.copyWith(messages: nextMessages);
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
        errorNotice!.copyWith(presentation: AppErrorPresentation.global),
      );
    }
    notifyListeners();
  }

  Future<void> _persistActiveConversation() async {
    final store = _conversationStore;
    final active = _activeConversation;
    if (store == null || active == null) {
      return;
    }
    final nextSummary = _summarize(active.summary, active.messages);
    final nextRecord = active.copyWith(summary: nextSummary);
    _activeConversation = nextRecord;
    await store.saveConversation(nextRecord);
    if (_hasConversationContent(nextRecord.messages)) {
      _replaceSummary(nextSummary);
    } else {
      _removeSummary(nextSummary.id);
    }
  }

  void _replaceActiveConversation(ChatStoreSnapshot snapshot) {
    _activeConversation = snapshot.activeConversation;
    _conversationSummaries
      ..clear()
      ..addAll(snapshot.conversationSummaries);
    if (_hasConversationContent(snapshot.activeConversation.messages)) {
      _replaceSummary(snapshot.activeConversation.summary);
    } else {
      _removeSummary(snapshot.activeConversation.summary.id);
    }
    notifyListeners();
  }

  void _replaceSummary(ChatConversationSummary summary) {
    if (summary.messageCount <= 0) {
      _removeSummary(summary.id);
      return;
    }
    _conversationSummaries.removeWhere((item) => item.id == summary.id);
    _conversationSummaries.insert(0, summary);
    _conversationSummaries.sort(
      (left, right) => right.updatedAtMs.compareTo(left.updatedAtMs),
    );
  }

  void _removeSummary(String conversationId) {
    _conversationSummaries.removeWhere((item) => item.id == conversationId);
  }

  ChatConversationSummary _summarize(
    ChatConversationSummary base,
    List<ChatMessage> messages,
  ) {
    final firstUserText = messages
        .where((message) => message.role == MessageRole.user)
        .map((message) => message.text.trim())
        .firstWhere((text) => text.isNotEmpty, orElse: () => '');
    final preview = messages.reversed
        .map((message) => message.text.trim())
        .firstWhere((text) => text.isNotEmpty, orElse: () => '');
    final title = base.isTitleManuallyEdited
        ? base.title
        : (firstUserText.isEmpty
              ? 'New chat'
              : _truncate(firstUserText, maxLength: 32));
    return base.copyWith(
      title: title,
      previewText: preview.isEmpty ? '' : _truncate(preview, maxLength: 60),
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      messageCount: messages.length,
    );
  }

  Future<void> _syncActiveSession() async {
    final sessionId = activeSessionId;
    if (sessionId.isEmpty) {
      return;
    }
    await _activeSessionSync?.call(sessionId);
  }

  ChatConversationRecord _requireActiveConversation() {
    final active = _activeConversation;
    if (active != null) {
      return active;
    }
    final fallback = ChatConversationRecord(
      summary: ChatConversationSummary(
        id: 'fallback',
        sessionId: 'fallback',
        title: 'New chat',
        previewText: '',
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
        messageCount: 0,
      ),
      messages: const <ChatMessage>[],
    );
    _activeConversation = fallback;
    return fallback;
  }

  static bool _shouldCreateFreshConversation(String normalizedText) {
    return normalizedText == '/new' || normalizedText == '/reset';
  }

  static bool _hasConversationContent(List<ChatMessage> messages) {
    return messages.any(
      (message) =>
          message.text.trim().isNotEmpty || message.attachments.isNotEmpty,
    );
  }

  static String _truncate(String value, {required int maxLength}) {
    final normalized = value.replaceAll('\n', ' ').trim();
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return '${normalized.substring(0, maxLength - 1)}…';
  }

  String _nextErrorId() {
    return _appErrorController?.nextId() ??
        'chat-error-${DateTime.now().microsecondsSinceEpoch}';
  }
}
