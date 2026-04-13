import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class KeystoreSignerStore {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
}

class KeystoreSigner {
  KeystoreSigner({
    MethodChannel? channel,
    KeystoreSignerStore? store,
    Ed25519? algorithm,
  })  : _channel = channel ?? const MethodChannel(_channelName),
        _store = store ?? _FlutterSecureKeystoreSignerStore(),
        _algorithm = algorithm ?? Ed25519();

  static const String _channelName = 'openclaw/keystore';
  static const String _backendKey = 'openclaw.signing.backend';
  static const String _softwarePublicKey = 'openclaw.signing.public_key';
  static const String _softwarePrivateKey = 'openclaw.signing.private_key';
  static const String _nativeBackend = 'native_android_keystore';
  static const String _softwareBackend = 'software_ed25519';

  final MethodChannel _channel;
  final KeystoreSignerStore _store;
  final Ed25519 _algorithm;

  Future<String> ensureKeypair() async {
    final backend = await _store.read(key: _backendKey);
    if (backend == _softwareBackend) {
      return _ensureSoftwareKeypair();
    }

    try {
      final publicKey = await _channel.invokeMethod<String>('ensureKeypair');
      if (publicKey == null || publicKey.isEmpty) {
        throw StateError('KeystoreSigner: missing public key');
      }
      await _store.write(key: _backendKey, value: _nativeBackend);
      return publicKey;
    } on MissingPluginException {
      if (backend == _nativeBackend) rethrow;
      return _ensureSoftwareKeypair();
    } on PlatformException {
      if (backend == _nativeBackend) rethrow;
      return _ensureSoftwareKeypair();
    }
  }

  Future<String> signPayload(String payload) async {
    final backend = await _resolveBackend();
    if (backend == _softwareBackend) {
      return _signWithSoftwareKey(payload);
    }

    final signature = await _channel.invokeMethod<String>(
      'signPayload',
      {'payload': payload},
    );
    if (signature == null || signature.isEmpty) {
      throw StateError('KeystoreSigner: missing signature');
    }
    return signature;
  }

  Future<void> clearKeypair() async {
    try {
      await _channel.invokeMethod('clearKeypair');
    } on MissingPluginException {
      // Ignore: software fallback may be the active backend.
    } on PlatformException {
      // Ignore: software fallback may be the active backend.
    }
    await _store.delete(key: _backendKey);
    await _store.delete(key: _softwarePublicKey);
    await _store.delete(key: _softwarePrivateKey);
  }

  Future<String> _resolveBackend() async {
    final backend = await _store.read(key: _backendKey);
    if (backend != null && backend.isNotEmpty) {
      return backend;
    }
    await ensureKeypair();
    return await _store.read(key: _backendKey) ?? _nativeBackend;
  }

  Future<String> _ensureSoftwareKeypair() async {
    final existingPublicKey = await _store.read(key: _softwarePublicKey);
    final existingPrivateKey = await _store.read(key: _softwarePrivateKey);
    if ((existingPublicKey?.isNotEmpty ?? false) &&
        (existingPrivateKey?.isNotEmpty ?? false)) {
      await _store.write(key: _backendKey, value: _softwareBackend);
      return existingPublicKey!;
    }

    final keyPair = await _algorithm.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKeyBase64 = base64.encode(publicKey.bytes);
    final privateKeyBase64 = base64.encode(privateKeyBytes);
    await _store.write(key: _softwarePublicKey, value: publicKeyBase64);
    await _store.write(key: _softwarePrivateKey, value: privateKeyBase64);
    await _store.write(key: _backendKey, value: _softwareBackend);
    return publicKeyBase64;
  }

  Future<String> _signWithSoftwareKey(String payload) async {
    final publicKeyBase64 = await _store.read(key: _softwarePublicKey);
    final privateKeyBase64 = await _store.read(key: _softwarePrivateKey);
    if (publicKeyBase64 == null ||
        publicKeyBase64.isEmpty ||
        privateKeyBase64 == null ||
        privateKeyBase64.isEmpty) {
      await _ensureSoftwareKeypair();
      return _signWithSoftwareKey(payload);
    }

    final publicKey = SimplePublicKey(
      base64.decode(publicKeyBase64),
      type: KeyPairType.ed25519,
    );
    final keyPair = SimpleKeyPairData(
      base64.decode(privateKeyBase64),
      publicKey: publicKey,
      type: KeyPairType.ed25519,
    );
    final signature = await _algorithm.sign(
      utf8.encode(payload),
      keyPair: keyPair,
    );
    return base64UrlEncode(signature.bytes).replaceAll('=', '');
  }
}

class InMemoryKeystoreSignerStore implements KeystoreSignerStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> delete({required String key}) async {
    _values.remove(key);
  }

  @override
  Future<String?> read({required String key}) async {
    return _values[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }
}

class _FlutterSecureKeystoreSignerStore implements KeystoreSignerStore {
  _FlutterSecureKeystoreSignerStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete({required String key}) {
    return _storage.delete(key: key);
  }

  @override
  Future<String?> read({required String key}) {
    return _storage.read(key: key);
  }

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }
}
