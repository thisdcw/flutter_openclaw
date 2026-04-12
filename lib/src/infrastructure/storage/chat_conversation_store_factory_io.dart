import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/chat_conversation_store.dart';
import 'file_chat_conversation_store.dart';

Future<ChatConversationStore> createChatConversationStoreImpl({
  required SharedPreferences prefs,
}) async {
  final appDocumentsDirectory = await getApplicationDocumentsDirectory();
  return FileChatConversationStore(appDocumentsDirectory);
}
