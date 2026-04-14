# Setup Code Gateway URL Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Use setup code `url` as the authoritative gateway URL (no `/claw` appending), reject `/claw` setup codes on import, and ensure `deviceToken` is only persisted from the first successful bootstrap connection.

**Architecture:** Parse and persist `gatewayUrl` from setup code, enforce `/claw` rejection at import and runtime, and restrict `deviceToken` persistence to bootstrap success. Reconnects use stored `deviceToken` without overwriting.

**Tech Stack:** Flutter/Dart, shared_preferences, flutter_secure_storage, web_socket_channel, flutter_test

---

## File Structure (Planned Changes)
- Modify: `lib/src/infrastructure/util/bootstrap_payload_parser.dart`
- Modify: `lib/src/application/use_cases/import_bootstrap_token_use_case.dart`
- Modify: `lib/src/infrastructure/storage/shared_prefs_config_repository.dart`
- Modify: `lib/src/application/controllers/settings_controller.dart`
- Modify: `lib/src/infrastructure/config/dev_defaults.dart`
- Modify: `lib/src/application/use_cases/test_connection_use_case.dart`
- Modify: `test/infrastructure/util/bootstrap_payload_parser_test.dart`
- Modify: `test/infrastructure/storage/shared_prefs_config_repository_test.dart`
- Modify: `test/application/use_cases/test_connection_use_case_test.dart`
- Create: `test/application/use_cases/import_bootstrap_token_use_case_test.dart`

---

### Task 1: Parse Setup Code URL + Reject `/claw` on Import

**Files:**
- Modify: `lib/src/infrastructure/util/bootstrap_payload_parser.dart`
- Modify: `lib/src/application/use_cases/import_bootstrap_token_use_case.dart`
- Modify: `test/infrastructure/util/bootstrap_payload_parser_test.dart`
- Create: `test/application/use_cases/import_bootstrap_token_use_case_test.dart`

- [ ] **Step 1: Update bootstrap payload parser to return `url` + `bootstrapToken`**

```dart
import 'dart:convert';

import 'openclaw_logger.dart';

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
      final decoded = utf8.decode(base64.decode(_normalizeBase64(trimmed)));
      final json = jsonDecode(decoded);
      if (json is! Map) {
        throw const FormatException('payload must be an object');
      }
      final map = Map<String, dynamic>.from(json);
      final url = map['url'] ?? map['gatewayUrl'];
      final token = map['bootstrapToken'];
      if (url is! String || token is! String) {
        throw const FormatException('missing url or bootstrapToken');
      }
      return BootstrapPayload(
        gatewayUrl: url.trim(),
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
      return BootstrapPayload(gatewayUrl: '', bootstrapToken: trimmed);
    }
  }

  String _normalizeBase64(String input) {
    final normalizedAlphabet =
        input.replaceAll('-', '+').replaceAll('_', '/');
    return base64.normalize(normalizedAlphabet);
  }
}
```

- [ ] **Step 2: Enforce `/claw` rejection on import**

```dart
import '../../domain/models/bootstrap_token_state.dart';
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
    _guardAgainstClawGateway(payload.gatewayUrl);
    final now = DateTime.now().millisecondsSinceEpoch;
    final state = BootstrapTokenState(
      token: payload.bootstrapToken,
      gatewayUrl: payload.gatewayUrl,
      importedAt: now,
      expiresAt: now + ttlMinutes * 60 * 1000,
    );
    await _authRepository.saveBootstrapToken(state);
    final config = await _configRepository.load();
    final next = config.copyWith(gatewayUrl: payload.gatewayUrl);
    await _configRepository.save(next);
    return state;
  }

  void _guardAgainstClawGateway(String gatewayUrl) {
    if (gatewayUrl.trim().isEmpty) {
      return;
    }
    final normalized = gatewayUrl.trim();
    if (normalized.toLowerCase().endsWith('/claw')) {
      throw StateError(
        '配对码无效：请重新获取配对码（正确地址应为 wss://thisdcw.cn）。',
      );
    }
  }
}
```

- [ ] **Step 3: Update parser test to assert `url` is parsed**

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_openclaw/src/infrastructure/util/bootstrap_payload_parser.dart';

void main() {
  test('parses url and bootstrap token from setup code payload', () {
    const token = 'boot-token-123';
    const payload = <String, Object?>{
      'url': 'wss://thisdcw.cn',
      'bootstrapToken': token,
    };
    final encoded = base64Url.encode(utf8.encode(jsonEncode(payload)));

    final parser = BootstrapPayloadParser();
    final result = parser.parse(encoded);

    expect(result.gatewayUrl, 'wss://thisdcw.cn');
    expect(result.bootstrapToken, token);
  });
}
```

- [ ] **Step 4: Add import use-case tests for `/claw` rejection and success**

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_openclaw/src/application/use_cases/import_bootstrap_token_use_case.dart';
import 'package:flutter_openclaw/src/domain/models/gateway_config.dart';
import 'package:flutter_openclaw/src/domain/repositories/auth_repository.dart';
import 'package:flutter_openclaw/src/domain/repositories/config_repository.dart';
import 'package:flutter_openclaw/src/infrastructure/util/bootstrap_payload_parser.dart';

class _InMemoryAuthRepository implements AuthRepository {
  BootstrapTokenState? bootstrap;
  DeviceIdentity? identity;
  OperatorAuthState? operatorAuth;

  @override
  Future<void> saveBootstrapToken(BootstrapTokenState state) async {
    bootstrap = state;
  }

  @override
  Future<BootstrapTokenState?> loadBootstrapToken() async => bootstrap;

  @override
  Future<void> clearBootstrapToken() async {
    bootstrap = null;
  }

  @override
  Future<void> saveDeviceIdentity(DeviceIdentity identity) async {
    this.identity = identity;
  }

  @override
  Future<DeviceIdentity?> loadDeviceIdentity() async => identity;

  @override
  Future<void> clearDeviceIdentity() async {
    identity = null;
  }

  @override
  Future<void> saveOperatorAuth(OperatorAuthState state) async {
    operatorAuth = state;
  }

  @override
  Future<OperatorAuthState?> loadOperatorAuth() async => operatorAuth;

  @override
  Future<void> clearOperatorAuth() async {
    operatorAuth = null;
  }
}

class _InMemoryConfigRepository implements ConfigRepository {
  GatewayConfig config = const GatewayConfig(
    gatewayUrl: '',
    sessionId: '',
    timeoutMs: 60000,
    locale: 'zh-CN',
  );

  @override
  Future<GatewayConfig> load() async => config;

  @override
  Future<void> save(GatewayConfig config) async {
    this.config = config;
  }
}

void main() {
  test('rejects setup code when url ends with /claw', () async {
    final payload = {
      'url': 'wss://thisdcw.cn/claw',
      'bootstrapToken': 'boot',
    };
    final encoded = base64Url.encode(utf8.encode(jsonEncode(payload)));

    final useCase = ImportBootstrapTokenUseCase(
      _InMemoryAuthRepository(),
      _InMemoryConfigRepository(),
      BootstrapPayloadParser(),
    );

    expect(
      () => useCase.call(encoded),
      throwsA(isA<StateError>()),
    );
  });

  test('stores gatewayUrl from setup code', () async {
    final payload = {
      'url': 'wss://thisdcw.cn',
      'bootstrapToken': 'boot',
    };
    final encoded = base64Url.encode(utf8.encode(jsonEncode(payload)));

    final auth = _InMemoryAuthRepository();
    final config = _InMemoryConfigRepository();
    final useCase = ImportBootstrapTokenUseCase(
      auth,
      config,
      BootstrapPayloadParser(),
    );

    final state = await useCase.call(encoded);

    expect(state.gatewayUrl, 'wss://thisdcw.cn');
    expect(config.config.gatewayUrl, 'wss://thisdcw.cn');
  });
}
```

- [ ] **Step 5: Do NOT run tests (per user instruction)**

Skip: test execution intentionally omitted per request.

- [ ] **Step 6: Commit**

```bash
git add lib/src/infrastructure/util/bootstrap_payload_parser.dart \
  lib/src/application/use_cases/import_bootstrap_token_use_case.dart \
  test/infrastructure/util/bootstrap_payload_parser_test.dart \
  test/application/use_cases/import_bootstrap_token_use_case_test.dart

git commit -m "Use setup code url and reject /claw on import"
```

---

### Task 2: Remove Fixed Gateway Normalization & Set Default Root URL

**Files:**
- Modify: `lib/src/infrastructure/storage/shared_prefs_config_repository.dart`
- Modify: `lib/src/application/controllers/settings_controller.dart`
- Modify: `lib/src/infrastructure/config/dev_defaults.dart`
- Modify: `test/infrastructure/storage/shared_prefs_config_repository_test.dart`

- [ ] **Step 1: Update default gateway URL to root**

```dart
const GatewayConfig defaultGatewayConfig = GatewayConfig(
  gatewayUrl: 'wss://thisdcw.cn',
  sessionId: '',
  timeoutMs: 60000,
  locale: 'zh-CN',
);
```

- [ ] **Step 2: Remove gateway normalization from config repository**

```dart
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
      openClawLog(
        'ConfigRepository',
        'load persisted config',
        fields: <String, Object?>{
          'gatewayUrl': config.gatewayUrl,
          'sessionId': config.sessionId,
          'timeoutMs': config.timeoutMs,
          'locale': config.locale,
        },
      );
      return config;
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
    final encoded = jsonEncode(config.toJson());
    openClawLog(
      'ConfigRepository',
      'save config',
      fields: <String, Object?>{
        'gatewayUrl': config.gatewayUrl,
        'sessionId': config.sessionId,
        'timeoutMs': config.timeoutMs,
        'locale': config.locale,
      },
    );
    await _prefs.setString(_storageKey, encoded);
  }
```

- [ ] **Step 3: Remove gateway normalization from SettingsController**

```dart
  })  : _config = initialConfig ?? defaultGatewayConfig,
        _localePreference = initialLocalePreference,
        _configRepository = configRepository,
        _authRepository = authRepository,
        _appLocalePreferenceRepository = appLocalePreferenceRepository,
        _clearOperatorAuthUseCase = clearOperatorAuthUseCase,
        _importBootstrapTokenUseCase = importBootstrapTokenUseCase,
        _resetDeviceIdentityUseCase = resetDeviceIdentityUseCase,
        _isStub = isStub;

  void update(GatewayConfig next) {
    openClawLog(
      'SettingsController',
      'update in-memory config',
      fields: <String, Object?>{
        'gatewayUrl': next.gatewayUrl,
        'sessionId': next.sessionId,
        'timeoutMs': next.timeoutMs,
        'locale': next.locale,
      },
    );
    _config = next;
    notifyListeners();
  }

  Future<void> save(GatewayConfig next) async {
    openClawLog(
      'SettingsController',
      'save config',
      fields: <String, Object?>{
        'gatewayUrl': next.gatewayUrl,
        'sessionId': next.sessionId,
        'timeoutMs': next.timeoutMs,
        'locale': next.locale,
      },
    );
    _config = next;
    await _configRepository?.save(next);
    notifyListeners();
  }

  Future<void> importBootstrapToken(String input) async {
    await _importBootstrapTokenUseCase?.call(input);
    final persistedConfig = await _configRepository?.load();
    if (persistedConfig != null) {
      _config = persistedConfig;
    }
    await refreshSecuritySnapshot(notify: false);
    notifyListeners();
  }

  Future<void> syncActiveSessionId(String sessionId) async {
    if (_config.sessionId == sessionId) {
      return;
    }
    final next = _config.copyWith(sessionId: sessionId);
    _config = next;
    await _configRepository?.save(next);
    notifyListeners();
  }
```

- [ ] **Step 4: Update repository tests to stop asserting normalization**

```dart
  test('save persists gatewayUrl as-is', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = SharedPrefsConfigRepository(prefs);

    const config = GatewayConfig(
      gatewayUrl: 'wss://example.invalid/gateway',
      sessionId: 'session-123',
      timeoutMs: 1234,
      locale: 'en-US',
    );

    await repository.save(config);

    final stored = prefs.getString('gateway_config');
    expect(stored, isNotNull);

    final payload = jsonDecode(stored!) as Map<String, dynamic>;
    expect(payload['gatewayUrl'], config.gatewayUrl);
  });

  test('load returns stored gatewayUrl as-is', () async {
    const storedConfig = <String, Object?>{
      'gatewayUrl': 'wss://example.invalid/other',
      'sessionId': 'session-456',
      'timeoutMs': 5678,
      'locale': 'fr-FR',
    };

    SharedPreferences.setMockInitialValues({
      'gateway_config': jsonEncode(storedConfig),
    });

    final prefs = await SharedPreferences.getInstance();
    final repository = SharedPrefsConfigRepository(prefs);

    final config = await repository.load();

    expect(config.gatewayUrl, storedConfig['gatewayUrl']);
  });
```

- [ ] **Step 5: Do NOT run tests (per user instruction)**

Skip: test execution intentionally omitted per request.

- [ ] **Step 6: Commit**

```bash
git add lib/src/infrastructure/config/dev_defaults.dart \
  lib/src/infrastructure/storage/shared_prefs_config_repository.dart \
  lib/src/application/controllers/settings_controller.dart \
  test/infrastructure/storage/shared_prefs_config_repository_test.dart

git commit -m "Use setup code gateway URL in config state"
```

---

### Task 3: Runtime `/claw` Guard + Bootstrap-Only DeviceToken Persistence

**Files:**
- Modify: `lib/src/application/use_cases/test_connection_use_case.dart`
- Modify: `test/application/use_cases/test_connection_use_case_test.dart`

- [ ] **Step 1: Add runtime guard for `/claw` gatewayUrl**

```dart
  Future<AuthenticatedGatewaySession> connect({
    required GatewayConfig config,
  }) async {
    _guardAgainstClawGateway(config.gatewayUrl);
    openClawLog(
      'TestConnection',
      'connect start',
      fields: <String, Object?>{
        'gatewayUrl': config.gatewayUrl,
        'sessionId': config.sessionId,
        'timeoutMs': config.timeoutMs,
        'locale': config.locale,
      },
    );
    // ... rest unchanged
  }

  void _guardAgainstClawGateway(String gatewayUrl) {
    final normalized = gatewayUrl.trim();
    if (normalized.isEmpty) {
      return;
    }
    if (normalized.toLowerCase().endsWith('/claw')) {
      throw StateError('检测到旧版本网关地址，请重新导入配对码。');
    }
  }
```

- [ ] **Step 2: Persist deviceToken only on bootstrap success + clear bootstrapToken**

```dart
      final nextAuth = _parser.extractHelloOkAuth(response) ?? operatorAuth;
      if (usingBootstrapToken && nextAuth != null) {
        await _authRepository.saveOperatorAuth(nextAuth);
        await _authRepository.clearBootstrapToken();
        openClawLog(
          'TestConnection',
          'persisted operator auth from bootstrap',
          fields: <String, Object?>{
            'deviceToken': redactValue(nextAuth.deviceToken),
            'scopes': nextAuth.scopes.join(','),
          },
        );
      }

      final effectiveAuth = usingBootstrapToken ? nextAuth : operatorAuth;
```

- [ ] **Step 3: Update connect return status to use effective auth**

```dart
      return AuthenticatedGatewaySession(
        client: client,
        deviceIdentity: deviceIdentity,
        operatorAuth: effectiveAuth,
        status: ConnectionStatus(
          phase: ConnectionPhase.ready,
          grantedScopes: effectiveAuth?.scopes ?? const <String>[],
          deviceId: deviceIdentity.id,
        ),
      );
```

- [ ] **Step 4: Update test to expect config gatewayUrl (not default)**

```dart
  expect(capturedUris.single.toString(), 'wss://thisdcw.cn');
```

- [ ] **Step 5: Add test for `/claw` runtime guard**

```dart
  test('connect throws when gatewayUrl ends with /claw', () async {
    final useCase = TestConnectionUseCase(
      authRepository: _FakeAuthRepository(
        deviceIdentity: const DeviceIdentity(id: 'id', publicKey: 'pk'),
      ),
      identityService: _FakeDeviceIdentityService(
        const DeviceIdentity(id: 'id', publicKey: 'pk'),
      ),
      channelFactory: (uri) => _FakeWebSocketChannel(),
    );

    const config = GatewayConfig(
      gatewayUrl: 'wss://thisdcw.cn/claw',
      sessionId: '',
      timeoutMs: 1000,
      locale: 'zh-CN',
    );

    expect(
      () => useCase.connect(config: config),
      throwsA(isA<StateError>()),
    );
  });
```

- [ ] **Step 6: Do NOT run tests (per user instruction)**

Skip: test execution intentionally omitted per request.

- [ ] **Step 7: Commit**

```bash
git add lib/src/application/use_cases/test_connection_use_case.dart \
  test/application/use_cases/test_connection_use_case_test.dart

git commit -m "Use setup code gateway and bootstrap-only device token"
```

---

## Plan Self-Review

- **Spec coverage:**
  - Setup code url used verbatim: Task 1 & Task 2.
  - `/claw` rejection at import: Task 1.
  - Runtime `/claw` guard: Task 3.
  - Bootstrap-only `deviceToken` persistence + clear bootstrap: Task 3.
  - Reconnect uses deviceToken (no overwrite): Task 3.
- **Placeholder scan:** No TODO/TBD placeholders present.
- **Type consistency:** Models and repository interfaces align with existing code.

---

Plan complete and saved to `docs/superpowers/plans/2026-04-14-setup-code-gateway-url.md`. Two execution options:

1. Subagent-Driven (recommended) - I dispatch a fresh subagent per task, review between tasks, fast iteration
2. Inline Execution - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
