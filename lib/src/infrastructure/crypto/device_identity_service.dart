import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../../domain/models/device_identity.dart';

class DeviceIdentityService {
  DeviceIdentityService({
    Ed25519? algorithm,
    HashAlgorithm? hasher,
  })  : _algorithm = algorithm ?? Ed25519(),
        _hasher = hasher ?? Sha256();

  final Ed25519 _algorithm;
  final HashAlgorithm _hasher;

  Future<DeviceIdentity> create() async {
    final keyPair = await _algorithm.newKeyPair();
    final keyPairData = await keyPair.extract();
    final publicBytes = keyPairData.publicKey.bytes;
    final privateBytes = keyPairData.bytes;

    return DeviceIdentity(
      id: await _deriveId(publicBytes),
      publicKey: base64.encode(publicBytes),
      privateKeyPem: _encodePem(privateBytes),
    );
  }

  Future<String> _deriveId(List<int> publicBytes) async {
    final digest = await _hasher.hash(publicBytes);
    return digest.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  String _encodePem(List<int> keyBytes) {
    const header = '-----BEGIN PRIVATE KEY-----';
    const footer = '-----END PRIVATE KEY-----';
    final encoded = base64.encode(_encodePkcs8(keyBytes));
    final buffer = StringBuffer()..writeln(header);

    for (var start = 0; start < encoded.length; start += 64) {
      final end = start + 64 < encoded.length ? start + 64 : encoded.length;
      buffer.writeln(encoded.substring(start, end));
    }

    buffer.write(footer);
    return buffer.toString();
  }

  List<int> _encodePkcs8(List<int> keyBytes) {
    if (keyBytes.length != 32) {
      throw StateError(
        'Ed25519 private key must be 32 bytes, got ${keyBytes.length}.',
      );
    }

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

    return <int>[...pkcs8Prefix, ...keyBytes];
  }
}
