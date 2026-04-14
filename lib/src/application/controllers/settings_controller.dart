import 'package:flutter/foundation.dart';

import '../../domain/models/app_locale_preference.dart';
import '../../domain/models/bootstrap_token_state.dart';
import '../../domain/models/gateway_config.dart';
import '../../domain/models/operator_auth_state.dart';
import '../../domain/repositories/app_locale_preference_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/config_repository.dart';
import '../../infrastructure/config/dev_defaults.dart';
import '../../infrastructure/util/openclaw_logger.dart';
import '../use_cases/clear_operator_auth_use_case.dart';
import '../use_cases/import_bootstrap_token_use_case.dart';
import '../use_cases/reset_device_identity_use_case.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({
    GatewayConfig? initialConfig,
    AppLocalePreference initialLocalePreference =
        AppLocalePreference.system,
    ConfigRepository? configRepository,
    AuthRepository? authRepository,
    AppLocalePreferenceRepository? appLocalePreferenceRepository,
    ClearOperatorAuthUseCase? clearOperatorAuthUseCase,
    ImportBootstrapTokenUseCase? importBootstrapTokenUseCase,
    ResetDeviceIdentityUseCase? resetDeviceIdentityUseCase,
    bool isStub = false,
  })  : _config = _normalizeGateway(initialConfig ?? defaultGatewayConfig),
        _localePreference = initialLocalePreference,
        _configRepository = configRepository,
        _authRepository = authRepository,
        _appLocalePreferenceRepository = appLocalePreferenceRepository,
        _clearOperatorAuthUseCase = clearOperatorAuthUseCase,
        _importBootstrapTokenUseCase = importBootstrapTokenUseCase,
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
  final AuthRepository? _authRepository;
  final AppLocalePreferenceRepository? _appLocalePreferenceRepository;
  final ClearOperatorAuthUseCase? _clearOperatorAuthUseCase;
  final ImportBootstrapTokenUseCase? _importBootstrapTokenUseCase;
  final ResetDeviceIdentityUseCase? _resetDeviceIdentityUseCase;
  final bool _isStub;
  OperatorAuthState? _operatorAuth;
  BootstrapTokenState? _bootstrapToken;

  GatewayConfig get config => _config;
  AppLocalePreference get localePreference => _localePreference;
  String get deviceToken => _operatorAuth?.deviceToken ?? '';
  String get bootstrapToken => _bootstrapToken?.token ?? '';

  bool get isStub => _isStub;

  static GatewayConfig _normalizeGateway(GatewayConfig config) {
    if (config.gatewayUrl == defaultGatewayConfig.gatewayUrl) {
      return config;
    }
    return config.copyWith(gatewayUrl: defaultGatewayConfig.gatewayUrl);
  }

  void update(GatewayConfig next) {
    final normalized = _normalizeGateway(next);
    openClawLog(
      'SettingsController',
      'update in-memory config',
      fields: <String, Object?>{
        'gatewayUrl': normalized.gatewayUrl,
        'sessionId': normalized.sessionId,
        'timeoutMs': normalized.timeoutMs,
        'locale': normalized.locale,
      },
    );
    _config = normalized;
    notifyListeners();
  }

  Future<void> save(GatewayConfig next) async {
    final normalized = _normalizeGateway(next);
    openClawLog(
      'SettingsController',
      'save config',
      fields: <String, Object?>{
        'gatewayUrl': normalized.gatewayUrl,
        'sessionId': normalized.sessionId,
        'timeoutMs': normalized.timeoutMs,
        'locale': normalized.locale,
      },
    );
    _config = normalized;
    await _configRepository?.save(normalized);
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
    await refreshSecuritySnapshot(notify: false);
    notifyListeners();
  }

  Future<void> resetDeviceIdentity() async {
    openClawLog('SettingsController', 'reset device identity');
    await _resetDeviceIdentityUseCase?.call();
    await _clearOperatorAuthUseCase?.call();
    await refreshSecuritySnapshot(notify: false);
    notifyListeners();
  }

  Future<void> importBootstrapToken(String input) async {
    await _importBootstrapTokenUseCase?.call(input);
    final persistedConfig = await _configRepository?.load();
    if (persistedConfig != null) {
      _config = _normalizeGateway(persistedConfig);
    }
    await refreshSecuritySnapshot(notify: false);
    notifyListeners();
  }

  Future<void> refreshSecuritySnapshot({bool notify = true}) async {
    final authRepository = _authRepository;
    if (authRepository == null) {
      _operatorAuth = null;
      _bootstrapToken = null;
      if (notify) {
        notifyListeners();
      }
      return;
    }

    final operatorAuth = await authRepository.loadOperatorAuth();
    final bootstrapToken = await authRepository.loadBootstrapToken();
    _operatorAuth = operatorAuth;
    _bootstrapToken =
        bootstrapToken != null && !bootstrapToken.isExpired ? bootstrapToken : null;
    if (notify) {
      notifyListeners();
    }
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
