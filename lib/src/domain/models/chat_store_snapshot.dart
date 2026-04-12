import 'chat_conversation_record.dart';
import 'chat_conversation_summary.dart';

class ChatStoreSnapshot {
  ChatStoreSnapshot({
    required this.activeConversation,
    required List<ChatConversationSummary> conversationSummaries,
  }) : conversationSummaries = List<ChatConversationSummary>.unmodifiable(
         conversationSummaries,
       );

  final ChatConversationRecord activeConversation;
  final List<ChatConversationSummary> conversationSummaries;
}
