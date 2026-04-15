import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../domain/models/chat_conversation_record.dart';
import '../../domain/models/chat_conversation_summary.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_store_snapshot.dart';
import '../../domain/models/selected_image_attachment.dart';
import '../../domain/repositories/chat_conversation_store.dart';
import '../util/openclaw_logger.dart';

class FileChatConversationStore implements ChatConversationStore {
  FileChatConversationStore(this._rootDirectory, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final Directory _rootDirectory;
  final Uuid _uuid;

  static const int _schemaVersion = 1;

  Directory get _storeDirectory =>
      Directory(p.join(_rootDirectory.path, 'chat_store'));
  Directory get _conversationDirectory =>
      Directory(p.join(_storeDirectory.path, 'conversations'));
  Directory get _mediaDirectory =>
      Directory(p.join(_storeDirectory.path, 'media'));
  File get _indexFile => File(p.join(_storeDirectory.path, 'index.json'));

  @override
  Future<ChatStoreSnapshot> bootstrap() async {
    await _ensureDirectories();
    final index = await _loadIndex();
    if (index == null) {
      final initial = _buildConversationRecord();
      openClawLog(
        'ChatConversationStore',
        'bootstrap created initial conversation',
        fields: <String, Object?>{
          'conversationId': initial.summary.id,
          'sessionId': initial.summary.sessionId,
        },
      );
      return ChatStoreSnapshot(
        activeConversation: initial,
        conversationSummaries: const <ChatConversationSummary>[],
      );
    }

    final baseSummaries = _sanitizeSummaries(index.summaries);
    ChatConversationRecord activeConversation =
        index.activeConversationId.isNotEmpty
        ? (await _loadConversationIfExists(index.activeConversationId) ??
              await _loadFirstAvailableConversation(baseSummaries) ??
              _buildConversationRecord())
        : (await _loadFirstAvailableConversation(baseSummaries) ??
              _buildConversationRecord());
    var nextSummaries = baseSummaries;
    if (_hasConversationContent(activeConversation.messages)) {
      final summarized = _summarizeConversation(
        activeConversation.summary,
        activeConversation.messages,
      );
      activeConversation = activeConversation.copyWith(summary: summarized);
      await _persistConversation(activeConversation);
      nextSummaries = _upsertSummary(nextSummaries, summarized);
    }
    final nextIndex = index.copyWith(
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
    await _ensureDirectories();
    final index = await _loadIndex() ?? _emptyIndex();
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
    await _ensureDirectories();
    final index = await _loadIndex() ?? _emptyIndex();
    final baseSummaries = _sanitizeSummaries(index.summaries);
    ChatConversationRecord activeConversation =
        await _loadConversationIfExists(conversationId) ??
        _buildConversationRecord();
    var nextSummaries = baseSummaries;
    if (_hasConversationContent(activeConversation.messages)) {
      final summarized = _summarizeConversation(
        activeConversation.summary,
        activeConversation.messages,
      );
      activeConversation = activeConversation.copyWith(summary: summarized);
      await _persistConversation(activeConversation);
      nextSummaries = _upsertSummary(nextSummaries, summarized);
    }
    final nextIndex = index.copyWith(
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
    await _ensureDirectories();
    final index = await _loadIndex() ?? _emptyIndex();
    final targetConversation = await _loadConversation(conversationId);
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
    await _persistConversation(updatedConversation);
    final nextSummaries = _upsertSummary(
      _sanitizeSummaries(index.summaries),
      updatedSummary,
    );

    final currentActiveId = index.activeConversationId.isEmpty
        ? updatedSummary.id
        : index.activeConversationId;
    final nextActiveConversation = currentActiveId == updatedSummary.id
        ? updatedConversation
        : (await _loadConversationIfExists(currentActiveId) ??
              await _loadFirstAvailableConversation(nextSummaries) ??
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
    await _ensureDirectories();
    final index = await _loadIndex() ?? _emptyIndex();
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
    await _persistConversation(nextConversation);
    await _saveIndex(nextIndex);
  }

  ChatConversationRecord _buildConversationRecord() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final conversationId = _uuid.v4();
    final summary = ChatConversationSummary(
      id: conversationId,
      sessionId: _uuid.v4(),
      title: 'New chat',
      previewText: '',
      updatedAtMs: now,
      messageCount: 0,
    );
    return ChatConversationRecord(
      summary: summary,
      messages: const <ChatMessage>[],
    );
  }

  Future<void> _ensureDirectories() async {
    await _storeDirectory.create(recursive: true);
    await _conversationDirectory.create(recursive: true);
    await _mediaDirectory.create(recursive: true);
  }

  Future<_ChatStoreIndex?> _loadIndex() async {
    if (!await _indexFile.exists()) {
      return null;
    }
    try {
      final raw = await _indexFile.readAsString();
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        return null;
      }
      return _ChatStoreIndex.fromJson(json);
    } catch (error, stackTrace) {
      openClawLog(
        'ChatConversationStore',
        'load index failed',
        fields: <String, Object?>{
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
      return null;
    }
  }

  Future<void> _saveIndex(_ChatStoreIndex index) async {
    await _indexFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(index.toJson()),
      flush: true,
    );
  }

  Future<ChatConversationRecord> _loadConversation(
    String conversationId,
  ) async {
    final file = _conversationFile(conversationId);
    if (!await file.exists()) {
      throw StateError('Conversation "$conversationId" does not exist.');
    }
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Conversation "$conversationId" is invalid.');
    }
    final summary = ChatConversationSummary.fromJson(
      Map<String, dynamic>.from(decoded['summary'] as Map),
    );
    final rawMessages = decoded['messages'];
    final messages = <ChatMessage>[];
    if (rawMessages is List) {
      for (final rawMessage in rawMessages) {
        if (rawMessage is! Map) {
          continue;
        }
        messages.add(
          await _deserializeMessage(Map<String, dynamic>.from(rawMessage)),
        );
      }
    }
    return ChatConversationRecord(summary: summary, messages: messages);
  }

  Future<ChatConversationRecord?> _loadConversationIfExists(
    String conversationId,
  ) async {
    try {
      return await _loadConversation(conversationId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistConversation(ChatConversationRecord conversation) async {
    final nextMessages = <Map<String, dynamic>>[];
    for (final message in conversation.messages) {
      nextMessages.add(
        await _serializeMessage(conversation.summary.id, message),
      );
    }
    final file = _conversationFile(conversation.summary.id);
    final encoded = const JsonEncoder.withIndent('  ').convert(
      <String, dynamic>{
        'summary': conversation.summary.toJson(),
        'messages': nextMessages,
      },
    );
    await file.writeAsString(encoded, flush: true);
  }

  Future<void> _removeConversationRecord(String conversationId) async {
    final conversationFile = _conversationFile(conversationId);
    if (await conversationFile.exists()) {
      await conversationFile.delete();
    }
    final mediaDirectory = Directory(
      p.join(_mediaDirectory.path, conversationId),
    );
    if (await mediaDirectory.exists()) {
      await mediaDirectory.delete(recursive: true);
    }
  }

  Future<Map<String, dynamic>> _serializeMessage(
    String conversationId,
    ChatMessage message,
  ) async {
    final nextAttachments = <Map<String, dynamic>>[];
    for (final attachment in message.attachments) {
      final extension = _preferredExtension(
        attachment.mimeType,
        attachment.fileName,
      );
      final relativePath = p.join(conversationId, '${attachment.id}$extension');
      final file = File(p.join(_mediaDirectory.path, relativePath));
      await file.parent.create(recursive: true);
      await file.writeAsBytes(attachment.bytes, flush: true);
      nextAttachments.add(<String, dynamic>{
        'id': attachment.id,
        'fileName': attachment.fileName,
        'mimeType': attachment.mimeType,
        'relativePath': relativePath,
      });
    }

    return <String, dynamic>{
      'id': message.id,
      'role': message.role.value,
      'text': message.text,
      'isStreaming': message.isStreaming,
      'attachments': nextAttachments,
    };
  }

  Future<ChatMessage> _deserializeMessage(Map<String, dynamic> json) async {
    final rawAttachments = json['attachments'];
    final attachments = <SelectedImageAttachment>[];
    if (rawAttachments is List) {
      for (final rawAttachment in rawAttachments) {
        if (rawAttachment is! Map) {
          continue;
        }
        final data = Map<String, dynamic>.from(rawAttachment);
        final relativePath = data['relativePath'];
        if (relativePath is! String || relativePath.isEmpty) {
          continue;
        }
        final file = File(p.join(_mediaDirectory.path, relativePath));
        if (!await file.exists()) {
          continue;
        }
        attachments.add(
          SelectedImageAttachment(
            id: _string(data, 'id'),
            fileName: _string(data, 'fileName'),
            mimeType: _string(data, 'mimeType'),
            bytes: await file.readAsBytes(),
          ),
        );
      }
    }

    return ChatMessage(
      id: _string(json, 'id'),
      role: MessageRole.fromValue(_string(json, 'role')),
      text: _string(json, 'text'),
      isStreaming: _boolOrFalse(json, 'isStreaming'),
      attachments: attachments,
    );
  }

  ChatConversationSummary _summarizeConversation(
    ChatConversationSummary base,
    List<ChatMessage> messages,
  ) {
    final title = base.isTitleManuallyEdited
        ? base.title
        : _deriveTitle(messages);
    final previewText = _derivePreview(messages);
    return base.copyWith(
      title: title,
      previewText: previewText,
      messageCount: messages.length,
    );
  }

  String _deriveTitle(List<ChatMessage> messages) {
    for (final message in messages) {
      if (message.role != MessageRole.user) {
        continue;
      }
      final normalized = message.text.trim();
      if (normalized.isEmpty) {
        continue;
      }
      return _truncate(normalized, maxLength: 32);
    }
    return 'New chat';
  }

  String _derivePreview(List<ChatMessage> messages) {
    for (final message in messages.reversed) {
      final normalized = message.text.trim();
      if (normalized.isNotEmpty) {
        return _truncate(normalized.replaceAll('\n', ' '), maxLength: 60);
      }
      if (message.attachments.isNotEmpty) {
        return '[Image]';
      }
    }
    return '';
  }

  String _truncate(String value, {required int maxLength}) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength - 1)}…';
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

  Future<ChatConversationRecord?> _loadFirstAvailableConversation(
    List<ChatConversationSummary> summaries,
  ) async {
    for (final summary in summaries) {
      final record = await _loadConversationIfExists(summary.id);
      if (record != null) {
        return record;
      }
    }
    return null;
  }

  File _conversationFile(String conversationId) {
    return File(p.join(_conversationDirectory.path, '$conversationId.json'));
  }

  _ChatStoreIndex _emptyIndex() {
    return const _ChatStoreIndex(
      schemaVersion: _schemaVersion,
      activeConversationId: '',
      summaries: <ChatConversationSummary>[],
    );
  }

  String _preferredExtension(String mimeType, String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex != -1) {
      return fileName.substring(dotIndex);
    }
    if (mimeType == 'image/png') {
      return '.png';
    }
    if (mimeType == 'image/webp') {
      return '.webp';
    }
    if (mimeType == 'image/gif') {
      return '.gif';
    }
    return '.jpg';
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw FormatException('FileChatConversationStore: "$key" must be String.');
  }

  static bool _boolOrFalse(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    return false;
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

  _ChatStoreIndex copyWith({
    int? schemaVersion,
    String? activeConversationId,
    List<ChatConversationSummary>? summaries,
  }) {
    return _ChatStoreIndex(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      activeConversationId: activeConversationId ?? this.activeConversationId,
      summaries: summaries ?? this.summaries,
    );
  }

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
