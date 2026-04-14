import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:flutter_openclaw/src/application/use_cases/test_connection_use_case.dart';
import 'package:flutter_openclaw/src/domain/models/bootstrap_token_state.dart';
import 'package:flutter_openclaw/src/domain/models/device_identity.dart';
import 'package:flutter_openclaw/src/domain/models/gateway_config.dart';
import 'package:flutter_openclaw/src/domain/models/operator_auth_state.dart';
import 'package:flutter_openclaw/src/domain/repositories/auth_repository.dart';
import 'package:flutter_openclaw/src/infrastructure/config/dev_defaults.dart';
import 'package:flutter_openclaw/src/infrastructure/crypto/device_identity_service.dart';

void main() {
  test('connect uses default gateway url', () async {
    final capturedUris = <Uri>[];
    const identity = DeviceIdentity(
      id: 'device-123',
      publicKey: 'public-key',
    );

    final authRepository = _FakeAuthRepository(
      deviceIdentity: identity,
      operatorAuth: const OperatorAuthState(
        role: 'operator',
        deviceToken: 'device-token',
        scopes: <String>['operator.read'],
      ),
    );

    final useCase = TestConnectionUseCase(
      authRepository: authRepository,
      identityService: _FakeDeviceIdentityService(identity),
      channelFactory: (uri) {
        capturedUris.add(uri);
        return _FakeWebSocketChannel();
      },
    );

    const config = GatewayConfig(
      gatewayUrl: 'wss://example.invalid/gateway',
      sessionId: 'session-123',
      timeoutMs: 1,
      locale: 'en-US',
    );

    try {
      await useCase.connect(config: config);
    } catch (_) {}

    expect(capturedUris, hasLength(1));
    expect(capturedUris.single.toString(), defaultGatewayConfig.gatewayUrl);
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.deviceIdentity,
    this.operatorAuth,
    this.bootstrapToken,
  });

  DeviceIdentity? deviceIdentity;
  OperatorAuthState? operatorAuth;
  BootstrapTokenState? bootstrapToken;

  @override
  Future<DeviceIdentity?> loadDeviceIdentity() async => deviceIdentity;

  @override
  Future<void> saveDeviceIdentity(DeviceIdentity identity) async {
    deviceIdentity = identity;
  }

  @override
  Future<void> clearDeviceIdentity() async {
    deviceIdentity = null;
  }

  @override
  Future<OperatorAuthState?> loadOperatorAuth() async => operatorAuth;

  @override
  Future<void> saveOperatorAuth(OperatorAuthState state) async {
    operatorAuth = state;
  }

  @override
  Future<void> clearOperatorAuth() async {
    operatorAuth = null;
  }

  @override
  Future<BootstrapTokenState?> loadBootstrapToken() async => bootstrapToken;

  @override
  Future<void> saveBootstrapToken(BootstrapTokenState state) async {
    bootstrapToken = state;
  }

  @override
  Future<void> clearBootstrapToken() async {
    bootstrapToken = null;
  }
}

class _FakeDeviceIdentityService extends DeviceIdentityService {
  _FakeDeviceIdentityService(this.identity);

  final DeviceIdentity identity;

  @override
  Future<DeviceIdentity> create() async => identity;
}

class _FakeWebSocketChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  _FakeWebSocketChannel()
      : _stream = const Stream<dynamic>.empty(),
        _sink = _FakeWebSocketSink();

  final Stream<dynamic> _stream;
  final WebSocketSink _sink;

  @override
  Stream<dynamic> get stream => _stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  Future<void> get ready => Future.value();
}

class _FakeWebSocketSink implements WebSocketSink {
  final Completer<void> _done = Completer<void>();

  @override
  Future<void> get done => _done.future;

  @override
  void add(dynamic data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {
    await stream.drain<void>();
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) {
    if (!_done.isCompleted) {
      _done.complete();
    }
    return done;
  }
}
