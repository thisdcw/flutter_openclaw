class ChatConversationSummary {
  const ChatConversationSummary({
    required this.id,
    required this.sessionId,
    required this.title,
    required this.previewText,
    required this.updatedAtMs,
    required this.messageCount,
  });

  final String id;
  final String sessionId;
  final String title;
  final String previewText;
  final int updatedAtMs;
  final int messageCount;

  ChatConversationSummary copyWith({
    String? id,
    String? sessionId,
    String? title,
    String? previewText,
    int? updatedAtMs,
    int? messageCount,
  }) {
    return ChatConversationSummary(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      title: title ?? this.title,
      previewText: previewText ?? this.previewText,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'sessionId': sessionId,
      'title': title,
      'previewText': previewText,
      'updatedAtMs': updatedAtMs,
      'messageCount': messageCount,
    };
  }

  factory ChatConversationSummary.fromJson(Map<String, dynamic> json) {
    return ChatConversationSummary(
      id: _string(json, 'id'),
      sessionId: _string(json, 'sessionId'),
      title: _string(json, 'title'),
      previewText: _string(json, 'previewText'),
      updatedAtMs: _int(json, 'updatedAtMs'),
      messageCount: _int(json, 'messageCount'),
    );
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw FormatException('ChatConversationSummary: "$key" must be a string.');
  }

  static int _int(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw FormatException('ChatConversationSummary: "$key" must be an int.');
  }
}
