import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/chat_conversation_store.dart';
import 'shared_prefs_chat_conversation_store.dart';

Future<ChatConversationStore> createChatConversationStoreImpl({
  required SharedPreferences prefs,
}) async {
  return SharedPrefsChatConversationStore(prefs);
}
