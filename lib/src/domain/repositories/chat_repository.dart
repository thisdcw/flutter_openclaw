import '../models/chat_message.dart';

abstract class ChatRepository {
  Stream<ChatMessage> sendMessage(
    String text, {
    required String sessionId,
  });
}
