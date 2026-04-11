import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_openclaw/src/domain/models/gateway_config.dart';
import 'package:flutter_openclaw/src/infrastructure/config/dev_defaults.dart';
import 'package:flutter_openclaw/src/infrastructure/storage/shared_prefs_config_repository.dart';

void main() {
  group('SharedPrefsConfigRepository', () {
    test('load returns default when nothing is persisted', () async {
      final repository = await SharedPrefsConfigRepository.inMemory();
      final config = await repository.load();
      expect(config, defaultGatewayConfig);
    });

    test('saved configs round-trip through shared prefs', () async {
      final repository = await SharedPrefsConfigRepository.inMemory();
      final customConfig = const GatewayConfig(
        gatewayUrl: 'wss://example.com',
        authToken: 'token-1',
        sessionId: 'in-memory',
        timeoutMs: 30,
        locale: 'en-US',
      );
      await repository.save(customConfig);
      final loaded = await repository.load();
      expect(loaded, customConfig);
    });
  });
}
