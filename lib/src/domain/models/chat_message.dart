import 'package:collection/collection.dart';

import 'selected_image_attachment.dart';

enum MessageRole {
  user,
  assistant,
  system,
  error;

  String get value => name;

  static MessageRole fromValue(String value) {
    for (final role in MessageRole.values) {
      if (role.value == value) {
        return role;
      }
    }
    throw FormatException('MessageRole: unsupported value "$value".');
  }
}

class ChatMessage {
  final String id;
  final MessageRole role;
  final String text;
  final bool isStreaming;
  final List<SelectedImageAttachment> attachments;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.isStreaming = false,
    List<SelectedImageAttachment> attachments = const [],
  }) : attachments = List<SelectedImageAttachment>.unmodifiable(attachments);

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? text,
    bool? isStreaming,
    List<SelectedImageAttachment>? attachments,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      isStreaming: isStreaming ?? this.isStreaming,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.value,
      'text': text,
      'isStreaming': isStreaming,
      'attachments': attachments
          .map(
            (attachment) => <String, dynamic>{
              'id': attachment.id,
              'fileName': attachment.fileName,
              'mimeType': attachment.mimeType,
              'bytes': attachment.bytes,
            },
          )
          .toList(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'];
    final attachments = <SelectedImageAttachment>[];
    if (rawAttachments is List) {
      for (final entry in rawAttachments) {
        if (entry is! Map) {
          throw FormatException(
            'ChatMessage: "attachments" entries must be objects.',
          );
        }
        final data = Map<String, dynamic>.from(entry);
        attachments.add(
          SelectedImageAttachment(
            id: _string(data, 'id'),
            fileName: _string(data, 'fileName'),
            mimeType: _string(data, 'mimeType'),
            bytes: _intList(data, 'bytes'),
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.role == role &&
        other.text == text &&
        other.isStreaming == isStreaming &&
        _attachmentEquality.equals(other.attachments, attachments);
  }

  @override
  int get hashCode => Object.hash(
        id,
        role,
        text,
        isStreaming,
        _attachmentEquality.hash(attachments),
      );

  @override
  String toString() {
    return 'ChatMessage(id: $id, role: ${role.value}, text: $text, '
        'isStreaming: $isStreaming, attachments: ${attachments.length})';
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw FormatException('ChatMessage: "$key" must be a string.');
  }

  static bool _boolOrFalse(Map<String, dynamic> json, String key) {
    if (!json.containsKey(key)) {
      return false;
    }
    final value = json[key];
    if (value == null) {
      return false;
    }
    if (value is bool) {
      return value;
    }
    throw FormatException('ChatMessage: "$key" must be a bool.');
  }

  static List<int> _intList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is List) {
      final items = <int>[];
      for (final entry in value) {
        if (entry is int) {
          items.add(entry);
          continue;
        }
        if (entry is num) {
          items.add(entry.toInt());
          continue;
        }
        throw FormatException('ChatMessage: "$key" must contain ints.');
      }
      return items;
    }
    throw FormatException('ChatMessage: "$key" must be a list.');
  }

  static const ListEquality<SelectedImageAttachment> _attachmentEquality =
      ListEquality<SelectedImageAttachment>();
}
