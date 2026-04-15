import '../models/chat_conversation_record.dart';
import '../models/chat_store_snapshot.dart';

abstract class ChatConversationStore {
  Future<ChatStoreSnapshot> bootstrap();

  Future<ChatStoreSnapshot> createConversation();

  Future<ChatStoreSnapshot> activateConversation(String conversationId);

  Future<ChatStoreSnapshot> renameConversationTitle({
    required String conversationId,
    required String title,
  });

  Future<void> saveConversation(ChatConversationRecord conversation);
}
