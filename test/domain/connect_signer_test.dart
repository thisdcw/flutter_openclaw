import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_openclaw/src/domain/models/connect_challenge.dart';
import 'package:flutter_openclaw/src/domain/models/device_identity.dart';
import 'package:flutter_openclaw/src/infrastructure/config/dev_defaults.dart';
import 'package:flutter_openclaw/src/infrastructure/crypto/connect_signer.dart';

void main() {
  group('ConnectSigner', () {
    test('builds connect payload with operator role and scopes', () async {
      const challenge = ConnectChallenge(nonce: 'nonce-1');
      final identity = await _identityFromSeed(
        List<int>.generate(32, (index) => index + 1),
      );

      final payload = await const ConnectSigner().buildConnectParams(
        challenge: challenge,
        identity: identity,
        authToken: 'auth-1',
        deviceToken: '',
        locale: 'zh-CN',
        signedAt: 1712822400000,
      );

      expect(payload.role, 'operator');
      expect(payload.scopes, defaultOperatorScopes);
      expect(payload.auth.toJson()['token'], 'auth-1');
      expect(payload.device.id, identity.id);
      expect(payload.device.nonce, 'nonce-1');
      expect(payload.device.signature, isNotEmpty);
    });

    test('prefers device token and emits a verifiable base64url signature',
        () async {
      const challenge = ConnectChallenge(nonce: 'nonce-2');
      final identity = await _identityFromSeed(
        List<int>.generate(32, (index) => 255 - index),
      );

      final payload = await const ConnectSigner().buildConnectParams(
        challenge: challenge,
        identity: identity,
        authToken: 'ignored-auth-token',
        deviceToken: 'device-token-1',
        locale: 'zh-CN',
        signedAt: 1712822400001,
      );

      expect(payload.auth.toJson()['deviceToken'], 'device-token-1');
      expect(payload.device.signature.contains('+'), isFalse);
      expect(payload.device.signature.contains('/'), isFalse);
      expect(payload.device.signature.contains('='), isFalse);

      final message = [
        'v2',
        identity.id,
        'cli',
        'probe',
        'operator',
        defaultOperatorScopes.join(','),
        '1712822400001',
        'device-token-1',
        'nonce-2',
      ].join('|');

      final verified = await Ed25519().verify(
        utf8.encode(message),
        signature: Signature(
          base64Url.decode(_padBase64Url(payload.device.signature)),
          publicKey: SimplePublicKey(
            base64.decode(identity.publicKey),
            type: KeyPairType.ed25519,
          ),
        ),
      );

      expect(verified, isTrue);
    });
  });
}

Future<DeviceIdentity> _identityFromSeed(List<int> seed) async {
  final keyPair = await Ed25519().newKeyPairFromSeed(seed);
  final keyPairData = await keyPair.extract();
  final publicKey = await keyPair.extractPublicKey();

  return DeviceIdentity(
    id: await _sha256Hex(publicKey.bytes),
    publicKey: base64.encode(publicKey.bytes),
    privateKeyPem: _encodePem(keyPairData.bytes),
  );
}

Future<String> _sha256Hex(List<int> value) async {
  final digest = await Sha256().hash(value);
  return digest.bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
}

String _encodePem(List<int> keyBytes) {
  const header = '-----BEGIN PRIVATE KEY-----';
  const footer = '-----END PRIVATE KEY-----';
  const prefix = <int>[
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

  final encoded = base64.encode(<int>[...prefix, ...keyBytes]);
  final buffer = StringBuffer()..writeln(header);
  for (var start = 0; start < encoded.length; start += 64) {
    final end = start + 64 < encoded.length ? start + 64 : encoded.length;
    buffer.writeln(encoded.substring(start, end));
  }
  buffer.write(footer);
  return buffer.toString();
}

String _padBase64Url(String value) {
  final remainder = value.length % 4;
  if (remainder == 0) {
    return value;
  }
  return '$value${'=' * (4 - remainder)}';
}
