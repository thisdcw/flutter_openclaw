import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_openclaw/src/domain/models/gateway_config.dart';
import 'package:flutter_openclaw/src/infrastructure/config/dev_defaults.dart';
import 'package:flutter_openclaw/src/infrastructure/storage/shared_prefs_config_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('save normalizes gatewayUrl to default', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = SharedPrefsConfigRepository(prefs);

    const config = GatewayConfig(
      gatewayUrl: 'wss://example.invalid/gateway',
      sessionId: 'session-123',
      timeoutMs: 1234,
      locale: 'en-US',
    );

    await repository.save(config);

    final stored = prefs.getString('gateway_config');
    expect(stored, isNotNull);

    final payload = jsonDecode(stored!) as Map<String, dynamic>;
    expect(payload['gatewayUrl'], defaultGatewayConfig.gatewayUrl);
    expect(payload['sessionId'], config.sessionId);
    expect(payload['timeoutMs'], config.timeoutMs);
    expect(payload['locale'], config.locale);
  });

  test('load normalizes gatewayUrl to default', () async {
    const storedConfig = <String, Object?>{
      'gatewayUrl': 'wss://example.invalid/other',
      'sessionId': 'session-456',
      'timeoutMs': 5678,
      'locale': 'fr-FR',
    };

    SharedPreferences.setMockInitialValues({
      'gateway_config': jsonEncode(storedConfig),
    });

    final prefs = await SharedPreferences.getInstance();
    final repository = SharedPrefsConfigRepository(prefs);

    final config = await repository.load();

    expect(config.gatewayUrl, defaultGatewayConfig.gatewayUrl);
    expect(config.sessionId, storedConfig['sessionId']);
    expect(config.timeoutMs, storedConfig['timeoutMs']);
    expect(config.locale, storedConfig['locale']);
  });
}
