# OpenClaw Device Pairing Security Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace shared gateway-token auth with device pairing + per-device tokens, backed by Android Keystore Ed25519 keys and bootstrap token import (manual + QR).

**Architecture:** Flutter owns device identity (id + publicKey) and bootstrap/device token state; Android Keystore signs connect payloads via a method channel. Connect flow prefers deviceToken, falls back to unexpired bootstrapToken.

**Tech Stack:** Flutter, Kotlin (Android Keystore), MethodChannel, flutter_secure_storage, shared_preferences, mobile_scanner.

---

## Scope Note (No Tests)
Per user request, **no tests will be added** in this project. Steps below omit test creation and execution.

---

## File Map (Create / Modify)

**Create**
- `lib/src/domain/models/bootstrap_token_state.dart`
- `lib/src/infrastructure/crypto/keystore_signer.dart`
- `lib/src/infrastructure/util/bootstrap_payload_parser.dart`
- `lib/src/application/use_cases/import_bootstrap_token_use_case.dart`
- `lib/src/presentation/screens/bootstrap_scan_screen.dart`
- `lib/src/presentation/widgets/bootstrap_import_sheet.dart`
- `android/app/src/main/kotlin/com/cw/claw/flutter_openclaw/KeystoreSigner.kt`

**Modify**
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/cw/claw/flutter_openclaw/MainActivity.kt`
- `pubspec.yaml`
- `lib/src/infrastructure/config/dev_defaults.dart`
- `lib/src/domain/models/device_identity.dart`
- `lib/src/domain/models/gateway_config.dart`
- `lib/src/domain/repositories/auth_repository.dart`
- `lib/src/infrastructure/storage/secure_auth_repository.dart`
- `lib/src/infrastructure/storage/shared_prefs_config_repository.dart`
- `lib/src/infrastructure/crypto/device_identity_service.dart`
- `lib/src/infrastructure/crypto/connect_signer.dart`
- `lib/src/application/use_cases/bootstrap_app_use_case.dart`
- `lib/src/application/use_cases/test_connection_use_case.dart`
- `lib/src/application/use_cases/reset_device_identity_use_case.dart`
- `lib/src/application/controllers/settings_controller.dart`
- `lib/src/app/app_dependencies.dart`
- `lib/src/presentation/screens/settings_screen.dart`
- `lib/src/presentation/localization/localized_gateway_text.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_zh.arb`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_en.dart`
- `lib/l10n/app_localizations_zh.dart`

---

### Task 1: Raise Android minSdk to 28 and add camera permission

**Files:**
- Modify: `android/app/build.gradle.kts`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Set minSdk to 28**

```kotlin
// android/app/build.gradle.kts
android {
    // ...
    defaultConfig {
        applicationId = "com.cw.claw.flutter_openclaw"
        minSdk = 28
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
}
```

- [ ] **Step 2: Add camera permission for QR scanning**

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest ...>
    <uses-permission android:name="android.permission.CAMERA" />
    <application ...>
        ...
    </application>
</manifest>
```

- [ ] **Step 3: Commit**

```bash
git add android/app/build.gradle.kts android/app/src/main/AndroidManifest.xml
git commit -m "chore: raise minSdk to 28 and add camera permission"
```

---

### Task 2: Lock scopes and remove shared auth defaults

**Files:**
- Modify: `lib/src/infrastructure/config/dev_defaults.dart`

- [ ] **Step 1: Restrict default operator scopes**

```dart
// lib/src/infrastructure/config/dev_defaults.dart
const List<String> defaultOperatorScopes = <String>[
  'operator.read',
  'operator.write',
];

const GatewayConfig defaultGatewayConfig = GatewayConfig(
  gatewayUrl: 'wss://thisdcw.cn/claw',
  sessionId: '',
  timeoutMs: 60000,
  locale: 'zh-CN',
);
```

- [ ] **Step 2: Commit**

```bash
git add lib/src/infrastructure/config/dev_defaults.dart
git commit -m "chore: restrict default operator scopes"
```

---

### Task 3: Remove authToken from GatewayConfig

**Files:**
- Modify: `lib/src/domain/models/gateway_config.dart`
- Modify: `lib/src/infrastructure/storage/shared_prefs_config_repository.dart`
- Modify: `lib/src/application/controllers/settings_controller.dart`
- Modify: `lib/src/application/use_cases/bootstrap_app_use_case.dart`
- Modify: `lib/src/application/use_cases/test_connection_use_case.dart`
- Modify: `lib/src/app/app_dependencies.dart`

- [ ] **Step 1: Remove authToken from model**

```dart
// lib/src/domain/models/gateway_config.dart
class GatewayConfig {
  final String gatewayUrl;
  final String sessionId;
  final int timeoutMs;
  final String locale;

  const GatewayConfig({
    required this.gatewayUrl,
    required this.sessionId,
    required this.timeoutMs,
    required this.locale,
  });

  GatewayConfig copyWith({
    String? gatewayUrl,
    String? sessionId,
    int? timeoutMs,
    String? locale,
  }) {
    return GatewayConfig(
      gatewayUrl: gatewayUrl ?? this.gatewayUrl,
      sessionId: sessionId ?? this.sessionId,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      locale: locale ?? this.locale,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gatewayUrl': gatewayUrl,
      'sessionId': sessionId,
      'timeoutMs': timeoutMs,
      'locale': locale,
    };
  }

  factory GatewayConfig.fromJson(Map<String, dynamic> json) {
    return GatewayConfig(
      gatewayUrl: _string(json, 'gatewayUrl'),
      sessionId: _string(json, 'sessionId'),
      timeoutMs: _int(json, 'timeoutMs'),
      locale: _string(json, 'locale'),
    );
  }
  // ... rest unchanged
}
```

- [ ] **Step 2: Ignore legacy authToken in stored config**

```dart
// lib/src/infrastructure/storage/shared_prefs_config_repository.dart
final map = jsonDecode(jsonString) as Map<String, dynamic>;
map.remove('authToken');
final config = GatewayConfig.fromJson(map);
```

- [ ] **Step 3: Remove authToken logging/usage**

```dart
// lib/src/application/controllers/settings_controller.dart (remove authToken fields)
// lib/src/application/use_cases/bootstrap_app_use_case.dart (remove authToken handling)
// lib/src/application/use_cases/test_connection_use_case.dart (remove authToken handling)
```

- [ ] **Step 4: Commit**

```bash
git add \
  lib/src/domain/models/gateway_config.dart \
  lib/src/infrastructure/storage/shared_prefs_config_repository.dart \
  lib/src/application/controllers/settings_controller.dart \
  lib/src/application/use_cases/bootstrap_app_use_case.dart \
  lib/src/application/use_cases/test_connection_use_case.dart \
  lib/src/app/app_dependencies.dart

git commit -m "refactor: remove shared auth token from gateway config"
```

---

### Task 4: Add bootstrap token state + parser

**Files:**
- Create: `lib/src/domain/models/bootstrap_token_state.dart`
- Create: `lib/src/infrastructure/util/bootstrap_payload_parser.dart`
- Modify: `lib/src/domain/repositories/auth_repository.dart`
- Modify: `lib/src/infrastructure/storage/secure_auth_repository.dart`
- Modify: `lib/src/application/use_cases/bootstrap_app_use_case.dart`
- Create: `lib/src/application/use_cases/import_bootstrap_token_use_case.dart`

- [ ] **Step 1: Add bootstrap token model**

```dart
// lib/src/domain/models/bootstrap_token_state.dart
class BootstrapTokenState {
  final String token;
  final String gatewayUrl;
  final int importedAt;
  final int expiresAt;

  const BootstrapTokenState({
    required this.token,
    required this.gatewayUrl,
    required this.importedAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;

  Map<String, dynamic> toJson() => {
        'token': token,
        'gatewayUrl': gatewayUrl,
        'importedAt': importedAt,
        'expiresAt': expiresAt,
      };

  factory BootstrapTokenState.fromJson(Map<String, dynamic> json) {
    return BootstrapTokenState(
      token: _string(json, 'token'),
      gatewayUrl: _string(json, 'gatewayUrl'),
      importedAt: _int(json, 'importedAt'),
      expiresAt: _int(json, 'expiresAt'),
    );
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('BootstrapTokenState: "$key" must be a string.');
  }

  static int _int(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FormatException('BootstrapTokenState: "$key" must be an int.');
  }
}
```

- [ ] **Step 2: Add payload parser (base64 JSON)**

```dart
// lib/src/infrastructure/util/bootstrap_payload_parser.dart
import 'dart:convert';

class BootstrapPayload {
  final String gatewayUrl;
  final String bootstrapToken;

  const BootstrapPayload({
    required this.gatewayUrl,
    required this.bootstrapToken,
  });
}

class BootstrapPayloadParser {
  BootstrapPayload parse(String input) {
    final trimmed = input.trim();
    try {
      final decoded = utf8.decode(base64.decode(trimmed));
      final json = jsonDecode(decoded);
      if (json is! Map) {
        throw const FormatException('payload must be an object');
      }
      final map = Map<String, dynamic>.from(json);
      final url = map['url'];
      final token = map['bootstrapToken'];
      if (url is! String || token is! String) {
        throw const FormatException('missing url or bootstrapToken');
      }
      return BootstrapPayload(gatewayUrl: url, bootstrapToken: token);
    } catch (_) {
      // treat as raw token without URL
      return BootstrapPayload(gatewayUrl: '', bootstrapToken: trimmed);
    }
  }
}
```

- [ ] **Step 3: Extend AuthRepository**

```dart
// lib/src/domain/repositories/auth_repository.dart
import '../models/bootstrap_token_state.dart';

abstract class AuthRepository {
  // ... existing
  Future<BootstrapTokenState?> loadBootstrapToken();
  Future<void> saveBootstrapToken(BootstrapTokenState state);
  Future<void> clearBootstrapToken();
}
```

- [ ] **Step 4: Implement bootstrap storage**

```dart
// lib/src/infrastructure/storage/secure_auth_repository.dart
static const String _bootstrapTokenKey = 'openclaw.bootstrap_token';

@override
Future<BootstrapTokenState?> loadBootstrapToken() async {
  final payload = await _storage.read(key: _bootstrapTokenKey);
  if (payload == null || payload.trim().isEmpty) {
    openClawLog('SecureAuthRepository', 'load bootstrap token: empty');
    return null;
  }
  final decoded = _decodeStoredJsonObject(payload, valueName: 'bootstrap token');
  return BootstrapTokenState.fromJson(decoded);
}

@override
Future<void> saveBootstrapToken(BootstrapTokenState state) {
  return _storage.write(
    key: _bootstrapTokenKey,
    value: jsonEncode(state.toJson()),
  );
}

@override
Future<void> clearBootstrapToken() {
  return _storage.delete(key: _bootstrapTokenKey);
}
```

- [ ] **Step 5: Add import use case**

```dart
// lib/src/application/use_cases/import_bootstrap_token_use_case.dart
import '../../domain/models/bootstrap_token_state.dart';
import '../../domain/models/gateway_config.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/config_repository.dart';
import '../../infrastructure/util/bootstrap_payload_parser.dart';

class ImportBootstrapTokenUseCase {
  ImportBootstrapTokenUseCase(
    this._authRepository,
    this._configRepository,
    this._parser,
  );

  final AuthRepository _authRepository;
  final ConfigRepository _configRepository;
  final BootstrapPayloadParser _parser;

  Future<BootstrapTokenState> call(String input, {int ttlMinutes = 10}) async {
    final payload = _parser.parse(input);
    final now = DateTime.now().millisecondsSinceEpoch;
    final state = BootstrapTokenState(
      token: payload.bootstrapToken,
      gatewayUrl: payload.gatewayUrl,
      importedAt: now,
      expiresAt: now + ttlMinutes * 60 * 1000,
    );
    await _authRepository.saveBootstrapToken(state);
    if (payload.gatewayUrl.isNotEmpty) {
      final config = await _configRepository.load();
      final next = config.copyWith(gatewayUrl: payload.gatewayUrl);
      await _configRepository.save(next);
    }
    return state;
  }
}
```

- [ ] **Step 6: Expire bootstrap token on app bootstrap**

```dart
// lib/src/application/use_cases/bootstrap_app_use_case.dart
final bootstrapToken = await _authRepository.loadBootstrapToken();
if (bootstrapToken != null && bootstrapToken.isExpired) {
  await _authRepository.clearBootstrapToken();
}
```

- [ ] **Step 7: Commit**

```bash
git add \
  lib/src/domain/models/bootstrap_token_state.dart \
  lib/src/infrastructure/util/bootstrap_payload_parser.dart \
  lib/src/domain/repositories/auth_repository.dart \
  lib/src/infrastructure/storage/secure_auth_repository.dart \
  lib/src/application/use_cases/import_bootstrap_token_use_case.dart \
  lib/src/application/use_cases/bootstrap_app_use_case.dart

git commit -m "feat: add bootstrap token state and import flow"
```

---

### Task 5: Android Keystore signer + method channel

**Files:**
- Create: `android/app/src/main/kotlin/com/cw/claw/flutter_openclaw/KeystoreSigner.kt`
- Modify: `android/app/src/main/kotlin/com/cw/claw/flutter_openclaw/MainActivity.kt`

- [ ] **Step 1: Add Keystore signer helper**

```kotlin
// android/app/src/main/kotlin/com/cw/claw/flutter_openclaw/KeystoreSigner.kt
package com.cw.claw.flutter_openclaw

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature

class KeystoreSigner(private val alias: String) {
    private val keystore: KeyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }

    fun ensureKeypair(): ByteArray {
        if (!keystore.containsAlias(alias)) {
            val generator = KeyPairGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_ED25519,
                ANDROID_KEYSTORE,
            )
            val spec = KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY,
            ).setDigests(KeyProperties.DIGEST_NONE).build()
            generator.initialize(spec)
            generator.generateKeyPair()
        }
        val entry = keystore.getEntry(alias, null) as KeyStore.PrivateKeyEntry
        val encoded = entry.certificate.publicKey.encoded
        return extractRawPublicKey(encoded)
    }

    fun sign(payload: ByteArray): ByteArray {
        val entry = keystore.getEntry(alias, null) as KeyStore.PrivateKeyEntry
        val signature = Signature.getInstance("Ed25519")
        signature.initSign(entry.privateKey)
        signature.update(payload)
        return signature.sign()
    }

    fun clear() {
        if (keystore.containsAlias(alias)) {
            keystore.deleteEntry(alias)
        }
    }

    private fun extractRawPublicKey(encoded: ByteArray): ByteArray {
        val marker = byteArrayOf(0x03, 0x21, 0x00)
        var index = -1
        for (i in 0 until encoded.size - marker.size) {
            if (encoded[i] == marker[0] && encoded[i + 1] == marker[1] && encoded[i + 2] == marker[2]) {
                index = i + 3
                break
            }
        }
        if (index < 0 || index + 32 > encoded.size) {
            throw IllegalStateException("Unsupported Ed25519 public key format")
        }
        return encoded.copyOfRange(index, index + 32)
    }

    companion object {
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"

        fun base64(bytes: ByteArray): String = Base64.encodeToString(bytes, Base64.NO_WRAP)

        fun base64Url(bytes: ByteArray): String = Base64.encodeToString(
            bytes,
            Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING,
        )
    }
}
```

- [ ] **Step 2: Wire MethodChannel in MainActivity**

```kotlin
// android/app/src/main/kotlin/com/cw/claw/flutter_openclaw/MainActivity.kt
companion object {
    private const val CHANNEL_NAME = "openclaw/media"
    private const val KEYSTORE_CHANNEL = "openclaw/keystore"
    private const val KEY_ALIAS = "openclaw.device.signing"
    private const val REQUEST_WRITE_STORAGE = 2407
}

override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    val keystoreSigner = KeystoreSigner(KEY_ALIAS)

    MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        CHANNEL_NAME,
    ).setMethodCallHandler { call, result ->
        when (call.method) {
            "saveImage" -> saveImage(call, result)
            else -> result.notImplemented()
        }
    }

    MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        KEYSTORE_CHANNEL,
    ).setMethodCallHandler { call, result ->
        when (call.method) {
            "ensureKeypair" -> {
                val publicKey = keystoreSigner.ensureKeypair()
                result.success(KeystoreSigner.base64(publicKey))
            }
            "signPayload" -> {
                val payload = call.argument<String>("payload") ?: ""
                val signature = keystoreSigner.sign(payload.toByteArray(Charsets.UTF_8))
                result.success(KeystoreSigner.base64Url(signature))
            }
            "clearKeypair" -> {
                keystoreSigner.clear()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add \
  android/app/src/main/kotlin/com/cw/claw/flutter_openclaw/KeystoreSigner.kt \
  android/app/src/main/kotlin/com/cw/claw/flutter_openclaw/MainActivity.kt

git commit -m "feat: add Android Keystore signer channel"
```

---

### Task 6: Flutter Keystore bridge + DeviceIdentity changes

**Files:**
- Create: `lib/src/infrastructure/crypto/keystore_signer.dart`
- Modify: `lib/src/domain/models/device_identity.dart`
- Modify: `lib/src/infrastructure/crypto/device_identity_service.dart`

- [ ] **Step 1: Add Keystore bridge**

```dart
// lib/src/infrastructure/crypto/keystore_signer.dart
import 'package:flutter/services.dart';

class KeystoreSigner {
  static const MethodChannel _channel = MethodChannel('openclaw/keystore');

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
```

- [ ] **Step 2: Remove privateKeyPem from DeviceIdentity**

```dart
// lib/src/domain/models/device_identity.dart
class DeviceIdentity {
  final String id;
  final String publicKey;

  const DeviceIdentity({
    required this.id,
    required this.publicKey,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'publicKey': publicKey,
      };

  factory DeviceIdentity.fromJson(Map<String, dynamic> json) {
    return DeviceIdentity(
      id: _string(json, 'id'),
      publicKey: _string(json, 'publicKey'),
    );
  }

  @override
  String toString() => 'DeviceIdentity(id: $id, publicKey: $publicKey)';

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('DeviceIdentity: "$key" must be a string.');
  }
}
```

- [ ] **Step 3: Update DeviceIdentityService to use Keystore**

```dart
// lib/src/infrastructure/crypto/device_identity_service.dart
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
    return DeviceIdentity(id: id, publicKey: publicKeyBase64);
  }

  Future<String> _deriveId(List<int> publicBytes) async {
    final digest = await _hasher.hash(publicBytes);
    return digest.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add \
  lib/src/infrastructure/crypto/keystore_signer.dart \
  lib/src/domain/models/device_identity.dart \
  lib/src/infrastructure/crypto/device_identity_service.dart

git commit -m "feat: move device identity to Android Keystore"
```

---

### Task 7: Update ConnectSigner to use Keystore signing

**Files:**
- Modify: `lib/src/infrastructure/crypto/connect_signer.dart`

- [ ] **Step 1: Replace local signing with Keystore**

```dart
// lib/src/infrastructure/crypto/connect_signer.dart
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
    required String locale,
    required List<String> scopes,
    int? signedAt,
    String? userAgent,
  }) async {
    final effectiveSignedAt = signedAt ?? DateTime.now().millisecondsSinceEpoch;
    final auth = _buildAuth(authToken: authToken, deviceToken: deviceToken);
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

  ConnectAuth _buildAuth({required String authToken, required String deviceToken}) {
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
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/src/infrastructure/crypto/connect_signer.dart
git commit -m "refactor: sign connect payload via Keystore"
```

---

### Task 8: Auth selection and connect flow update

**Files:**
- Modify: `lib/src/application/use_cases/test_connection_use_case.dart`

- [ ] **Step 1: Resolve auth from deviceToken or bootstrapToken**

```dart
// lib/src/application/use_cases/test_connection_use_case.dart
final operatorAuth = await _authRepository.loadOperatorAuth();
final bootstrapToken = await _authRepository.loadBootstrapToken();
final hasDeviceToken = (operatorAuth?.deviceToken ?? '').isNotEmpty;
final usableBootstrap = bootstrapToken != null && !bootstrapToken.isExpired;

if (!hasDeviceToken && !usableBootstrap) {
  throw StateError('Bootstrap token missing or expired. Please import again.');
}

final authToken = usableBootstrap ? bootstrapToken!.token : '';
```

- [ ] **Step 2: Pass approved scopes when available**

```dart
final scopes = (operatorAuth?.scopes ?? const <String>[]);
final connectParams = await _signer.buildConnectParams(
  challenge: challengeModel,
  identity: deviceIdentity,
  authToken: authToken,
  deviceToken: operatorAuth?.deviceToken ?? '',
  locale: config.locale,
  scopes: scopes,
);
```

- [ ] **Step 3: Clear expired bootstrap token after successful pairing**

```dart
if (bootstrapToken != null && bootstrapToken.isExpired) {
  await _authRepository.clearBootstrapToken();
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/src/application/use_cases/test_connection_use_case.dart
git commit -m "feat: use bootstrap token when device token missing"
```

---

### Task 9: Clear Keystore key on device reset

**Files:**
- Modify: `lib/src/application/use_cases/reset_device_identity_use_case.dart`
- Modify: `lib/src/app/app_dependencies.dart`

- [ ] **Step 1: Call Keystore clear on reset**

```dart
// lib/src/application/use_cases/reset_device_identity_use_case.dart
import '../../infrastructure/crypto/keystore_signer.dart';

class ResetDeviceIdentityUseCase {
  ResetDeviceIdentityUseCase(this._authRepository, {KeystoreSigner? keystore})
      : _keystore = keystore ?? KeystoreSigner();

  final AuthRepository _authRepository;
  final KeystoreSigner _keystore;

  Future<void> call() async {
    await _keystore.clearKeypair();
    await _authRepository.clearDeviceIdentity();
  }
}
```

- [ ] **Step 2: Wire dependency**

```dart
// lib/src/app/app_dependencies.dart
final resetDeviceIdentityUseCase = ResetDeviceIdentityUseCase(authRepository);
```

- [ ] **Step 3: Commit**

```bash
git add \
  lib/src/application/use_cases/reset_device_identity_use_case.dart \
  lib/src/app/app_dependencies.dart

git commit -m "feat: clear Keystore key on identity reset"
```

---

### Task 10: Add QR scanner + manual import UI

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/src/presentation/screens/bootstrap_scan_screen.dart`
- Create: `lib/src/presentation/widgets/bootstrap_import_sheet.dart`
- Modify: `lib/src/application/controllers/settings_controller.dart`
- Modify: `lib/src/app/app_dependencies.dart`
- Modify: `lib/src/presentation/screens/settings_screen.dart`

- [ ] **Step 1: Add QR scanner dependency**

```yaml
# pubspec.yaml
dependencies:
  mobile_scanner: ^5.2.0
```

- [ ] **Step 2: Create import sheet (manual input)**

```dart
// lib/src/presentation/widgets/bootstrap_import_sheet.dart
import 'package:flutter/material.dart';

class BootstrapImportSheet extends StatefulWidget {
  const BootstrapImportSheet({super.key, required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<BootstrapImportSheet> createState() => _BootstrapImportSheetState();
}

class _BootstrapImportSheetState extends State<BootstrapImportSheet> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('导入配对码', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '粘贴扫码内容或 bootstrap token',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onSubmit(controller.text),
              child: const Text('导入'),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Create QR scan screen**

```dart
// lib/src/presentation/screens/bootstrap_scan_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BootstrapScanScreen extends StatelessWidget {
  const BootstrapScanScreen({super.key, required this.onScanned});

  final ValueChanged<String> onScanned;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('扫描配对二维码')),
      body: MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.firstOrNull;
          final rawValue = barcode?.rawValue;
          if (rawValue != null && rawValue.trim().isNotEmpty) {
            onScanned(rawValue);
            Navigator.of(context).maybePop();
          }
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Wire import use case in SettingsController**

```dart
// lib/src/application/controllers/settings_controller.dart
import '../use_cases/import_bootstrap_token_use_case.dart';

final ImportBootstrapTokenUseCase? _importBootstrapTokenUseCase;

Future<void> importBootstrapToken(String input) async {
  await _importBootstrapTokenUseCase?.call(input);
  notifyListeners();
}
```

- [ ] **Step 5: Register dependency**

```dart
// lib/src/app/app_dependencies.dart
import 'package:flutter_openclaw/src/infrastructure/util/bootstrap_payload_parser.dart';
import 'package:flutter_openclaw/src/application/use_cases/import_bootstrap_token_use_case.dart';

final importBootstrapTokenUseCase = ImportBootstrapTokenUseCase(
  authRepository,
  configRepository,
  BootstrapPayloadParser(),
);

final settingsController = SettingsController(
  // ...
  clearOperatorAuthUseCase: clearOperatorAuthUseCase,
  resetDeviceIdentityUseCase: resetDeviceIdentityUseCase,
  importBootstrapTokenUseCase: importBootstrapTokenUseCase,
);
```

- [ ] **Step 6: Add pairing UI in SettingsScreen**

```dart
// lib/src/presentation/screens/settings_screen.dart
// Add a new Card with buttons to import/scan
Card(
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('配对管理', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => BootstrapImportSheet(
                      onSubmit: (value) async {
                        Navigator.of(context).pop();
                        await widget.settingsController.importBootstrapToken(value);
                      },
                    ),
                  );
                },
                child: const Text('手动导入'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BootstrapScanScreen(
                        onScanned: (value) async {
                          await widget.settingsController.importBootstrapToken(value);
                        },
                      ),
                    ),
                  );
                },
                child: const Text('扫码导入'),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
),
```

- [ ] **Step 7: Commit**

```bash
git add \
  pubspec.yaml \
  lib/src/presentation/screens/bootstrap_scan_screen.dart \
  lib/src/presentation/widgets/bootstrap_import_sheet.dart \
  lib/src/application/controllers/settings_controller.dart \
  lib/src/app/app_dependencies.dart \
  lib/src/presentation/screens/settings_screen.dart

git commit -m "feat: add bootstrap token import UI"
```

---

### Task 11: Localization updates

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_zh.arb`
- Modify: `lib/l10n/app_localizations.dart`
- Modify: `lib/l10n/app_localizations_en.dart`
- Modify: `lib/l10n/app_localizations_zh.dart`

- [ ] **Step 1: Add strings to ARB files**

```json
// lib/l10n/app_zh.arb
"pairingTitle": "配对管理",
"pairingImportManual": "手动导入",
"pairingImportScan": "扫码导入",
"pairingExpired": "配对码已过期，请重新导入",
"pairingMissing": "请先导入配对码"
```

```json
// lib/l10n/app_en.arb
"pairingTitle": "Pairing",
"pairingImportManual": "Manual Import",
"pairingImportScan": "Scan QR",
"pairingExpired": "Pairing code expired. Please import again.",
"pairingMissing": "Please import a pairing code first."
```

- [ ] **Step 2: Update generated localization dart files**

```dart
// lib/l10n/app_localizations.dart
String get pairingTitle;
String get pairingImportManual;
String get pairingImportScan;
String get pairingExpired;
String get pairingMissing;
```

```dart
// lib/l10n/app_localizations_zh.dart
@override
String get pairingTitle => '配对管理';
@override
String get pairingImportManual => '手动导入';
@override
String get pairingImportScan => '扫码导入';
@override
String get pairingExpired => '配对码已过期，请重新导入';
@override
String get pairingMissing => '请先导入配对码';
```

```dart
// lib/l10n/app_localizations_en.dart
@override
String get pairingTitle => 'Pairing';
@override
String get pairingImportManual => 'Manual Import';
@override
String get pairingImportScan => 'Scan QR';
@override
String get pairingExpired => 'Pairing code expired. Please import again.';
@override
String get pairingMissing => 'Please import a pairing code first.';
```

- [ ] **Step 3: Commit**

```bash
git add \
  lib/l10n/app_en.arb \
  lib/l10n/app_zh.arb \
  lib/l10n/app_localizations.dart \
  lib/l10n/app_localizations_en.dart \
  lib/l10n/app_localizations_zh.dart

git commit -m "chore: add pairing localization strings"
```

---

## Self-Review Checklist
- [x] Spec coverage: Keystore signing, bootstrap token import, expiry logic, scopes restriction, UI actions covered.
- [x] Placeholder scan: No TODO/TBD text in steps.
- [x] Type consistency: Models and method names aligned across tasks.

---

**Plan complete and saved to `docs/superpowers/plans/2026-04-13-openclaw-device-pairing-security-plan.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
