import 'package:flutter/foundation.dart';

import '../../domain/models/app_locale_preference.dart';
import '../../domain/models/gateway_config.dart';
import '../../domain/repositories/app_locale_preference_repository.dart';
import '../../domain/repositories/config_repository.dart';
import '../../infrastructure/config/dev_defaults.dart';
import '../../infrastructure/util/openclaw_logger.dart';
import '../use_cases/clear_operator_auth_use_case.dart';
import '../use_cases/reset_device_identity_use_case.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({
    GatewayConfig? initialConfig,
    AppLocalePreference initialLocalePreference =
        AppLocalePreference.system,
    ConfigRepository? configRepository,
    AppLocalePreferenceRepository? appLocalePreferenceRepository,
    ClearOperatorAuthUseCase? clearOperatorAuthUseCase,
    ResetDeviceIdentityUseCase? resetDeviceIdentityUseCase,
    bool isStub = false,
  })  : _config = initialConfig ?? defaultGatewayConfig,
        _localePreference = initialLocalePreference,
        _configRepository = configRepository,
        _appLocalePreferenceRepository = appLocalePreferenceRepository,
        _clearOperatorAuthUseCase = clearOperatorAuthUseCase,
        _resetDeviceIdentityUseCase = resetDeviceIdentityUseCase,
        _isStub = isStub;

  factory SettingsController.fake({
    AppLocalePreference initialLocalePreference =
        AppLocalePreference.system,
  }) => SettingsController(
        isStub: true,
        initialLocalePreference: initialLocalePreference,
      );

  GatewayConfig _config;
  AppLocalePreference _localePreference;
  final ConfigRepository? _configRepository;
  final AppLocalePreferenceRepository? _appLocalePreferenceRepository;
  final ClearOperatorAuthUseCase? _clearOperatorAuthUseCase;
  final ResetDeviceIdentityUseCase? _resetDeviceIdentityUseCase;
  final bool _isStub;

  GatewayConfig get config => _config;
  AppLocalePreference get localePreference => _localePreference;

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
      },
    );
    _config = next;
    await _configRepository?.save(next);
    notifyListeners();
  }

  Future<void> saveLocalePreference(AppLocalePreference next) async {
    if (_localePreference == next) {
      return;
    }
    _localePreference = next;
    await _appLocalePreferenceRepository?.save(next);
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

  Future<void> syncActiveSessionId(String sessionId) async {
    if (_config.sessionId == sessionId) {
      return;
    }
    final next = _config.copyWith(sessionId: sessionId);
    _config = next;
    await _configRepository?.save(next);
    notifyListeners();
  }
}
