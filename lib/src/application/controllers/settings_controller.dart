import 'package:flutter/foundation.dart';

import '../../domain/models/gateway_config.dart';
import '../../domain/repositories/config_repository.dart';
import '../../infrastructure/config/dev_defaults.dart';
import '../../infrastructure/util/openclaw_logger.dart';
import '../use_cases/clear_operator_auth_use_case.dart';
import '../use_cases/reset_device_identity_use_case.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({
    GatewayConfig? initialConfig,
    ConfigRepository? configRepository,
    ClearOperatorAuthUseCase? clearOperatorAuthUseCase,
    ResetDeviceIdentityUseCase? resetDeviceIdentityUseCase,
    bool isStub = false,
  })  : _config = initialConfig ?? defaultGatewayConfig,
        _configRepository = configRepository,
        _clearOperatorAuthUseCase = clearOperatorAuthUseCase,
        _resetDeviceIdentityUseCase = resetDeviceIdentityUseCase,
        _isStub = isStub;

  factory SettingsController.fake() => SettingsController(isStub: true);

  GatewayConfig _config;
  final ConfigRepository? _configRepository;
  final ClearOperatorAuthUseCase? _clearOperatorAuthUseCase;
  final ResetDeviceIdentityUseCase? _resetDeviceIdentityUseCase;
  final bool _isStub;

  GatewayConfig get config => _config;

  bool get isStub => _isStub;

  void update(GatewayConfig next) {
    openClawLog(
      'SettingsController',
      'update in-memory config',
      fields: <String, Object?>{
        'gatewayUrl': next.gatewayUrl,
        'sessionId': next.sessionId,
        'timeoutMs': next.timeoutMs,
        'locale': next.locale,
        'authToken': redactValue(next.authToken),
      },
    );
    _config = next;
    notifyListeners();
  }

  Future<void> save(GatewayConfig next) async {
    openClawLog(
      'SettingsController',
      'save config',
      fields: <String, Object?>{
        'gatewayUrl': next.gatewayUrl,
        'sessionId': next.sessionId,
        'timeoutMs': next.timeoutMs,
        'locale': next.locale,
        'authToken': redactValue(next.authToken),
      },
    );
    _config = next;
    await _configRepository?.save(next);
    notifyListeners();
  }

  Future<void> clearDeviceToken() async {
    openClawLog('SettingsController', 'clear device token');
    await _clearOperatorAuthUseCase?.call();
    notifyListeners();
  }

  Future<void> resetDeviceIdentity() async {
    openClawLog('SettingsController', 'reset device identity');
    await _resetDeviceIdentityUseCase?.call();
    await _clearOperatorAuthUseCase?.call();
    notifyListeners();
  }
}
