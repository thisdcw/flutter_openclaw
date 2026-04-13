import '../../domain/models/bootstrap_token_state.dart';
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
    final bootstrapToken = await _authRepository.loadBootstrapToken();
    if (bootstrapToken != null && bootstrapToken.isExpired) {
      await _authRepository.clearBootstrapToken();
    }
    openClawLog(
      'Bootstrap',
      'config and identity loaded',
      fields: <String, Object?>{
        'gatewayUrl': config.gatewayUrl,
        'sessionId': config.sessionId,
        'timeoutMs': config.timeoutMs,
        'locale': config.locale,
        'deviceId': identity.id,
        'identitySource': existingIdentity == null ? 'generated' : 'persisted',
      },
    );

    if (existingIdentity == null) {
      await _authRepository.saveDeviceIdentity(identity);
    }

    final operatorAuth = await _authRepository.loadOperatorAuth();
    openClawLog(
      'Bootstrap',
      'auth snapshot loaded',
      fields: <String, Object?>{
        'hasDeviceToken': (operatorAuth?.deviceToken ?? '').isNotEmpty,
        'deviceToken': redactValue(operatorAuth?.deviceToken ?? ''),
        'scopes': operatorAuth?.scopes.join(',') ?? '(none)',
      },
    );
    return BootstrapAppResult(
      config: config,
      deviceIdentity: identity,
      operatorAuth: operatorAuth,
    );
  }
}
