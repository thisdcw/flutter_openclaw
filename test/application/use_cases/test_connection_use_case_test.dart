import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:flutter_openclaw/src/application/use_cases/test_connection_use_case.dart';
import 'package:flutter_openclaw/src/domain/models/bootstrap_token_state.dart';
import 'package:flutter_openclaw/src/domain/models/device_identity.dart';
import 'package:flutter_openclaw/src/domain/models/gateway_config.dart';
import 'package:flutter_openclaw/src/domain/models/operator_auth_state.dart';
import 'package:flutter_openclaw/src/domain/repositories/auth_repository.dart';
import 'package:flutter_openclaw/src/infrastructure/crypto/connect_signer.dart';
import 'package:flutter_openclaw/src/infrastructure/crypto/device_identity_service.dart';
import 'package:flutter_openclaw/src/infrastructure/crypto/keystore_signer.dart';

void main() {
  test('connect uses config gateway url as-is', () async {
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
      gatewayUrl: 'wss://example.invalid',
      sessionId: 'session-123',
      timeoutMs: 1,
      locale: 'en-US',
    );

    try {
      await useCase.connect(config: config);
    } catch (_) {}

    expect(capturedUris, hasLength(1));
    expect(capturedUris.single.toString(), config.gatewayUrl);
  });

  test('connect rejects legacy /claw gateway url', () async {
    final capturedUris = <Uri>[];
    const identity = DeviceIdentity(
      id: 'device-123',
      publicKey: 'public-key',
    );

    final authRepository = _FakeAuthRepository(deviceIdentity: identity);
    final useCase = TestConnectionUseCase(
      authRepository: authRepository,
      identityService: _FakeDeviceIdentityService(identity),
      channelFactory: (uri) {
        capturedUris.add(uri);
        return _FakeWebSocketChannel();
      },
    );

    const config = GatewayConfig(
      gatewayUrl: 'wss://example.invalid/claw?x=y',
      sessionId: 'session-123',
      timeoutMs: 1,
      locale: 'en-US',
    );

    await expectLater(
      useCase.connect(config: config),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          '检测到旧版本网关地址，请重新导入配对码。',
        ),
      ),
    );
    expect(capturedUris, isEmpty);
  });

  test('bootstrap pairing connect sends auth.bootstrapToken', () async {
    const identity = DeviceIdentity(
      id: 'device-123',
      publicKey: 'public-key',
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    final authRepository = _FakeAuthRepository(
      deviceIdentity: identity,
      bootstrapToken: BootstrapTokenState(
        token: 'bootstrap-token',
        gatewayUrl: 'wss://example.invalid',
        importedAt: now - 1000,
        expiresAt: now + 60000,
      ),
    );
    final channel = _ScriptedWebSocketChannel(
      challengeFrame: <String, Object?>{
        'type': 'event',
        'event': 'connect.challenge',
        'payload': <String, Object?>{'nonce': 'nonce-123'},
      },
      helloFrame: <String, Object?>{
        'type': 'res',
        'ok': true,
        'payload': <String, Object?>{
          'type': 'hello-ok',
          'auth': <String, Object?>{
            'role': 'operator',
            'deviceToken': 'issued-device-token',
            'scopes': <String>['operator.read', 'operator.write'],
          },
        },
      },
    );

    final useCase = TestConnectionUseCase(
      authRepository: authRepository,
      identityService: _FakeDeviceIdentityService(identity),
      signer: ConnectSigner(
        keystoreSigner: KeystoreSigner(store: InMemoryKeystoreSignerStore()),
      ),
      channelFactory: (_) => channel,
    );

    const config = GatewayConfig(
      gatewayUrl: 'wss://example.invalid',
      sessionId: 'session-123',
      timeoutMs: 2000,
      locale: 'en-US',
    );

    final session = await useCase.connect(config: config);
    await session.dispose();

    final connectFrame = channel.sentFrames.singleWhere(
      (frame) => frame['method'] == 'connect',
    );
    final params = Map<String, dynamic>.from(
      connectFrame['params'] as Map<dynamic, dynamic>,
    );
    final auth = Map<String, dynamic>.from(
      params['auth'] as Map<dynamic, dynamic>,
    );

    expect(auth['bootstrapToken'], 'bootstrap-token');
    expect(auth.containsKey('token'), isFalse);
    expect(auth.containsKey('deviceToken'), isFalse);
    expect(authRepository.operatorAuth?.deviceToken, 'issued-device-token');
    expect(authRepository.bootstrapToken, isNull);
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

class _FakeWebSocketChannel implements WebSocketChannel {
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

class _ScriptedWebSocketChannel implements WebSocketChannel {
  _ScriptedWebSocketChannel({
    required Map<String, Object?> challengeFrame,
    required Map<String, Object?> helloFrame,
  })  : _challengeFrame = Map<String, Object?>.from(challengeFrame),
        _helloFrame = Map<String, Object?>.from(helloFrame),
        _sink = _ScriptedWebSocketSink() {
    _sink.onAdd = _handleOutgoing;
    _sink.onClose = _closeIncoming;
    scheduleMicrotask(() {
      if (!_incoming.isClosed) {
        _incoming.add(jsonEncode(_challengeFrame));
      }
    });
  }

  final Map<String, Object?> _challengeFrame;
  final Map<String, Object?> _helloFrame;
  final StreamController<dynamic> _incoming =
      StreamController<dynamic>.broadcast();
  final List<Map<String, dynamic>> _sentFrames = <Map<String, dynamic>>[];
  final _ScriptedWebSocketSink _sink;
  bool _helloQueued = false;

  List<Map<String, dynamic>> get sentFrames =>
      List<Map<String, dynamic>>.unmodifiable(_sentFrames);

  @override
  Stream<dynamic> get stream => _incoming.stream;

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

  void _handleOutgoing(dynamic data) {
    if (data is! String) {
      return;
    }
    final decoded = jsonDecode(data);
    if (decoded is! Map) {
      return;
    }
    final frame = Map<String, dynamic>.from(decoded);
    _sentFrames.add(frame);
    if (_helloQueued) {
      return;
    }
    _helloQueued = true;
    scheduleMicrotask(() {
      if (!_incoming.isClosed) {
        _incoming.add(jsonEncode(_helloFrame));
      }
    });
  }

  void _closeIncoming() {
    if (!_incoming.isClosed) {
      _incoming.close();
    }
  }
}

class _ScriptedWebSocketSink implements WebSocketSink {
  final Completer<void> _done = Completer<void>();
  void Function(dynamic data)? onAdd;
  void Function()? onClose;

  @override
  Future<void> get done => _done.future;

  @override
  void add(dynamic data) {
    onAdd?.call(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {
    await stream.drain<void>();
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) {
    onClose?.call();
    if (!_done.isCompleted) {
      _done.complete();
    }
    return done;
  }
}
