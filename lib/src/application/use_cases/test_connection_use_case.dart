import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../domain/models/bootstrap_token_state.dart';
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
      },
    );
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
    final bootstrapToken = await _authRepository.loadBootstrapToken();
    openClawLog(
      'TestConnection',
      'operator auth snapshot',
      fields: <String, Object?>{
        'hasDeviceToken': (operatorAuth?.deviceToken ?? '').isNotEmpty,
        'deviceToken': redactValue(operatorAuth?.deviceToken ?? ''),
        'scopes': operatorAuth?.scopes.join(',') ?? '(none)',
      },
    );
    openClawLog(
      'TestConnection',
      'bootstrap token snapshot',
      fields: <String, Object?>{
        'hasBootstrapToken': bootstrapToken != null,
        'bootstrapExpired': bootstrapToken?.isExpired ?? false,
        'gatewayUrl': bootstrapToken?.gatewayUrl ?? '(none)',
      },
    );
    final trimmedDeviceToken = (operatorAuth?.deviceToken ?? '').trim();
    final hasDeviceToken = trimmedDeviceToken.isNotEmpty;
    final hasUsableBootstrapToken = !hasDeviceToken &&
        bootstrapToken != null &&
        !bootstrapToken.isExpired;
    if (!hasDeviceToken && !hasUsableBootstrapToken) {
      openClawLog(
        'TestConnection',
        'missing auth credentials',
        fields: <String, Object?>{
          'hasDeviceToken': hasDeviceToken,
          'hasBootstrapToken': bootstrapToken != null,
          'bootstrapExpired': bootstrapToken?.isExpired ?? false,
        },
      );
      throw StateError(
        '缺少可用的设备令牌或配对码，请导入配对码后再试。',
      );
    }
    final usingBootstrapToken = !hasDeviceToken && hasUsableBootstrapToken;
    final selectedAuthToken = usingBootstrapToken ? bootstrapToken!.token : '';
    final selectedDeviceToken = usingBootstrapToken ? '' : trimmedDeviceToken;
    final scopesForConnect = operatorAuth?.scopes ?? const [];
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
        authToken: selectedAuthToken,
        deviceToken: selectedDeviceToken,
        scopes: scopesForConnect,
        locale: config.locale,
      );
      final requestId = 'auth-${_uuid.v4()}';
      openClawLog(
        'TestConnection',
        'sending connect',
        fields: <String, Object?>{
          'requestId': requestId,
          'authSource': usingBootstrapToken ? 'bootstrapToken' : 'deviceToken',
          'authMode': connectParams.auth.usesDeviceToken ? 'deviceToken' : 'token',
          'deviceToken': redactValue(connectParams.auth.deviceToken ?? ''),
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
      openClawLog(
        'TestConnection',
        'connect success',
        fields: <String, Object?>{
          'deviceId': deviceIdentity.id,
          'grantedScopes': nextAuth?.scopes.join(',') ?? '(none)',
          'usedBootstrapToken': usingBootstrapToken,
        },
      );
      if (bootstrapToken != null && bootstrapToken.isExpired) {
        await _authRepository.clearBootstrapToken();
        openClawLog(
          'TestConnection',
          'cleared expired bootstrap token',
          fields: <String, Object?>{
            'gatewayUrl': bootstrapToken.gatewayUrl,
          },
        );
      }

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

}
