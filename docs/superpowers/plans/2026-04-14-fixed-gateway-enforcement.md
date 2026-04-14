# Fixed Gateway Enforcement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enforce `wss://thisdcw.cn/claw` as the immutable gateway URL across bootstrap import, config storage, UI state, and connection logic.

**Architecture:** Lock the gateway at the config layer (load/save normalization), ignore any gateway embedded in bootstrap payloads, and add a connection-layer override to guarantee the WebSocket always targets the fixed URL even if a config object is malformed.

**Tech Stack:** Flutter/Dart, shared_preferences, flutter_secure_storage, web_socket_channel, flutter_test

---

## File Structure (Planned Changes)

- Modify: `lib/src/infrastructure/util/bootstrap_payload_parser.dart`
- Modify: `lib/src/application/use_cases/import_bootstrap_token_use_case.dart`
- Modify: `lib/src/infrastructure/storage/shared_prefs_config_repository.dart`
- Modify: `lib/src/application/controllers/settings_controller.dart`
- Modify: `lib/src/application/use_cases/test_connection_use_case.dart`
- Create: `test/infrastructure/util/bootstrap_payload_parser_test.dart`
- Create: `test/infrastructure/storage/shared_prefs_config_repository_test.dart`
- Create: `test/application/use_cases/test_connection_use_case_test.dart`

---

### Task 1: Make Bootstrap Payload Ignore Gateway URL

**Files:**
- Modify: `lib/src/infrastructure/util/bootstrap_payload_parser.dart`
- Modify: `lib/src/application/use_cases/import_bootstrap_token_use_case.dart`
- Test: `test/infrastructure/util/bootstrap_payload_parser_test.dart`

- [ ] **Step 1: Write failing test for bootstrap payload parsing**

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_openclaw/src/infrastructure/util/bootstrap_payload_parser.dart';

void main() {
  test('parses bootstrapToken and ignores gatewayUrl', () {
    final payload = {
      'gatewayUrl': 'wss://evil.example/ws',
      'bootstrapToken': 'boot-123',
    };
    final encoded = base64.encode(utf8.encode(jsonEncode(payload)));

    final parser = BootstrapPayloadParser();
    final result = parser.parse(encoded);

    expect(result.bootstrapToken, 'boot-123');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/util/bootstrap_payload_parser_test.dart`
Expected: FAIL (type errors or missing property once parser is updated in the next step)

- [ ] **Step 3: Update bootstrap payload parser to only care about token**

```dart
import 'dart:convert';

import 'openclaw_logger.dart';

class BootstrapPayload {
  final String bootstrapToken;

  const BootstrapPayload({
    required this.bootstrapToken,
  });
}

class BootstrapPayloadParser {
  BootstrapPayload parse(String input) {
    final trimmed = input.trim();
    try {
      final decoded = utf8.decode(base64.decode(_normalizeBase64(trimmed)));
      final json = jsonDecode(decoded);
      if (json is! Map) {
        throw const FormatException('payload must be an object');
      }
      final map = Map<String, dynamic>.from(json);
      final token = map['bootstrapToken'];
      if (token is! String || token.trim().isEmpty) {
        throw const FormatException('missing bootstrapToken');
      }
      return BootstrapPayload(
        bootstrapToken: token.trim(),
      );
    } catch (error) {
      openClawLog(
        'BootstrapPayloadParser',
        'fallback to raw bootstrap token after parse failure',
        fields: <String, Object?>{
          'error': error.toString(),
          'preview': '<redacted>',
        },
      );
      return BootstrapPayload(bootstrapToken: trimmed);
    }
  }

  String _normalizeBase64(String input) {
    final normalizedAlphabet =
        input.replaceAll('-', '+').replaceAll('_', '/');
    return base64.normalize(normalizedAlphabet);
  }
}
```

- [ ] **Step 4: Update bootstrap import use-case to ignore payload gateway**

```dart
import '../../domain/models/bootstrap_token_state.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/config_repository.dart';
import '../../infrastructure/config/dev_defaults.dart';
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
    final fixedGatewayUrl = defaultGatewayConfig.gatewayUrl;
    final now = DateTime.now().millisecondsSinceEpoch;
    final state = BootstrapTokenState(
      token: payload.bootstrapToken,
      gatewayUrl: fixedGatewayUrl,
      importedAt: now,
      expiresAt: now + ttlMinutes * 60 * 1000,
    );
    await _authRepository.saveBootstrapToken(state);
    final config = await _configRepository.load();
    final next = config.copyWith(gatewayUrl: fixedGatewayUrl);
    await _configRepository.save(next);
    return state;
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/infrastructure/util/bootstrap_payload_parser_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/src/infrastructure/util/bootstrap_payload_parser.dart \
  lib/src/application/use_cases/import_bootstrap_token_use_case.dart \
  test/infrastructure/util/bootstrap_payload_parser_test.dart

git commit -m "Enforce bootstrap token parsing without gateway"
```

---

### Task 2: Lock Gateway URL in Config Storage + Settings State

**Files:**
- Modify: `lib/src/infrastructure/storage/shared_prefs_config_repository.dart`
- Modify: `lib/src/application/controllers/settings_controller.dart`
- Test: `test/infrastructure/storage/shared_prefs_config_repository_test.dart`

- [ ] **Step 1: Write failing tests for config repository enforcement**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_openclaw/src/domain/models/gateway_config.dart';
import 'package:flutter_openclaw/src/infrastructure/config/dev_defaults.dart';
import 'package:flutter_openclaw/src/infrastructure/storage/shared_prefs_config_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('load() normalizes gatewayUrl to fixed value', () async {
    final repo = await SharedPrefsConfigRepository.inMemory();
    await repo.save(const GatewayConfig(
      gatewayUrl: 'wss://evil.example/ws',
      sessionId: 's1',
      timeoutMs: 1,
      locale: 'zh-CN',
    ));

    final config = await repo.load();

    expect(config.gatewayUrl, defaultGatewayConfig.gatewayUrl);
  });

  test('save() persists fixed gateway regardless of input', () async {
    final repo = await SharedPrefsConfigRepository.inMemory();
    await repo.save(const GatewayConfig(
      gatewayUrl: 'wss://evil.example/ws',
      sessionId: 's2',
      timeoutMs: 2,
      locale: 'zh-CN',
    ));

    final config = await repo.load();

    expect(config.gatewayUrl, defaultGatewayConfig.gatewayUrl);
    expect(config.sessionId, 's2');
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/infrastructure/storage/shared_prefs_config_repository_test.dart`
Expected: FAIL (gatewayUrl remains the injected value)

- [ ] **Step 3: Enforce fixed gateway in shared prefs repository**

```dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/gateway_config.dart';
import '../../domain/repositories/config_repository.dart';
import '../config/dev_defaults.dart';
import '../util/openclaw_logger.dart';

class SharedPrefsConfigRepository implements ConfigRepository {
  SharedPrefsConfigRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _storageKey = 'gateway_config';

  static Future<SharedPrefsConfigRepository> inMemory() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return SharedPrefsConfigRepository(prefs);
  }

  @override
  Future<GatewayConfig> load() async {
    final jsonString = _prefs.getString(_storageKey);
    if (jsonString == null || jsonString.isEmpty) {
      openClawLog('ConfigRepository', 'load default config: no persisted value');
      return defaultGatewayConfig;
    }

    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      map.remove('authToken');
      final config = GatewayConfig.fromJson(map);
      final normalized = config.copyWith(
        gatewayUrl: defaultGatewayConfig.gatewayUrl,
      );
      openClawLog(
        'ConfigRepository',
        'load persisted config',
        fields: <String, Object?>{
          'gatewayUrl': normalized.gatewayUrl,
          'sessionId': normalized.sessionId,
          'timeoutMs': normalized.timeoutMs,
          'locale': normalized.locale,
        },
      );
      return normalized;
    } catch (_) {
      openClawLog(
        'ConfigRepository',
        'load config failed, fallback to default',
        fields: <String, Object?>{
          'raw': truncateForLog(jsonString, maxLength: 160),
        },
      );
      return defaultGatewayConfig;
    }
  }

  @override
  Future<void> save(GatewayConfig config) async {
    final normalized = config.copyWith(
      gatewayUrl: defaultGatewayConfig.gatewayUrl,
    );
    final encoded = jsonEncode(normalized.toJson());
    openClawLog(
      'ConfigRepository',
      'save config',
      fields: <String, Object?>{
        'gatewayUrl': normalized.gatewayUrl,
        'sessionId': normalized.sessionId,
        'timeoutMs': normalized.timeoutMs,
        'locale': normalized.locale,
      },
    );
    await _prefs.setString(_storageKey, encoded);
  }
}
```

- [ ] **Step 4: Normalize gateway in SettingsController state**

```dart
import 'package:flutter/foundation.dart';

import '../../domain/models/app_locale_preference.dart';
import '../../domain/models/bootstrap_token_state.dart';
import '../../domain/models/gateway_config.dart';
import '../../domain/models/operator_auth_state.dart';
import '../../domain/repositories/app_locale_preference_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/config_repository.dart';
import '../../infrastructure/config/dev_defaults.dart';
import '../../infrastructure/util/openclaw_logger.dart';
import '../use_cases/clear_operator_auth_use_case.dart';
import '../use_cases/import_bootstrap_token_use_case.dart';
import '../use_cases/reset_device_identity_use_case.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({
    GatewayConfig? initialConfig,
    AppLocalePreference initialLocalePreference =
        AppLocalePreference.system,
    ConfigRepository? configRepository,
    AuthRepository? authRepository,
    AppLocalePreferenceRepository? appLocalePreferenceRepository,
    ClearOperatorAuthUseCase? clearOperatorAuthUseCase,
    ImportBootstrapTokenUseCase? importBootstrapTokenUseCase,
    ResetDeviceIdentityUseCase? resetDeviceIdentityUseCase,
    bool isStub = false,
  })  : _config = _normalizeGateway(initialConfig ?? defaultGatewayConfig),
        _localePreference = initialLocalePreference,
        _configRepository = configRepository,
        _authRepository = authRepository,
        _appLocalePreferenceRepository = appLocalePreferenceRepository,
        _clearOperatorAuthUseCase = clearOperatorAuthUseCase,
        _importBootstrapTokenUseCase = importBootstrapTokenUseCase,
        _resetDeviceIdentityUseCase = resetDeviceIdentityUseCase,
        _isStub = isStub;

  // ... unchanged fields

  void update(GatewayConfig next) {
    final normalized = _normalizeGateway(next);
    openClawLog(
      'SettingsController',
      'update in-memory config',
      fields: <String, Object?>{
        'gatewayUrl': normalized.gatewayUrl,
        'sessionId': normalized.sessionId,
        'timeoutMs': normalized.timeoutMs,
        'locale': normalized.locale,
      },
    );
    _config = normalized;
    notifyListeners();
  }

  Future<void> save(GatewayConfig next) async {
    final normalized = _normalizeGateway(next);
    openClawLog(
      'SettingsController',
      'save config',
      fields: <String, Object?>{
        'gatewayUrl': normalized.gatewayUrl,
        'sessionId': normalized.sessionId,
        'timeoutMs': normalized.timeoutMs,
        'locale': normalized.locale,
      },
    );
    _config = normalized;
    await _configRepository?.save(normalized);
    notifyListeners();
  }

  Future<void> importBootstrapToken(String input) async {
    await _importBootstrapTokenUseCase?.call(input);
    final persistedConfig = await _configRepository?.load();
    if (persistedConfig != null) {
      _config = _normalizeGateway(persistedConfig);
    }
    await refreshSecuritySnapshot(notify: false);
    notifyListeners();
  }

  static GatewayConfig _normalizeGateway(GatewayConfig config) {
    if (config.gatewayUrl == defaultGatewayConfig.gatewayUrl) {
      return config;
    }
    return config.copyWith(gatewayUrl: defaultGatewayConfig.gatewayUrl);
  }

  // ... rest unchanged
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/infrastructure/storage/shared_prefs_config_repository_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/src/infrastructure/storage/shared_prefs_config_repository.dart \
  lib/src/application/controllers/settings_controller.dart \
  test/infrastructure/storage/shared_prefs_config_repository_test.dart

git commit -m "Lock gateway URL in config storage and settings"
```

---

### Task 3: Enforce Fixed Gateway in Connection Flow

**Files:**
- Modify: `lib/src/application/use_cases/test_connection_use_case.dart`
- Test: `test/application/use_cases/test_connection_use_case_test.dart`

- [ ] **Step 1: Write failing test to assert fixed gateway is used**

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_openclaw/src/application/use_cases/test_connection_use_case.dart';
import 'package:flutter_openclaw/src/domain/models/gateway_config.dart';
import 'package:flutter_openclaw/src/infrastructure/config/dev_defaults.dart';
import 'package:flutter_openclaw/src/infrastructure/crypto/connect_signer.dart';
import 'package:flutter_openclaw/src/infrastructure/crypto/device_identity_service.dart';
import 'package:flutter_openclaw/src/infrastructure/crypto/keystore_signer.dart';
import 'package:flutter_openclaw/src/infrastructure/gateway/gateway_protocol_parser.dart';
import 'package:flutter_openclaw/src/infrastructure/storage/secure_auth_repository.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _FakeWebSocketSink implements WebSocketSink {
  final StreamController<dynamic> _outgoing;

  _FakeWebSocketSink(this._outgoing);

  @override
  void add(dynamic event) => _outgoing.add(event);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _outgoing.addError(error, stackTrace);

  @override
  Future close([int? closeCode, String? closeReason]) async {
    await _outgoing.close();
  }

  @override
  Future get done => _outgoing.done;
}

class _FakeWebSocketChannel implements WebSocketChannel {
  _FakeWebSocketChannel(this.incoming, this.outgoing)
      : _sink = _FakeWebSocketSink(outgoing);

  final StreamController<dynamic> incoming;
  final StreamController<dynamic> outgoing;
  final WebSocketSink _sink;

  @override
  Stream get stream => incoming.stream;

  @override
  WebSocketSink get sink => _sink;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('openclaw/keystore');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'keystore-error', message: 'unavailable');
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('connect() always uses the fixed gateway URL', () async {
    final authRepository = SecureAuthRepository.inMemory();
    await authRepository.saveOperatorAuth(const OperatorAuthState(
      role: 'operator',
      deviceToken: 'device-token',
      scopes: <String>['operator.read'],
    ));

    final keystore = KeystoreSigner(
      channel: channel,
      store: InMemoryKeystoreSignerStore(),
    );
    final identityService = DeviceIdentityService(keystoreSigner: keystore);
    final signer = ConnectSigner(keystoreSigner: keystore);

    Uri? capturedUri;
    final incoming = StreamController<dynamic>();
    final outgoing = StreamController<dynamic>();

    final useCase = TestConnectionUseCase(
      authRepository: authRepository,
      identityService: identityService,
      signer: signer,
      parser: const GatewayProtocolParser(),
      channelFactory: (uri) {
        capturedUri = uri;

        Future.microtask(() {
          incoming.add(jsonEncode({
            'type': 'event',
            'event': 'connect.challenge',
            'payload': {'nonce': 'nonce-1'},
          }));

          Future.microtask(() {
            incoming.add(jsonEncode({
              'type': 'res',
              'ok': true,
              'payload': {
                'type': 'hello-ok',
                'auth': {
                  'role': 'operator',
                  'deviceToken': 'device-token',
                  'scopes': ['operator.read'],
                },
              },
            }));
          });
        });

        return _FakeWebSocketChannel(incoming, outgoing);
      },
    );

    await useCase.connect(
      config: const GatewayConfig(
        gatewayUrl: 'wss://evil.example/ws',
        sessionId: '',
        timeoutMs: 2000,
        locale: 'zh-CN',
      ),
    );

    expect(capturedUri.toString(), defaultGatewayConfig.gatewayUrl);

    await incoming.close();
    await outgoing.close();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/application/use_cases/test_connection_use_case_test.dart`
Expected: FAIL (captured URI is the non-fixed input)

- [ ] **Step 3: Override gateway URL in connection use-case**

```dart
import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../domain/models/bootstrap_token_state.dart';
import '../../domain/models/connection_status.dart';
import '../../domain/models/device_identity.dart';
import '../../domain/models/gateway_config.dart';
import '../../domain/models/gateway_failure.dart';
import '../../domain/models/operator_auth_state.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../infrastructure/config/dev_defaults.dart';
import '../../infrastructure/crypto/connect_signer.dart';
import '../../infrastructure/crypto/device_identity_service.dart';
import '../../infrastructure/gateway/gateway_client.dart';
import '../../infrastructure/gateway/gateway_frame.dart';
import '../../infrastructure/gateway/gateway_protocol_parser.dart';
import '../../infrastructure/util/openclaw_logger.dart';

class TestConnectionUseCase {
  // ... existing constructor and fields unchanged

  Future<AuthenticatedGatewaySession> connect({
    required GatewayConfig config,
  }) async {
    final effectiveConfig = config.copyWith(
      gatewayUrl: defaultGatewayConfig.gatewayUrl,
    );
    openClawLog(
      'TestConnection',
      'connect start',
      fields: <String, Object?>{
        'gatewayUrl': effectiveConfig.gatewayUrl,
        'sessionId': effectiveConfig.sessionId,
        'timeoutMs': effectiveConfig.timeoutMs,
        'locale': effectiveConfig.locale,
      },
    );
    // ... use effectiveConfig everywhere below

    final channel = (_channelFactory ?? WebSocketChannel.connect)(
      Uri.parse(effectiveConfig.gatewayUrl),
    );

    // ... timeout references should use effectiveConfig.timeoutMs
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/application/use_cases/test_connection_use_case_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/src/application/use_cases/test_connection_use_case.dart \
  test/application/use_cases/test_connection_use_case_test.dart

git commit -m "Force fixed gateway in connection flow"
```

---

## Plan Self-Review

- **Spec coverage:**
  - Fixed gateway on config load/save: Task 2.
  - Ignore gateway in bootstrap payload: Task 1.
  - Connection always uses fixed gateway: Task 3.
  - UI consistency via settings normalization: Task 2.
- **Placeholder scan:** No TODO/TBD placeholders present.
- **Type consistency:** Added types match existing models and usage patterns.

---

Plan complete and saved to `docs/superpowers/plans/2026-04-14-fixed-gateway-enforcement.md`. Two execution options:

1. Subagent-Driven (recommended) - I dispatch a fresh subagent per task, review between tasks, fast iteration
2. Inline Execution - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
