import 'dart:io';

import '../../domain/models/connect_challenge.dart';
import '../../domain/models/connect_params.dart';
import '../../domain/models/device_identity.dart';
import '../config/dev_defaults.dart';
import 'keystore_signer.dart';

class ConnectSigner {
  static const String _clientId = 'cli';
  static const String _clientMode = 'probe';
  static const String _deviceFamily = 'cli';
  static const String _appVersion = '1.1.0';

  const ConnectSigner({KeystoreSigner? keystoreSigner})
      : _keystoreSigner = keystoreSigner ?? const KeystoreSigner();

  final KeystoreSigner _keystoreSigner;

  Future<ConnectParams> buildConnectParams({
    required ConnectChallenge challenge,
    required DeviceIdentity identity,
    required String authToken,
    required String deviceToken,
    required List<String> scopes,
    required String locale,
    int? signedAt,
    String? userAgent,
  }) async {
    final effectiveSignedAt = signedAt ?? DateTime.now().millisecondsSinceEpoch;
    final auth = _buildAuth(
      authToken: authToken,
      deviceToken: deviceToken,
    );
    final effectiveScopes = scopes.isNotEmpty ? scopes : defaultOperatorScopes;
    final payload = _buildPayload(
      identity: identity,
      signedAt: effectiveSignedAt,
      nonce: challenge.nonce,
      scopes: effectiveScopes,
      signingToken: auth.usesDeviceToken ? auth.deviceToken! : auth.token ?? '',
    );
    final signature = await _keystoreSigner.signPayload(payload);

    return ConnectParams(
      minProtocol: 3,
      maxProtocol: 3,
      role: 'operator',
      scopes: List<String>.from(effectiveScopes),
      client: ConnectClientInfo(
        id: _clientId,
        version: _appVersion,
        platform: _normalizePlatform(),
        deviceFamily: _deviceFamily,
        mode: _clientMode,
        instanceId: identity.id,
      ),
      locale: locale,
      userAgent: userAgent ?? 'my-openclaw-cli/$_appVersion',
      caps: const <String>[],
      commands: const <String>[],
      permissions: const <String, Object?>{},
      device: ConnectDeviceProof(
        id: identity.id,
        publicKey: identity.publicKey,
        signature: signature,
        signedAt: effectiveSignedAt,
        nonce: challenge.nonce,
      ),
      auth: auth,
    );
  }

  ConnectAuth _buildAuth({
    required String authToken,
    required String deviceToken,
  }) {
    if (deviceToken.trim().isNotEmpty) {
      return ConnectAuth(deviceToken: deviceToken.trim());
    }
    return ConnectAuth(token: authToken.trim());
  }

  String _normalizePlatform() {
    switch (Platform.operatingSystem) {
      case 'darwin':
        return 'macos';
      case 'win32':
        return 'windows';
      default:
        return Platform.operatingSystem;
    }
  }

  String _buildPayload({
    required DeviceIdentity identity,
    required int signedAt,
    required String nonce,
    required List<String> scopes,
    required String signingToken,
  }) {
    return [
      'v2',
      identity.id,
      _clientId,
      _clientMode,
      'operator',
      scopes.join(','),
      '$signedAt',
      signingToken,
      nonce,
    ].join('|');
  }
}
