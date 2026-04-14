import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_openclaw/src/application/use_cases/import_bootstrap_token_use_case.dart';
import 'package:flutter_openclaw/src/domain/models/bootstrap_token_state.dart';
import 'package:flutter_openclaw/src/domain/models/device_identity.dart';
import 'package:flutter_openclaw/src/domain/models/gateway_config.dart';
import 'package:flutter_openclaw/src/domain/models/operator_auth_state.dart';
import 'package:flutter_openclaw/src/domain/repositories/auth_repository.dart';
import 'package:flutter_openclaw/src/domain/repositories/config_repository.dart';
import 'package:flutter_openclaw/src/infrastructure/util/bootstrap_payload_parser.dart';

void main() {
  test('rejects /claw gateway url', () async {
    const payload = <String, Object?>{
      'url': 'wss://thisdcw.cn/claw',
      'bootstrapToken': 'boot',
    };
    final encoded = base64Url.encode(utf8.encode(jsonEncode(payload)));

    final useCase = ImportBootstrapTokenUseCase(
      _InMemoryAuthRepository(),
      _InMemoryConfigRepository(
        const GatewayConfig(
          gatewayUrl: 'wss://example.invalid',
          sessionId: 'session-1',
          timeoutMs: 1000,
          locale: 'en-US',
        ),
      ),
      BootstrapPayloadParser(),
    );

    expect(
      () => useCase.call(encoded),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          '配对码无效：请重新获取配对码（正确地址应为 wss://thisdcw.cn）。',
        ),
      ),
    );
  });

  test('persists gateway url and bootstrap token', () async {
    const payload = <String, Object?>{
      'url': 'wss://example.invalid',
      'bootstrapToken': 'boot-token',
    };
    final encoded = base64Url.encode(utf8.encode(jsonEncode(payload)));

    final authRepository = _InMemoryAuthRepository();
    final configRepository = _InMemoryConfigRepository(
      const GatewayConfig(
        gatewayUrl: 'wss://old.invalid',
        sessionId: 'session-1',
        timeoutMs: 1000,
        locale: 'en-US',
      ),
    );

    final useCase = ImportBootstrapTokenUseCase(
      authRepository,
      configRepository,
      BootstrapPayloadParser(),
    );

    final state = await useCase.call(encoded);

    expect(state.gatewayUrl, 'wss://example.invalid');
    expect(state.token, 'boot-token');
    expect(authRepository.bootstrap?.gatewayUrl, 'wss://example.invalid');
    expect(authRepository.bootstrap?.token, 'boot-token');
    expect(configRepository.config.gatewayUrl, 'wss://example.invalid');
  });
}

class _InMemoryAuthRepository implements AuthRepository {
  BootstrapTokenState? bootstrap;
  DeviceIdentity? identity;
  OperatorAuthState? operatorAuth;

  @override
  Future<void> saveBootstrapToken(BootstrapTokenState state) async {
    bootstrap = state;
  }

  @override
  Future<BootstrapTokenState?> loadBootstrapToken() async => bootstrap;

  @override
  Future<void> clearBootstrapToken() async {
    bootstrap = null;
  }

  @override
  Future<void> saveDeviceIdentity(DeviceIdentity identity) async {
    this.identity = identity;
  }

  @override
  Future<DeviceIdentity?> loadDeviceIdentity() async => identity;

  @override
  Future<void> clearDeviceIdentity() async {
    identity = null;
  }

  @override
  Future<void> saveOperatorAuth(OperatorAuthState state) async {
    operatorAuth = state;
  }

  @override
  Future<OperatorAuthState?> loadOperatorAuth() async => operatorAuth;

  @override
  Future<void> clearOperatorAuth() async {
    operatorAuth = null;
  }
}

class _InMemoryConfigRepository implements ConfigRepository {
  _InMemoryConfigRepository(this.config);

  @override
  GatewayConfig config;

  @override
  Future<GatewayConfig> load() async => config;

  @override
  Future<void> save(GatewayConfig config) async {
    this.config = config;
  }
}
