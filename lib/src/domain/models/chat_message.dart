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

  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.isStreaming = false,
  });

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? text,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.value,
      'text': text,
      'isStreaming': isStreaming,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: _string(json, 'id'),
      role: MessageRole.fromValue(_string(json, 'role')),
      text: _string(json, 'text'),
      isStreaming: _bool(json, 'isStreaming'),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.id == id &&
        other.role == role &&
        other.text == text &&
        other.isStreaming == isStreaming;
  }

  @override
  int get hashCode => Object.hash(id, role, text, isStreaming);

  @override
  String toString() {
    return 'ChatMessage(id: $id, role: ${role.value}, text: $text, '
        'isStreaming: $isStreaming)';
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw FormatException('ChatMessage: "$key" must be a string.');
  }

  static bool _bool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    throw FormatException('ChatMessage: "$key" must be a bool.');
  }
}
