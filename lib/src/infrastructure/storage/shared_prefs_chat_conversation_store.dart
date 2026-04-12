import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/chat_conversation_record.dart';
import '../../domain/models/chat_conversation_summary.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_store_snapshot.dart';
import '../../domain/repositories/chat_conversation_store.dart';

class SharedPrefsChatConversationStore implements ChatConversationStore {
  SharedPrefsChatConversationStore(
    this._prefs, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final SharedPreferences _prefs;
  final Uuid _uuid;

  static const String _indexKey = 'chat_store_index';
  static const int _schemaVersion = 1;

  @override
  Future<ChatStoreSnapshot> bootstrap() async {
    final index = _loadIndex();
    if (index == null || index.summaries.isEmpty) {
      final initial = _buildConversationRecord();
      await _saveConversationRecord(initial);
      final nextIndex = _ChatStoreIndex(
        schemaVersion: _schemaVersion,
        activeConversationId: initial.summary.id,
        summaries: <ChatConversationSummary>[initial.summary],
      );
      await _saveIndex(nextIndex);
      return ChatStoreSnapshot(
        activeConversation: initial,
        conversationSummaries: nextIndex.summaries,
      );
    }

    final activeId = index.activeConversationId.isNotEmpty
        ? index.activeConversationId
        : index.summaries.first.id;
    final activeConversation = _loadConversation(activeId) ?? _buildConversationRecord();
    final nextSummaries = _upsertSummary(
      index.summaries,
      activeConversation.summary,
    );
    final nextIndex = _ChatStoreIndex(
      schemaVersion: _schemaVersion,
      activeConversationId: activeConversation.summary.id,
      summaries: nextSummaries,
    );
    await _saveIndex(nextIndex);
    await _saveConversationRecord(activeConversation);
    return ChatStoreSnapshot(
      activeConversation: activeConversation,
      conversationSummaries: nextSummaries,
    );
  }

  @override
  Future<ChatStoreSnapshot> createConversation() async {
    final index = _loadIndex() ?? _emptyIndex();
    final conversation = _buildConversationRecord();
    await _saveConversationRecord(conversation);
    final nextSummaries = _upsertSummary(index.summaries, conversation.summary);
    final nextIndex = _ChatStoreIndex(
      schemaVersion: _schemaVersion,
      activeConversationId: conversation.summary.id,
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
    final activeConversation = _loadConversation(conversationId) ?? _buildConversationRecord();
    final nextSummaries = _upsertSummary(
      index.summaries,
      activeConversation.summary,
    );
    final nextIndex = _ChatStoreIndex(
      schemaVersion: _schemaVersion,
      activeConversationId: activeConversation.summary.id,
      summaries: nextSummaries,
    );
    await _saveIndex(nextIndex);
    await _saveConversationRecord(activeConversation);
    return ChatStoreSnapshot(
      activeConversation: activeConversation,
      conversationSummaries: nextSummaries,
    );
  }

  @override
  Future<void> saveConversation(ChatConversationRecord conversation) async {
    final index = _loadIndex() ?? _emptyIndex();
    final updatedSummary = _summarizeConversation(
      conversation.summary.copyWith(
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
      conversation.messages,
    );
    final nextConversation = conversation.copyWith(summary: updatedSummary);
    await _saveConversationRecord(nextConversation);
    final nextSummaries = _upsertSummary(index.summaries, updatedSummary);
    final nextIndex = _ChatStoreIndex(
      schemaVersion: _schemaVersion,
      activeConversationId: index.activeConversationId.isEmpty
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

  Future<void> _saveConversationRecord(ChatConversationRecord conversation) async {
    final key = _conversationKey(conversation.summary.id);
    final encoded = jsonEncode(
      <String, dynamic>{
        'summary': conversation.summary.toJson(),
        'messages': conversation.messages.map((message) => message.toJson()).toList(),
      },
    );
    await _prefs.setString(key, encoded);
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
      summary,
      ...existing.where((item) => item.id != summary.id),
    ];
    next.sort((left, right) => right.updatedAtMs.compareTo(left.updatedAtMs));
    return next;
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
    return base.copyWith(
      title: firstUserText.isEmpty
          ? 'New chat'
          : _truncate(firstUserText, maxLength: 32),
      previewText: preview.isEmpty ? '' : _truncate(preview, maxLength: 60),
      messageCount: messages.length,
    );
  }

  String _conversationKey(String conversationId) => 'chat_conversation_$conversationId';

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
