import 'package:flutter_openclaw/src/application/controllers/app_error_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_openclaw/src/application/controllers/chat_controller.dart';
import 'package:flutter_openclaw/src/application/controllers/connection_controller.dart';
import 'package:flutter_openclaw/src/application/controllers/settings_controller.dart';
import 'package:flutter_openclaw/src/application/use_cases/bootstrap_app_use_case.dart';
import 'package:flutter_openclaw/src/application/use_cases/clear_operator_auth_use_case.dart';
import 'package:flutter_openclaw/src/application/use_cases/import_bootstrap_token_use_case.dart';
import 'package:flutter_openclaw/src/application/use_cases/reset_device_identity_use_case.dart';
import 'package:flutter_openclaw/src/application/use_cases/send_chat_message_use_case.dart';
import 'package:flutter_openclaw/src/application/use_cases/test_connection_use_case.dart';
import 'package:flutter_openclaw/src/domain/models/connection_status.dart';
import 'package:flutter_openclaw/src/infrastructure/crypto/connect_signer.dart';
import 'package:flutter_openclaw/src/infrastructure/crypto/device_identity_service.dart';
import 'package:flutter_openclaw/src/infrastructure/crypto/keystore_signer.dart';
import 'package:flutter_openclaw/src/infrastructure/gateway/gateway_protocol_parser.dart';
import 'package:flutter_openclaw/src/infrastructure/storage/chat_conversation_store_factory.dart';
import 'package:flutter_openclaw/src/infrastructure/storage/shared_prefs_app_locale_preference_repository.dart';
import 'package:flutter_openclaw/src/infrastructure/storage/secure_auth_repository.dart';
import 'package:flutter_openclaw/src/infrastructure/storage/shared_prefs_config_repository.dart';
import 'package:flutter_openclaw/src/infrastructure/util/bootstrap_payload_parser.dart';

class AppDependencies {
  AppDependencies({
    required this.settingsController,
    required this.connectionController,
    required this.chatController,
    required this.appErrorController,
  });

  final SettingsController settingsController;
  final ConnectionController connectionController;
  final ChatController chatController;
  final AppErrorController appErrorController;

  static Future<AppDependencies> create({
    AppErrorController? appErrorController,
  }) async {
    final resolvedAppErrorController =
        appErrorController ?? AppErrorController();
    final prefs = await SharedPreferences.getInstance();
    final configRepository = SharedPrefsConfigRepository(prefs);
    final appLocalePreferenceRepository =
        SharedPrefsAppLocalePreferenceRepository(prefs);
    final chatConversationStore = await createChatConversationStore(
      prefs: prefs,
    );
    final chatStoreSnapshot = await chatConversationStore.bootstrap();
    final authRepository = SecureAuthRepository();
    final parser = const GatewayProtocolParser();
    final keystoreSigner = KeystoreSigner();
    final signer = ConnectSigner(keystoreSigner: keystoreSigner);
    final identityService = DeviceIdentityService();
    final bootstrap = BootstrapAppUseCase(
      configRepository,
      authRepository,
      identityService,
    );
    final bootstrapResult = await bootstrap.call();
    final initialConfig = bootstrapResult.config.copyWith(
      sessionId: chatStoreSnapshot.activeConversation.summary.sessionId,
    );
    final initialLocalePreference = await appLocalePreferenceRepository.load();
    final clearOperatorAuthUseCase = ClearOperatorAuthUseCase(authRepository);
    final resetDeviceIdentityUseCase = ResetDeviceIdentityUseCase(
      authRepository,
      keystore: keystoreSigner,
    );
    final importBootstrapTokenUseCase = ImportBootstrapTokenUseCase(
      authRepository,
      configRepository,
      BootstrapPayloadParser(),
    );
    final testConnectionUseCase = TestConnectionUseCase(
      authRepository: authRepository,
      identityService: identityService,
      signer: signer,
      parser: parser,
    );
    final sendChatMessageUseCase = SendChatMessageUseCase(
      testConnectionUseCase,
      parser: parser,
    );
    final settingsController = SettingsController(
      initialConfig: initialConfig,
      initialLocalePreference: initialLocalePreference,
      configRepository: configRepository,
      authRepository: authRepository,
      appLocalePreferenceRepository: appLocalePreferenceRepository,
      clearOperatorAuthUseCase: clearOperatorAuthUseCase,
      importBootstrapTokenUseCase: importBootstrapTokenUseCase,
      resetDeviceIdentityUseCase: resetDeviceIdentityUseCase,
    );
    final connectionController = ConnectionController(
      initialStatus: ConnectionStatus(
        phase: ConnectionPhase.idle,
        grantedScopes: bootstrapResult.operatorAuth?.scopes ?? const <String>[],
        deviceId: bootstrapResult.deviceIdentity.id,
      ),
      testConnectionUseCase: testConnectionUseCase,
      configProvider: () => settingsController.config,
      appErrorController: resolvedAppErrorController,
    );
    final chatController = ChatController(
      sendChatMessageUseCase: sendChatMessageUseCase,
      configProvider: () => settingsController.config,
      conversationStore: chatConversationStore,
      initialSnapshot: chatStoreSnapshot,
      appErrorController: resolvedAppErrorController,
      activeSessionSync: settingsController.syncActiveSessionId,
    );

    return AppDependencies(
      settingsController: settingsController,
      connectionController: connectionController,
      chatController: chatController,
      appErrorController: resolvedAppErrorController,
    );
  }

  static AppDependencies fake() {
    final appErrorController = AppErrorController();
    return AppDependencies(
      settingsController: SettingsController.fake(),
      connectionController: ConnectionController(
        isStub: true,
        appErrorController: appErrorController,
      ),
      chatController: ChatController(
        isStub: true,
        appErrorController: appErrorController,
      ),
      appErrorController: appErrorController,
    );
  }
}
