import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_openclaw/src/application/controllers/chat_controller.dart';
import 'package:flutter_openclaw/src/application/controllers/connection_controller.dart';
import 'package:flutter_openclaw/src/application/controllers/settings_controller.dart';
import 'package:flutter_openclaw/src/application/use_cases/bootstrap_app_use_case.dart';
import 'package:flutter_openclaw/src/application/use_cases/clear_operator_auth_use_case.dart';
import 'package:flutter_openclaw/src/application/use_cases/reset_device_identity_use_case.dart';
import 'package:flutter_openclaw/src/application/use_cases/send_chat_message_use_case.dart';
import 'package:flutter_openclaw/src/application/use_cases/test_connection_use_case.dart';
import 'package:flutter_openclaw/src/domain/models/connection_status.dart';
import 'package:flutter_openclaw/src/infrastructure/crypto/connect_signer.dart';
import 'package:flutter_openclaw/src/infrastructure/crypto/device_identity_service.dart';
import 'package:flutter_openclaw/src/infrastructure/gateway/gateway_protocol_parser.dart';
import 'package:flutter_openclaw/src/infrastructure/storage/secure_auth_repository.dart';
import 'package:flutter_openclaw/src/infrastructure/storage/shared_prefs_config_repository.dart';

class AppDependencies {
  AppDependencies({
    required this.settingsController,
    required this.connectionController,
    required this.chatController,
  });

  final SettingsController settingsController;
  final ConnectionController connectionController;
  final ChatController chatController;

  static Future<AppDependencies> create() async {
    final prefs = await SharedPreferences.getInstance();
    final configRepository = SharedPrefsConfigRepository(prefs);
    final authRepository = SecureAuthRepository();
    final parser = const GatewayProtocolParser();
    final signer = const ConnectSigner();
    final identityService = DeviceIdentityService();
    final bootstrap = BootstrapAppUseCase(
      configRepository,
      authRepository,
      identityService,
    );
    final bootstrapResult = await bootstrap.call();
    final clearOperatorAuthUseCase = ClearOperatorAuthUseCase(authRepository);
    final resetDeviceIdentityUseCase = ResetDeviceIdentityUseCase(authRepository);
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
      initialConfig: bootstrapResult.config,
      configRepository: configRepository,
      clearOperatorAuthUseCase: clearOperatorAuthUseCase,
      resetDeviceIdentityUseCase: resetDeviceIdentityUseCase,
    );
    final connectionController = ConnectionController(
      initialStatus: ConnectionStatus(
        phase: ConnectionPhase.idle,
        grantedScopes:
            bootstrapResult.operatorAuth?.scopes ?? const <String>[],
        deviceId: bootstrapResult.deviceIdentity.id,
      ),
      testConnectionUseCase: testConnectionUseCase,
      configProvider: () => settingsController.config,
    );
    final chatController = ChatController(
      sendChatMessageUseCase: sendChatMessageUseCase,
      configProvider: () => settingsController.config,
      sessionIdProvider: () => settingsController.config.sessionId,
    );

    return AppDependencies(
      settingsController: settingsController,
      connectionController: connectionController,
      chatController: chatController,
    );
  }

  static AppDependencies fake() {
    return AppDependencies(
      settingsController: SettingsController.fake(),
      connectionController: ConnectionController.fake(),
      chatController: ChatController.fake(),
    );
  }
}
