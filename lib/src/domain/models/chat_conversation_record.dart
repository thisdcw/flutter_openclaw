import 'chat_conversation_summary.dart';
import 'chat_message.dart';

class ChatConversationRecord {
  ChatConversationRecord({
    required this.summary,
    required List<ChatMessage> messages,
  }) : messages = List<ChatMessage>.unmodifiable(messages);

  final ChatConversationSummary summary;
  final List<ChatMessage> messages;

  ChatConversationRecord copyWith({
    ChatConversationSummary? summary,
    List<ChatMessage>? messages,
  }) {
    return ChatConversationRecord(
      summary: summary ?? this.summary,
      messages: messages ?? this.messages,
    );
  }
}
