import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../domain/models/connection_status.dart';
import '../../domain/models/device_identity.dart';
import '../../domain/models/gateway_config.dart';
import '../../domain/models/operator_auth_state.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../infrastructure/crypto/connect_signer.dart';
import '../../infrastructure/crypto/device_identity_service.dart';
import '../../infrastructure/gateway/gateway_client.dart';
import '../../infrastructure/gateway/gateway_frame.dart';
import '../../infrastructure/gateway/gateway_protocol_parser.dart';
import '../../infrastructure/util/openclaw_logger.dart';

class AuthenticatedGatewaySession {
  AuthenticatedGatewaySession({
    required this.client,
    required this.status,
    required this.deviceIdentity,
    required this.operatorAuth,
  });

  final GatewayClient client;
  final ConnectionStatus status;
  final DeviceIdentity deviceIdentity;
  final OperatorAuthState? operatorAuth;

  Future<void> dispose() => client.dispose();
}

class TestConnectionUseCase {
  TestConnectionUseCase({
    required AuthRepository authRepository,
    required DeviceIdentityService identityService,
    ConnectSigner? signer,
    GatewayProtocolParser? parser,
    WebSocketChannel Function(Uri uri)? channelFactory,
    Uuid? uuid,
  })  : _authRepository = authRepository,
        _identityService = identityService,
        _signer = signer ?? const ConnectSigner(),
        _parser = parser ?? const GatewayProtocolParser(),
        _channelFactory = channelFactory,
        _uuid = uuid ?? const Uuid();

  final AuthRepository _authRepository;
  final DeviceIdentityService _identityService;
  final ConnectSigner _signer;
  final GatewayProtocolParser _parser;
  final WebSocketChannel Function(Uri uri)? _channelFactory;
  final Uuid _uuid;

  Future<ConnectionStatus> call({
    required GatewayConfig config,
  }) async {
    final session = await connect(config: config);
    try {
      return session.status;
    } finally {
      await session.dispose();
    }
  }

  Future<AuthenticatedGatewaySession> connect({
    required GatewayConfig config,
  }) async {
    openClawLog(
      'TestConnection',
      'connect start',
      fields: <String, Object?>{
        'gatewayUrl': config.gatewayUrl,
        'sessionId': config.sessionId,
        'timeoutMs': config.timeoutMs,
        'locale': config.locale,
        'authToken': redactValue(config.authToken),
      },
    );
    final authToken = await _resolveAuthToken(config);
    final existingIdentity = await _authRepository.loadDeviceIdentity();
    final deviceIdentity = existingIdentity ?? await _identityService.create();
    openClawLog(
      'TestConnection',
      'device identity ready',
      fields: <String, Object?>{
        'deviceId': deviceIdentity.id,
        'identitySource': existingIdentity == null ? 'generated' : 'persisted',
      },
    );
    if (existingIdentity == null) {
      await _authRepository.saveDeviceIdentity(deviceIdentity);
    }

    final operatorAuth = await _authRepository.loadOperatorAuth();
    openClawLog(
      'TestConnection',
      'operator auth snapshot',
      fields: <String, Object?>{
        'hasDeviceToken': (operatorAuth?.deviceToken ?? '').isNotEmpty,
        'deviceToken': redactValue(operatorAuth?.deviceToken ?? ''),
        'scopes': operatorAuth?.scopes.join(',') ?? '(none)',
        'resolvedAuthToken': redactValue(authToken),
      },
    );
    final channel = (_channelFactory ?? WebSocketChannel.connect)(
      Uri.parse(config.gatewayUrl),
    );
    openClawLog('TestConnection', 'websocket channel created');
    final client = GatewayClient(
      channel: channel,
      parser: _parser,
    );
    client.start();

    try {
      openClawLog('TestConnection', 'waiting for connect.challenge');
      final challenge = await client.frames
          .firstWhere((frame) => frame.isConnectChallenge)
          .timeout(Duration(milliseconds: config.timeoutMs));
      final challengeModel = _parser.extractChallenge(challenge);
      openClawLog(
        'TestConnection',
        'received connect.challenge',
        fields: <String, Object?>{
          'nonce': challengeModel.nonce,
        },
      );
      final connectParams = await _signer.buildConnectParams(
        challenge: challengeModel,
        identity: deviceIdentity,
        authToken: authToken,
        deviceToken: operatorAuth?.deviceToken ?? '',
        locale: config.locale,
      );
      final requestId = 'auth-${_uuid.v4()}';
      openClawLog(
        'TestConnection',
        'sending connect',
        fields: <String, Object?>{
          'requestId': requestId,
          'authMode': connectParams.auth.usesDeviceToken
              ? 'deviceToken'
              : 'token',
          'deviceToken': redactValue(connectParams.auth.deviceToken ?? ''),
          'authToken': redactValue(connectParams.auth.token ?? ''),
          'clientMode': connectParams.client.mode,
          'deviceId': connectParams.device.id,
          'scopes': connectParams.scopes.join(','),
        },
      );

      client.send(
        <String, Object?>{
          'type': 'req',
          'id': requestId,
          'method': 'connect',
          'params': connectParams.payload,
        },
      );

      final response = await client.frames
          .firstWhere(
            (frame) =>
                frame.isHelloOk ||
                (frame.type == 'res' &&
                    frame.id == requestId &&
                    frame.isErrorResponse),
          )
          .timeout(Duration(milliseconds: config.timeoutMs));
      openClawLog(
        'TestConnection',
        'received auth response',
        fields: <String, Object?>{
          'type': response.type,
          'id': response.id,
          'event': response.event,
          'payloadType': response.payloadType,
          'isError': response.isErrorResponse,
          'payload': truncateForLog(response.payload.toString(), maxLength: 220),
        },
      );

      final failure = _parser.extractFailure(response);
      if (failure != null) {
        openClawLog(
          'TestConnection',
          'auth failed',
          fields: <String, Object?>{
            'code': failure.code,
            'reason': failure.reason,
            'message': failure.message,
          },
        );
        throw StateError(failure.message);
      }

      final nextAuth = _parser.extractHelloOkAuth(response) ?? operatorAuth;
      if (nextAuth != null) {
        await _authRepository.saveOperatorAuth(nextAuth);
        openClawLog(
          'TestConnection',
          'persisted operator auth',
          fields: <String, Object?>{
            'deviceToken': redactValue(nextAuth.deviceToken),
            'scopes': nextAuth.scopes.join(','),
          },
        );
      }
      if (authToken.trim().isNotEmpty) {
        await _authRepository.saveAuthToken(authToken);
      }

      openClawLog(
        'TestConnection',
        'connect success',
        fields: <String, Object?>{
          'deviceId': deviceIdentity.id,
          'grantedScopes': nextAuth?.scopes.join(',') ?? '(none)',
        },
      );

      return AuthenticatedGatewaySession(
        client: client,
        deviceIdentity: deviceIdentity,
        operatorAuth: nextAuth,
        status: ConnectionStatus(
          phase: ConnectionPhase.ready,
          grantedScopes: nextAuth?.scopes ?? const <String>[],
          deviceId: deviceIdentity.id,
        ),
      );
    } catch (error) {
      openClawLog(
        'TestConnection',
        'connect exception',
        fields: <String, Object?>{
          'error': error.toString(),
        },
      );
      await client.dispose();
      rethrow;
    }
  }

  Future<String> _resolveAuthToken(GatewayConfig config) async {
    if (config.authToken.trim().isNotEmpty) {
      openClawLog(
        'TestConnection',
        'resolve auth token from config',
        fields: <String, Object?>{
          'value': redactValue(config.authToken),
        },
      );
      return config.authToken;
    }
    final persistedToken = await _authRepository.loadAuthToken();
    if ((persistedToken ?? '').trim().isNotEmpty) {
      openClawLog(
        'TestConnection',
        'resolve auth token from secure storage',
        fields: <String, Object?>{
          'value': redactValue(persistedToken!),
        },
      );
      return persistedToken!;
    }
    openClawLog('TestConnection', 'resolve auth token: empty');
    return '';
  }
}
