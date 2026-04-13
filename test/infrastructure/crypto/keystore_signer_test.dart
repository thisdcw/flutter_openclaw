import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_openclaw/src/infrastructure/crypto/keystore_signer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('openclaw/keystore');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
        code: 'keystore-error',
        message: 'Ed25519 is not available in AndroidKeyStore on this device.',
      );
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'falls back to software Ed25519 when native keystore is unavailable',
    () async {
      final store = InMemoryKeystoreSignerStore();
      final signer = KeystoreSigner(channel: channel, store: store);

      final publicKey = await signer.ensureKeypair();
      final repeatedPublicKey = await signer.ensureKeypair();
      final signatureBase64Url = await signer.signPayload('hello-openclaw');

      expect(publicKey, isNotEmpty);
      expect(repeatedPublicKey, publicKey);

      final algorithm = Ed25519();
      final verified = await algorithm.verify(
        utf8.encode('hello-openclaw'),
        signature: Signature(
          base64Url.decode(base64Url.normalize(signatureBase64Url)),
          publicKey: SimplePublicKey(
            base64.decode(publicKey),
            type: KeyPairType.ed25519,
          ),
        ),
      );

      expect(verified, isTrue);
    },
  );
}
