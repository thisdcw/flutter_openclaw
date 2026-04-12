import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/chat_conversation_store.dart';
import 'chat_conversation_store_factory_stub.dart'
    if (dart.library.io) 'chat_conversation_store_factory_io.dart'
    if (dart.library.html) 'chat_conversation_store_factory_web.dart';

Future<ChatConversationStore> createChatConversationStore({
  required SharedPreferences prefs,
}) {
  return createChatConversationStoreImpl(prefs: prefs);
}
