import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../../domain/models/device_identity.dart';
import 'keystore_signer.dart';

class DeviceIdentityService {
  DeviceIdentityService({
    HashAlgorithm? hasher,
    KeystoreSigner? keystoreSigner,
  })  : _hasher = hasher ?? Sha256(),
        _keystoreSigner = keystoreSigner ?? KeystoreSigner();

  final HashAlgorithm _hasher;
  final KeystoreSigner _keystoreSigner;

  Future<DeviceIdentity> create() async {
    final publicKeyBase64 = await _keystoreSigner.ensureKeypair();
    final publicBytes = base64.decode(publicKeyBase64);
    final id = await _deriveId(publicBytes);

    return DeviceIdentity(
      id: id,
      publicKey: publicKeyBase64,
    );
  }

  Future<String> _deriveId(List<int> publicBytes) async {
    final digest = await _hasher.hash(publicBytes);
    return digest.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
