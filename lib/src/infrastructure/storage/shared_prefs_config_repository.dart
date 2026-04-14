import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/gateway_config.dart';
import '../../domain/repositories/config_repository.dart';
import '../config/dev_defaults.dart';
import '../util/openclaw_logger.dart';

class SharedPrefsConfigRepository implements ConfigRepository {
  SharedPrefsConfigRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _storageKey = 'gateway_config';

  static Future<SharedPrefsConfigRepository> inMemory() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return SharedPrefsConfigRepository(prefs);
  }

  GatewayConfig _normalizeGateway(GatewayConfig config) {
    if (config.gatewayUrl == defaultGatewayConfig.gatewayUrl) {
      return config;
    }
    return config.copyWith(gatewayUrl: defaultGatewayConfig.gatewayUrl);
  }

  @override
  Future<GatewayConfig> load() async {
    final jsonString = _prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      openClawLog('ConfigRepository', 'load default config: no persisted value');
      return defaultGatewayConfig;
    }

    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      map.remove('authToken');
      final config = _normalizeGateway(GatewayConfig.fromJson(map));
      openClawLog(
        'ConfigRepository',
        'load persisted config',
        fields: <String, Object?>{
          'gatewayUrl': config.gatewayUrl,
          'sessionId': config.sessionId,
          'timeoutMs': config.timeoutMs,
          'locale': config.locale,
        },
      );
      return config;
    } catch (_) {
      openClawLog(
        'ConfigRepository',
        'load config failed, fallback to default',
        fields: <String, Object?>{
          'raw': truncateForLog(jsonString, maxLength: 160),
        },
      );
      return defaultGatewayConfig;
    }
  }

  @override
  Future<void> save(GatewayConfig config) async {
    final normalized = _normalizeGateway(config);
    final encoded = jsonEncode(normalized.toJson());
    openClawLog(
      'ConfigRepository',
      'save config',
      fields: <String, Object?>{
        'gatewayUrl': normalized.gatewayUrl,
        'sessionId': normalized.sessionId,
        'timeoutMs': normalized.timeoutMs,
        'locale': normalized.locale,
      },
    );
    await _prefs.setString(_storageKey, encoded);
  }
}
