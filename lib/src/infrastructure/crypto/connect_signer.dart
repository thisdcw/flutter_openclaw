import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

import '../../domain/models/connect_challenge.dart';
import '../../domain/models/connect_params.dart';
import '../../domain/models/device_identity.dart';
import '../config/dev_defaults.dart';

class ConnectSigner {
  static const String _clientId = 'cli';
  static const String _clientMode = 'probe';
  static const String _deviceFamily = 'cli';
  static const String _appVersion = '1.1.0';

  const ConnectSigner();

  Future<ConnectParams> buildConnectParams({
    required ConnectChallenge challenge,
    required DeviceIdentity identity,
    required String authToken,
    required String deviceToken,
    required String locale,
    int? signedAt,
    String? userAgent,
  }) async {
    final effectiveSignedAt = signedAt ?? DateTime.now().millisecondsSinceEpoch;
    final auth = _buildAuth(
      authToken: authToken,
      deviceToken: deviceToken,
    );
    final signature = await _signPayload(
      identity: identity,
      nonce: challenge.nonce,
      signedAt: effectiveSignedAt,
      signingToken: auth.usesDeviceToken ? auth.deviceToken! : auth.token ?? '',
    );

    return ConnectParams(
      minProtocol: 3,
      maxProtocol: 3,
      role: 'operator',
      scopes: List<String>.from(defaultOperatorScopes),
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

  Future<String> _signPayload({
    required DeviceIdentity identity,
    required String nonce,
    required int signedAt,
    required String signingToken,
  }) async {
    final payload = [
      'v2',
      identity.id,
      _clientId,
      _clientMode,
      'operator',
      defaultOperatorScopes.join(','),
      '$signedAt',
      signingToken,
      nonce,
    ].join('|');

    final algorithm = Ed25519();
    final publicKeyBytes = base64.decode(identity.publicKey);
    final privateKeyBytes = _decodePkcs8Pem(identity.privateKeyPem);
    final keyPair = SimpleKeyPairData(
      privateKeyBytes,
      publicKey: SimplePublicKey(
        publicKeyBytes,
        type: KeyPairType.ed25519,
      ),
      type: KeyPairType.ed25519,
    );

    final signature = await algorithm.sign(
      utf8.encode(payload),
      keyPair: keyPair,
    );
    return _base64UrlEncode(signature.bytes);
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

  List<int> _decodePkcs8Pem(String pem) {
    final normalized = pem
        .replaceAll('-----BEGIN PRIVATE KEY-----', '')
        .replaceAll('-----END PRIVATE KEY-----', '')
        .replaceAll(RegExp(r'\s+'), '');

    final decoded = base64.decode(normalized);
    const pkcs8Prefix = <int>[
      0x30,
      0x2e,
      0x02,
      0x01,
      0x00,
      0x30,
      0x05,
      0x06,
      0x03,
      0x2b,
      0x65,
      0x70,
      0x04,
      0x22,
      0x04,
      0x20,
    ];

    if (decoded.length != pkcs8Prefix.length + 32) {
      throw FormatException(
        'ConnectSigner: PKCS#8 Ed25519 private key must contain 32 raw bytes.',
      );
    }

    for (var index = 0; index < pkcs8Prefix.length; index++) {
      if (decoded[index] != pkcs8Prefix[index]) {
        throw FormatException(
          'ConnectSigner: unsupported PKCS#8 private key prefix.',
        );
      }
    }

    return decoded.sublist(pkcs8Prefix.length);
  }

  String _base64UrlEncode(List<int> value) {
    return base64Url.encode(value).replaceAll('=', '');
  }
}
