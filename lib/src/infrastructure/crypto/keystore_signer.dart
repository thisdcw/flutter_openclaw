import 'package:flutter/services.dart';

class KeystoreSigner {
  static const MethodChannel _channel = MethodChannel('openclaw/keystore');

  const KeystoreSigner();

  Future<String> ensureKeypair() async {
    final publicKey = await _channel.invokeMethod<String>('ensureKeypair');
    if (publicKey == null || publicKey.isEmpty) {
      throw StateError('KeystoreSigner: missing public key');
    }
    return publicKey;
  }

  Future<String> signPayload(String payload) async {
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
    await _channel.invokeMethod('clearKeypair');
  }
}
