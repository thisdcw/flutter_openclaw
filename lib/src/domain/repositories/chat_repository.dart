import '../models/chat_draft.dart';
import '../models/chat_message.dart';

abstract class ChatRepository {
  Stream<ChatMessage> sendMessage(
    ChatDraft draft, {
    required String sessionId,
  });
}
