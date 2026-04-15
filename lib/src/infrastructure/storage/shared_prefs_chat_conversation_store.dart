import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/chat_conversation_record.dart';
import '../../domain/models/chat_conversation_summary.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_store_snapshot.dart';
import '../../domain/repositories/chat_conversation_store.dart';

class SharedPrefsChatConversationStore implements ChatConversationStore {
  SharedPrefsChatConversationStore(this._prefs, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final SharedPreferences _prefs;
  final Uuid _uuid;

  static const String _indexKey = 'chat_store_index';
  static const int _schemaVersion = 1;

  @override
  Future<ChatStoreSnapshot> bootstrap() async {
    final index = _loadIndex();
    if (index == null) {
      final initial = _buildConversationRecord();
      return ChatStoreSnapshot(
        activeConversation: initial,
        conversationSummaries: const <ChatConversationSummary>[],
      );
    }

    final baseSummaries = _sanitizeSummaries(index.summaries);
    ChatConversationRecord activeConversation =
        index.activeConversationId.isNotEmpty
        ? (_loadConversation(index.activeConversationId) ??
              _loadFirstAvailableConversation(baseSummaries) ??
              _buildConversationRecord())
        : (_loadFirstAvailableConversation(baseSummaries) ??
              _buildConversationRecord());
    var nextSummaries = baseSummaries;
    if (_hasConversationContent(activeConversation.messages)) {
      final summarized = _summarizeConversation(
        activeConversation.summary,
        activeConversation.messages,
      );
      activeConversation = activeConversation.copyWith(summary: summarized);
      await _saveConversationRecord(activeConversation);
      nextSummaries = _upsertSummary(nextSummaries, summarized);
    }
    final nextIndex = _ChatStoreIndex(
      schemaVersion: _schemaVersion,
      activeConversationId: _hasConversationContent(activeConversation.messages)
          ? activeConversation.summary.id
          : '',
      summaries: nextSummaries,
    );
    await _saveIndex(nextIndex);
    return ChatStoreSnapshot(
      activeConversation: activeConversation,
      conversationSummaries: nextSummaries,
    );
  }

  @override
  Future<ChatStoreSnapshot> createConversation() async {
    final index = _loadIndex() ?? _emptyIndex();
    final nextSummaries = _sanitizeSummaries(index.summaries);
    final conversation = _buildConversationRecord();
    final nextIndex = _ChatStoreIndex(
      schemaVersion: _schemaVersion,
      activeConversationId:
          nextSummaries.any(
            (summary) => summary.id == index.activeConversationId,
          )
          ? index.activeConversationId
          : '',
      summaries: nextSummaries,
    );
    await _saveIndex(nextIndex);
    return ChatStoreSnapshot(
      activeConversation: conversation,
      conversationSummaries: nextSummaries,
    );
  }

  @override
  Future<ChatStoreSnapshot> activateConversation(String conversationId) async {
    final index = _loadIndex() ?? _emptyIndex();
    final baseSummaries = _sanitizeSummaries(index.summaries);
    ChatConversationRecord activeConversation =
        _loadConversation(conversationId) ?? _buildConversationRecord();
    var nextSummaries = baseSummaries;
    if (_hasConversationContent(activeConversation.messages)) {
      final summarized = _summarizeConversation(
        activeConversation.summary,
        activeConversation.messages,
      );
      activeConversation = activeConversation.copyWith(summary: summarized);
      await _saveConversationRecord(activeConversation);
      nextSummaries = _upsertSummary(nextSummaries, summarized);
    }
    final nextIndex = _ChatStoreIndex(
      schemaVersion: _schemaVersion,
      activeConversationId: _hasConversationContent(activeConversation.messages)
          ? activeConversation.summary.id
          : '',
      summaries: nextSummaries,
    );
    await _saveIndex(nextIndex);
    return ChatStoreSnapshot(
      activeConversation: activeConversation,
      conversationSummaries: nextSummaries,
    );
  }

  @override
  Future<ChatStoreSnapshot> renameConversationTitle({
    required String conversationId,
    required String title,
  }) async {
    final normalized = title.trim();
    if (normalized.isEmpty) {
      throw StateError('会话标题不能为空。');
    }
    final index = _loadIndex() ?? _emptyIndex();
    final targetConversation = _loadConversation(conversationId);
    if (targetConversation == null) {
      throw StateError('Conversation "$conversationId" does not exist.');
    }
    if (!_hasConversationContent(targetConversation.messages)) {
      throw StateError('空会话不支持重命名。');
    }
    final updatedSummary = targetConversation.summary.copyWith(
      title: _truncate(normalized, maxLength: 32),
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      isTitleManuallyEdited: true,
    );
    final updatedConversation = targetConversation.copyWith(
      summary: updatedSummary,
    );
    await _saveConversationRecord(updatedConversation);
    final nextSummaries = _upsertSummary(
      _sanitizeSummaries(index.summaries),
      updatedSummary,
    );

    final currentActiveId = index.activeConversationId.isEmpty
        ? updatedSummary.id
        : index.activeConversationId;
    final nextActiveConversation = currentActiveId == updatedSummary.id
        ? updatedConversation
        : (_loadConversation(currentActiveId) ??
              _loadFirstAvailableConversation(nextSummaries) ??
              updatedConversation);
    final nextIndex = _ChatStoreIndex(
      schemaVersion: _schemaVersion,
      activeConversationId:
          _hasConversationContent(nextActiveConversation.messages)
          ? nextActiveConversation.summary.id
          : '',
      summaries: nextSummaries,
    );
    await _saveIndex(nextIndex);
    return ChatStoreSnapshot(
      activeConversation: nextActiveConversation,
      conversationSummaries: nextSummaries,
    );
  }

  @override
  Future<void> saveConversation(ChatConversationRecord conversation) async {
    final index = _loadIndex() ?? _emptyIndex();
    final baseSummaries = _sanitizeSummaries(index.summaries);
    final updatedSummary = _summarizeConversation(
      conversation.summary.copyWith(
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
      conversation.messages,
    );
    final nextConversation = conversation.copyWith(summary: updatedSummary);
    if (!_hasConversationContent(nextConversation.messages)) {
      await _removeConversationRecord(nextConversation.summary.id);
      final nextSummaries = baseSummaries
          .where((summary) => summary.id != nextConversation.summary.id)
          .toList(growable: false);
      final nextActiveId =
          index.activeConversationId == nextConversation.summary.id
          ? (nextSummaries.isEmpty ? '' : nextSummaries.first.id)
          : (nextSummaries.any(
                  (summary) => summary.id == index.activeConversationId,
                )
                ? index.activeConversationId
                : '');
      final nextIndex = _ChatStoreIndex(
        schemaVersion: _schemaVersion,
        activeConversationId: nextActiveId,
        summaries: nextSummaries,
      );
      await _saveIndex(nextIndex);
      return;
    }

    await _saveConversationRecord(nextConversation);
    final nextSummaries = _upsertSummary(baseSummaries, updatedSummary);
    final nextIndex = _ChatStoreIndex(
      schemaVersion: _schemaVersion,
      activeConversationId:
          index.activeConversationId.isEmpty ||
              !nextSummaries.any(
                (summary) => summary.id == index.activeConversationId,
              )
          ? updatedSummary.id
          : index.activeConversationId,
      summaries: nextSummaries,
    );
    await _saveIndex(nextIndex);
  }

  ChatConversationRecord _buildConversationRecord() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    return ChatConversationRecord(
      summary: ChatConversationSummary(
        id: id,
        sessionId: _uuid.v4(),
        title: 'New chat',
        previewText: '',
        updatedAtMs: now,
        messageCount: 0,
      ),
      messages: const <ChatMessage>[],
    );
  }

  Future<void> _saveConversationRecord(
    ChatConversationRecord conversation,
  ) async {
    final key = _conversationKey(conversation.summary.id);
    final encoded = jsonEncode(<String, dynamic>{
      'summary': conversation.summary.toJson(),
      'messages': conversation.messages
          .map((message) => message.toJson())
          .toList(),
    });
    await _prefs.setString(key, encoded);
  }

  Future<void> _removeConversationRecord(String conversationId) async {
    await _prefs.remove(_conversationKey(conversationId));
  }

  ChatConversationRecord? _loadConversation(String conversationId) {
    final raw = _prefs.getString(_conversationKey(conversationId));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final summary = ChatConversationSummary.fromJson(
      Map<String, dynamic>.from(decoded['summary'] as Map),
    );
    final rawMessages = decoded['messages'];
    final messages = <ChatMessage>[];
    if (rawMessages is List) {
      for (final rawMessage in rawMessages) {
        if (rawMessage is Map) {
          messages.add(
            ChatMessage.fromJson(Map<String, dynamic>.from(rawMessage)),
          );
        }
      }
    }
    return ChatConversationRecord(summary: summary, messages: messages);
  }

  _ChatStoreIndex? _loadIndex() {
    final raw = _prefs.getString(_indexKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return _ChatStoreIndex.fromJson(decoded);
  }

  Future<void> _saveIndex(_ChatStoreIndex index) async {
    await _prefs.setString(_indexKey, jsonEncode(index.toJson()));
  }

  _ChatStoreIndex _emptyIndex() {
    return const _ChatStoreIndex(
      schemaVersion: _schemaVersion,
      activeConversationId: '',
      summaries: <ChatConversationSummary>[],
    );
  }

  List<ChatConversationSummary> _upsertSummary(
    List<ChatConversationSummary> existing,
    ChatConversationSummary summary,
  ) {
    final next = <ChatConversationSummary>[
      if (_isPersistableSummary(summary)) summary,
      ...existing.where((item) => item.id != summary.id),
    ];
    return _sanitizeSummaries(next);
  }

  ChatConversationSummary _summarizeConversation(
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
      messageCount: messages.length,
    );
  }

  String _conversationKey(String conversationId) =>
      'chat_conversation_$conversationId';

  ChatConversationRecord? _loadFirstAvailableConversation(
    List<ChatConversationSummary> summaries,
  ) {
    for (final summary in summaries) {
      final record = _loadConversation(summary.id);
      if (record != null) {
        return record;
      }
    }
    return null;
  }

  List<ChatConversationSummary> _sanitizeSummaries(
    List<ChatConversationSummary> summaries,
  ) {
    final next = summaries.where(_isPersistableSummary).toList(growable: false);
    final sorted = List<ChatConversationSummary>.from(next);
    sorted.sort((left, right) => right.updatedAtMs.compareTo(left.updatedAtMs));
    return sorted;
  }

  bool _isPersistableSummary(ChatConversationSummary summary) {
    return summary.messageCount > 0;
  }

  bool _hasConversationContent(List<ChatMessage> messages) {
    return messages.any(
      (message) =>
          message.text.trim().isNotEmpty || message.attachments.isNotEmpty,
    );
  }

  String _truncate(String value, {required int maxLength}) {
    final normalized = value.replaceAll('\n', ' ').trim();
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return '${normalized.substring(0, maxLength - 1)}…';
  }
}

class _ChatStoreIndex {
  const _ChatStoreIndex({
    required this.schemaVersion,
    required this.activeConversationId,
    required this.summaries,
  });

  final int schemaVersion;
  final String activeConversationId;
  final List<ChatConversationSummary> summaries;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'activeConversationId': activeConversationId,
      'summaries': summaries.map((summary) => summary.toJson()).toList(),
    };
  }

  factory _ChatStoreIndex.fromJson(Map<String, dynamic> json) {
    final rawSummaries = json['summaries'];
    final summaries = <ChatConversationSummary>[];
    if (rawSummaries is List) {
      for (final rawSummary in rawSummaries) {
        if (rawSummary is Map) {
          summaries.add(
            ChatConversationSummary.fromJson(
              Map<String, dynamic>.from(rawSummary),
            ),
          );
        }
      }
    }
    return _ChatStoreIndex(
      schemaVersion: json['schemaVersion'] is int
          ? json['schemaVersion'] as int
          : 1,
      activeConversationId: json['activeConversationId'] is String
          ? json['activeConversationId'] as String
          : '',
      summaries: summaries,
    );
  }
}
