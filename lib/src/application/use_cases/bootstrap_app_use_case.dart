import '../../domain/models/device_identity.dart';
import '../../domain/models/gateway_config.dart';
import '../../domain/models/operator_auth_state.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/config_repository.dart';
import '../../infrastructure/crypto/device_identity_service.dart';
import '../../infrastructure/util/openclaw_logger.dart';

class BootstrapAppResult {
  final GatewayConfig config;
  final DeviceIdentity deviceIdentity;
  final OperatorAuthState? operatorAuth;

  const BootstrapAppResult({
    required this.config,
    required this.deviceIdentity,
    required this.operatorAuth,
  });
}

class BootstrapAppUseCase {
  BootstrapAppUseCase(
    this._configRepository,
    this._authRepository,
    this._identityService,
  );

  final ConfigRepository _configRepository;
  final AuthRepository _authRepository;
  final DeviceIdentityService _identityService;

  Future<BootstrapAppResult> call() async {
    final config = await _configRepository.load();
    final existingIdentity = await _authRepository.loadDeviceIdentity();
    final identity = existingIdentity ?? await _identityService.create();
    openClawLog(
      'Bootstrap',
      'config and identity loaded',
      fields: <String, Object?>{
        'gatewayUrl': config.gatewayUrl,
        'sessionId': config.sessionId,
        'timeoutMs': config.timeoutMs,
        'locale': config.locale,
        'authToken': redactValue(config.authToken),
        'deviceId': identity.id,
        'identitySource': existingIdentity == null ? 'generated' : 'persisted',
      },
    );

    if (existingIdentity == null) {
      await _authRepository.saveDeviceIdentity(identity);
    }

    final operatorAuth = await _authRepository.loadOperatorAuth();
    final persistedToken = await _authRepository.loadAuthToken();
    openClawLog(
      'Bootstrap',
      'auth snapshot loaded',
      fields: <String, Object?>{
        'hasPersistedAuthToken': (persistedToken ?? '').trim().isNotEmpty,
        'persistedAuthToken': redactValue(persistedToken ?? ''),
        'hasDeviceToken': (operatorAuth?.deviceToken ?? '').isNotEmpty,
        'deviceToken': redactValue(operatorAuth?.deviceToken ?? ''),
        'scopes': operatorAuth?.scopes.join(',') ?? '(none)',
      },
    );
    if ((persistedToken ?? '').trim().isEmpty &&
        config.authToken.trim().isNotEmpty) {
      openClawLog('Bootstrap', 'persist config auth token into secure storage');
      await _authRepository.saveAuthToken(config.authToken);
    }

    return BootstrapAppResult(
      config: config,
      deviceIdentity: identity,
      operatorAuth: operatorAuth,
    );
  }
}
