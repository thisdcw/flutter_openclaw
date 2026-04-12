# Flutter OpenClaw Localization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add app-wide English and Simplified Chinese localization, defaulting to the system language and allowing the user to switch app language from the settings screen without coupling UI language to gateway locale.

**Architecture:** Use Flutter's standard `gen_l10n` flow for all visible UI copy. Introduce a separate app-language preference model persisted in `SharedPreferences`, wire `OpenClawApp` to rebuild from `SettingsController`, and keep dynamic connection/chat error copy locale-independent until the presentation layer maps it to localized strings.

**Tech Stack:** Flutter, Dart, `flutter_localizations`, `intl`, `shared_preferences`, `flutter_test`

---

## File Structure

- Modify: `flutter_openclaw/pubspec.yaml`
  Enable Flutter localization generation and add localization dependencies.
- Create: `flutter_openclaw/lib/l10n/app_en.arb`
  English source strings for the app UI.
- Create: `flutter_openclaw/lib/l10n/app_zh.arb`
  Simplified Chinese translations for the app UI.
- Create: `flutter_openclaw/lib/src/domain/models/app_locale_preference.dart`
  Stable app-language preference enum with storage values.
- Create: `flutter_openclaw/lib/src/domain/repositories/app_locale_preference_repository.dart`
  Repository contract for loading and saving the app-language preference.
- Create: `flutter_openclaw/lib/src/infrastructure/storage/shared_prefs_app_locale_preference_repository.dart`
  SharedPreferences-backed implementation using a dedicated key.
- Modify: `flutter_openclaw/lib/src/application/controllers/settings_controller.dart`
  Hold the current app-language preference and expose save/update APIs.
- Modify: `flutter_openclaw/lib/src/app/app_dependencies.dart`
  Load the persisted app-language preference at startup and inject the new repository.
- Modify: `flutter_openclaw/lib/src/app/openclaw_app.dart`
  Configure `MaterialApp` localization, app-level locale switching, and rebuild behavior.
- Create: `flutter_openclaw/lib/src/presentation/localization/localized_gateway_text.dart`
  Presentation-layer helpers for localized phase labels, blocked-send reasons, and gateway/chat failures.
- Modify: `flutter_openclaw/lib/src/application/controllers/chat_controller.dart`
  Preserve raw error reasons so the presentation layer can localize them at render time.
- Modify: `flutter_openclaw/lib/src/presentation/screens/settings_screen.dart`
  Add app-language state and pass language controls into the settings form.
- Modify: `flutter_openclaw/lib/src/presentation/widgets/settings_form.dart`
  Show the new language selector and relabel the existing locale field as gateway locale.
- Modify: `flutter_openclaw/lib/src/presentation/screens/chat_screen.dart`
  Replace hardcoded strings with localized copy and use localized connection/failure helpers.
- Modify: `flutter_openclaw/lib/src/presentation/widgets/connection_summary_card.dart`
  Localize headings and field labels while keeping scope values raw.
- Modify: `flutter_openclaw/lib/src/presentation/widgets/chat_composer.dart`
  Localize tooltip, hint, and send/streaming labels.
- Modify: `flutter_openclaw/lib/src/presentation/widgets/message_bubble.dart`
  Localize streaming text and error bubble copy.
- Modify: `flutter_openclaw/lib/src/presentation/widgets/status_badge.dart`
  Render localized connection-phase labels.
- Create: `flutter_openclaw/test/infrastructure/shared_prefs_app_locale_preference_repository_test.dart`
  Verify app-language persistence default and round-trips.
- Modify: `flutter_openclaw/test/application/chat_controller_test.dart`
  Lock in the locale-independent raw error payload behavior.
- Modify: `flutter_openclaw/test/widget_test.dart`
  Verify system-follow locale, explicit overrides, settings selector copy, and localized connection/chat UI.

## Task 1: Add A Dedicated App Locale Preference Model And Repository

**Files:**
- Create: `flutter_openclaw/lib/src/domain/models/app_locale_preference.dart`
- Create: `flutter_openclaw/lib/src/domain/repositories/app_locale_preference_repository.dart`
- Create: `flutter_openclaw/lib/src/infrastructure/storage/shared_prefs_app_locale_preference_repository.dart`
- Create: `flutter_openclaw/test/infrastructure/shared_prefs_app_locale_preference_repository_test.dart`

- [ ] **Step 1: Write the failing repository tests**

Create `flutter_openclaw/test/infrastructure/shared_prefs_app_locale_preference_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_openclaw/src/domain/models/app_locale_preference.dart';
import 'package:flutter_openclaw/src/infrastructure/storage/shared_prefs_app_locale_preference_repository.dart';

void main() {
  group('SharedPrefsAppLocalePreferenceRepository', () {
    test('load returns system when nothing is persisted', () async {
      final repository =
          await SharedPrefsAppLocalePreferenceRepository.inMemory();

      expect(await repository.load(), AppLocalePreference.system);
    });

    test('saved preferences round-trip through shared prefs', () async {
      final repository =
          await SharedPrefsAppLocalePreferenceRepository.inMemory();

      await repository.save(AppLocalePreference.simplifiedChinese);

      expect(
        await repository.load(),
        AppLocalePreference.simplifiedChinese,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/shared_prefs_app_locale_preference_repository_test.dart`
Expected: FAIL with missing repository and enum symbols.

- [ ] **Step 3: Implement the enum, repository contract, and SharedPreferences storage**

Create `flutter_openclaw/lib/src/domain/models/app_locale_preference.dart`:

```dart
enum AppLocalePreference {
  system('system'),
  english('en'),
  simplifiedChinese('zh-Hans');

  const AppLocalePreference(this.storageValue);

  final String storageValue;

  static AppLocalePreference fromStorageValue(String? value) {
    for (final candidate in AppLocalePreference.values) {
      if (candidate.storageValue == value) {
        return candidate;
      }
    }
    return AppLocalePreference.system;
  }
}
```

Create `flutter_openclaw/lib/src/domain/repositories/app_locale_preference_repository.dart`:

```dart
import '../models/app_locale_preference.dart';

abstract class AppLocalePreferenceRepository {
  Future<AppLocalePreference> load();
  Future<void> save(AppLocalePreference preference);
}
```

Create `flutter_openclaw/lib/src/infrastructure/storage/shared_prefs_app_locale_preference_repository.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_locale_preference.dart';
import '../../domain/repositories/app_locale_preference_repository.dart';

class SharedPrefsAppLocalePreferenceRepository
    implements AppLocalePreferenceRepository {
  SharedPrefsAppLocalePreferenceRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _storageKey = 'app_locale_preference';

  static Future<SharedPrefsAppLocalePreferenceRepository> inMemory() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return SharedPrefsAppLocalePreferenceRepository(prefs);
  }

  @override
  Future<AppLocalePreference> load() async {
    final rawValue = _prefs.getString(_storageKey);
    return AppLocalePreference.fromStorageValue(rawValue);
  }

  @override
  Future<void> save(AppLocalePreference preference) async {
    await _prefs.setString(_storageKey, preference.storageValue);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/infrastructure/shared_prefs_app_locale_preference_repository_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/src/domain/models/app_locale_preference.dart lib/src/domain/repositories/app_locale_preference_repository.dart lib/src/infrastructure/storage/shared_prefs_app_locale_preference_repository.dart test/infrastructure/shared_prefs_app_locale_preference_repository_test.dart
git commit -m "feat: add app locale preference persistence"
```

## Task 2: Enable Flutter Localization And Wire App-Level Locale Switching

**Files:**
- Modify: `flutter_openclaw/pubspec.yaml`
- Create: `flutter_openclaw/lib/l10n/app_en.arb`
- Create: `flutter_openclaw/lib/l10n/app_zh.arb`
- Modify: `flutter_openclaw/lib/src/application/controllers/settings_controller.dart`
- Modify: `flutter_openclaw/lib/src/app/app_dependencies.dart`
- Modify: `flutter_openclaw/lib/src/app/openclaw_app.dart`
- Modify: `flutter_openclaw/test/widget_test.dart`

- [ ] **Step 1: Write the failing widget tests for system-follow and explicit override**

Replace `flutter_openclaw/test/widget_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:flutter_openclaw/src/application/controllers/chat_controller.dart';
import 'package:flutter_openclaw/src/application/controllers/connection_controller.dart';
import 'package:flutter_openclaw/src/application/controllers/settings_controller.dart';
import 'package:flutter_openclaw/src/app/app_dependencies.dart';
import 'package:flutter_openclaw/src/app/openclaw_app.dart';
import 'package:flutter_openclaw/src/domain/models/app_locale_preference.dart';
import 'package:flutter_openclaw/src/presentation/screens/settings_screen.dart';

void main() {
  testWidgets('openclaw app follows system locale by default',
      (WidgetTester tester) async {
    tester.binding.platformDispatcher.localeTestValue =
        const Locale('zh', 'CN');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

    final dependencies = AppDependencies(
      settingsController: SettingsController.fake(),
      connectionController: ConnectionController.fake(),
      chatController: ChatController.fake(),
    );

    await tester.pumpWidget(OpenClawApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(find.text('OpenClaw 对话'), findsOneWidget);
  });

  testWidgets('explicit english preference overrides system locale',
      (WidgetTester tester) async {
    tester.binding.platformDispatcher.localeTestValue =
        const Locale('zh', 'CN');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

    final dependencies = AppDependencies(
      settingsController: SettingsController.fake(
        initialLocalePreference: AppLocalePreference.english,
      ),
      connectionController: ConnectionController.fake(),
      chatController: ChatController.fake(),
    );

    await tester.pumpWidget(OpenClawApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(find.text('OpenClaw Chat'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because localization generation, localized copy, and locale wiring do not exist yet.

- [ ] **Step 3: Enable localization generation and add the source translation files**

Update `flutter_openclaw/pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.2
```

Under the `flutter:` section add:

```yaml
flutter:
  generate: true
  uses-material-design: true
```

Create `flutter_openclaw/lib/l10n/app_en.arb`:

```json
{
  "@@locale": "en",
  "appTitle": "OpenClaw",
  "chatScreenTitle": "OpenClaw Chat",
  "settingsTitle": "Settings",
  "settingsCloseTooltip": "Close Settings",
  "settingsOpenTooltip": "Open Settings",
  "settingsIntro": "Review live connection state and tune your chat session configuration.",
  "gatewayConfigurationTitle": "Gateway Configuration",
  "gatewayConfigurationSubtitle": "Keep the chat session details up to date. Connection can be retried directly from the chat page when needed.",
  "connectionOverviewTitle": "Connection Overview",
  "connectionOverviewSubtitle": "Live connection state for this device and session.",
  "phaseLabel": "Phase",
  "deviceIdLabel": "Device ID",
  "grantedScopesLabel": "Granted Scopes",
  "noneLabel": "(none)",
  "appLanguageLabel": "App Language",
  "followSystemLabel": "Follow system",
  "englishLabel": "English",
  "simplifiedChineseLabel": "Simplified Chinese",
  "settingsFormIntro": "Gateway URL and auth token stay hidden here for a cleaner everyday view. You can still adjust the session and response behavior below.",
  "sessionIdLabel": "Session ID",
  "sessionIdHint": "openclaw-session",
  "gatewayLocaleLabel": "Gateway Locale",
  "gatewayLocaleHint": "zh-CN",
  "timeoutLabel": "Timeout (ms)",
  "timeoutHint": "30000",
  "saveSettingsLabel": "Save Settings",
  "chatEmptyTitle": "Ask anything once your gateway is ready.",
  "chatEmptySubtitle": "Your assistant replies will stream here as soon as the connection is ready and operator.write is available.",
  "connectionButtonLabel": "Connection",
  "connectionConnectingTitle": "Connecting to gateway…",
  "connectionRetrySubtitle": "Check your gateway settings and tap Connection to retry.",
  "connectionStatusSubtitle": "Status: {phase}.",
  "@connectionStatusSubtitle": {
    "placeholders": {
      "phase": {}
    }
  },
  "addImagesTooltip": "Add images",
  "messageHint": "Message OpenClaw",
  "sendLabel": "Send",
  "sendingLabel": "Sending...",
  "streamingResponseLabel": "Streaming response",
  "pickerErrorChannel": "Image picker is not fully registered yet. Fully restart the app and try again.",
  "pickerErrorUnavailable": "The image picker plugin is unavailable. Fully restart the app and try again.",
  "pickerErrorGeneric": "Picking images failed. Please try again.",
  "blockedReasonNotReady": "Connection not ready.",
  "blockedReasonMissingWriteScope": "Missing scope: operator.write.",
  "gatewayFailureMissingWriteScope": "This device is missing operator.write authorization. Complete pairing or refresh authorization first.",
  "gatewayFailurePairingRequired": "This device has not completed pairing authorization yet.",
  "gatewayFailureTimeout": "The request timed out. Check the gateway and try again.",
  "gatewayFailureDisconnect": "The gateway connection was lost. Reconnect and try again.",
  "gatewayFailureAuthFailed": "Authentication failed for this device. Refresh authorization and try again.",
  "gatewayFailureProtocolError": "The gateway protocol response was invalid.",
  "gatewayFailureUnknown": "Gateway error: {code} | {reason}",
  "@gatewayFailureUnknown": {
    "placeholders": {
      "code": {},
      "reason": {}
    }
  },
  "phaseIdle": "Idle",
  "phaseConnecting": "Connecting",
  "phaseWaitingChallenge": "Waiting for challenge",
  "phaseAuthenticating": "Authenticating",
  "phaseReady": "Ready",
  "phaseReconnecting": "Reconnecting",
  "phaseFailed": "Failed"
}
```

Create `flutter_openclaw/lib/l10n/app_zh.arb`:

```json
{
  "@@locale": "zh",
  "appTitle": "OpenClaw",
  "chatScreenTitle": "OpenClaw 对话",
  "settingsTitle": "设置",
  "settingsCloseTooltip": "关闭设置",
  "settingsOpenTooltip": "打开设置",
  "settingsIntro": "查看当前连接状态，并调整你的聊天会话配置。",
  "gatewayConfigurationTitle": "网关配置",
  "gatewayConfigurationSubtitle": "保持聊天会话配置为最新。需要时可以直接在聊天页重试连接。",
  "connectionOverviewTitle": "连接概览",
  "connectionOverviewSubtitle": "查看当前设备和会话的实时连接状态。",
  "phaseLabel": "阶段",
  "deviceIdLabel": "设备 ID",
  "grantedScopesLabel": "已授予权限",
  "noneLabel": "（无）",
  "appLanguageLabel": "应用语言",
  "followSystemLabel": "跟随系统",
  "englishLabel": "English",
  "simplifiedChineseLabel": "简体中文",
  "settingsFormIntro": "这里默认隐藏 Gateway URL 和授权令牌，让日常视图更简洁。你仍然可以在下方调整会话和响应行为。",
  "sessionIdLabel": "会话 ID",
  "sessionIdHint": "openclaw-session",
  "gatewayLocaleLabel": "网关 Locale",
  "gatewayLocaleHint": "zh-CN",
  "timeoutLabel": "超时时间（毫秒）",
  "timeoutHint": "30000",
  "saveSettingsLabel": "保存设置",
  "chatEmptyTitle": "Gateway 就绪后就可以开始提问。",
  "chatEmptySubtitle": "连接就绪并且具备 operator.write 权限后，助手回复会显示在这里。",
  "connectionButtonLabel": "连接",
  "connectionConnectingTitle": "正在连接 Gateway…",
  "connectionRetrySubtitle": "检查网关设置后，点击“连接”重试。",
  "connectionStatusSubtitle": "当前状态：{phase}。",
  "@connectionStatusSubtitle": {
    "placeholders": {
      "phase": {}
    }
  },
  "addImagesTooltip": "添加图片",
  "messageHint": "向 OpenClaw 发送消息",
  "sendLabel": "发送",
  "sendingLabel": "发送中…",
  "streamingResponseLabel": "正在流式返回",
  "pickerErrorChannel": "图片选择器尚未完成原生注册，请完整重启应用后再试。",
  "pickerErrorUnavailable": "图片选择器插件不可用，请完整重启应用后再试。",
  "pickerErrorGeneric": "选择图片失败，请稍后重试。",
  "blockedReasonNotReady": "连接尚未就绪。",
  "blockedReasonMissingWriteScope": "缺少权限：operator.write。",
  "gatewayFailureMissingWriteScope": "当前设备缺少 operator.write 授权，请先完成配对或刷新授权。",
  "gatewayFailurePairingRequired": "当前设备尚未完成配对授权。",
  "gatewayFailureTimeout": "请求超时，请检查 Gateway 状态后重试。",
  "gatewayFailureDisconnect": "Gateway 连接已断开，请重新连接后再试。",
  "gatewayFailureAuthFailed": "当前设备认证失败，请刷新授权后重试。",
  "gatewayFailureProtocolError": "Gateway 协议响应无效。",
  "gatewayFailureUnknown": "Gateway 错误：{code} | {reason}",
  "@gatewayFailureUnknown": {
    "placeholders": {
      "code": {},
      "reason": {}
    }
  },
  "phaseIdle": "空闲",
  "phaseConnecting": "连接中",
  "phaseWaitingChallenge": "等待挑战",
  "phaseAuthenticating": "认证中",
  "phaseReady": "已就绪",
  "phaseReconnecting": "重新连接中",
  "phaseFailed": "失败"
}
```

- [ ] **Step 4: Load the saved preference in the controller graph and rebuild MaterialApp from SettingsController**

Update `flutter_openclaw/lib/src/application/controllers/settings_controller.dart`:

```dart
import '../../domain/models/app_locale_preference.dart';
import '../../domain/repositories/app_locale_preference_repository.dart';
```

```dart
  SettingsController({
    GatewayConfig? initialConfig,
    AppLocalePreference initialLocalePreference =
        AppLocalePreference.system,
    ConfigRepository? configRepository,
    AppLocalePreferenceRepository? appLocalePreferenceRepository,
    ClearOperatorAuthUseCase? clearOperatorAuthUseCase,
    ResetDeviceIdentityUseCase? resetDeviceIdentityUseCase,
    bool isStub = false,
  })  : _config = initialConfig ?? defaultGatewayConfig,
        _localePreference = initialLocalePreference,
        _configRepository = configRepository,
        _appLocalePreferenceRepository = appLocalePreferenceRepository,
        _clearOperatorAuthUseCase = clearOperatorAuthUseCase,
        _resetDeviceIdentityUseCase = resetDeviceIdentityUseCase,
        _isStub = isStub;
```

```dart
  factory SettingsController.fake({
    AppLocalePreference initialLocalePreference =
        AppLocalePreference.system,
  }) =>
      SettingsController(
        isStub: true,
        initialLocalePreference: initialLocalePreference,
      );
```

```dart
  AppLocalePreference _localePreference;
  final AppLocalePreferenceRepository? _appLocalePreferenceRepository;

  AppLocalePreference get localePreference => _localePreference;

  Future<void> saveLocalePreference(AppLocalePreference next) async {
    _localePreference = next;
    await _appLocalePreferenceRepository?.save(next);
    notifyListeners();
  }
```

Update `flutter_openclaw/lib/src/app/app_dependencies.dart`:

```dart
import 'package:flutter_openclaw/src/infrastructure/storage/shared_prefs_app_locale_preference_repository.dart';
```

```dart
    final localePreferenceRepository =
        SharedPrefsAppLocalePreferenceRepository(prefs);
    final initialLocalePreference = await localePreferenceRepository.load();
```

```dart
    final settingsController = SettingsController(
      initialConfig: bootstrapResult.config,
      initialLocalePreference: initialLocalePreference,
      configRepository: configRepository,
      appLocalePreferenceRepository: localePreferenceRepository,
      clearOperatorAuthUseCase: clearOperatorAuthUseCase,
      resetDeviceIdentityUseCase: resetDeviceIdentityUseCase,
    );
```

Update `flutter_openclaw/lib/src/app/openclaw_app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../domain/models/app_locale_preference.dart';
```

```dart
class OpenClawApp extends StatelessWidget {
  const OpenClawApp({
    super.key,
    required this.dependencies,
  });

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: dependencies.settingsController,
      builder: (context, _) {
        final preference = dependencies.settingsController.localePreference;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: switch (preference) {
            AppLocalePreference.system => null,
            AppLocalePreference.english => const Locale('en'),
            AppLocalePreference.simplifiedChinese =>
              const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
          },
          theme: buildAppTheme(),
          home: ChatScreen(
            settingsController: dependencies.settingsController,
            connectionController: dependencies.connectionController,
            chatController: dependencies.chatController,
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS for system-follow Chinese and explicit English override.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml lib/l10n/app_en.arb lib/l10n/app_zh.arb lib/src/application/controllers/settings_controller.dart lib/src/app/app_dependencies.dart lib/src/app/openclaw_app.dart test/widget_test.dart
git commit -m "feat: wire flutter localization and app locale switching"
```

## Task 3: Add The Settings-Screen Language Selector And Keep Gateway Locale Separate

**Files:**
- Modify: `flutter_openclaw/lib/src/presentation/screens/settings_screen.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/settings_form.dart`
- Modify: `flutter_openclaw/test/widget_test.dart`

- [ ] **Step 1: Add the failing settings-screen widget test**

Append this test to `flutter_openclaw/test/widget_test.dart`:

```dart
testWidgets('settings screen shows app language selector and gateway locale label',
    (WidgetTester tester) async {
  final settingsController = SettingsController.fake();
  final connectionController = ConnectionController.fake();
  final chatController = ChatController.fake();

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SettingsScreen(
        settingsController: settingsController,
        connectionController: connectionController,
        chatController: chatController,
      ),
    ),
  );

  expect(find.text('App Language'), findsOneWidget);
  expect(find.text('Gateway Locale'), findsOneWidget);
  expect(find.text('Follow system'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because the settings form still only shows `Locale` as a free-form field and has no app-language selector.

- [ ] **Step 3: Track the selected app-language value in SettingsScreen**

Update `flutter_openclaw/lib/src/presentation/screens/settings_screen.dart`:

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../domain/models/app_locale_preference.dart';
```

```dart
class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController gatewayUrlController;
  late final TextEditingController authTokenController;
  late final TextEditingController sessionIdController;
  late final TextEditingController localeController;
  late final TextEditingController timeoutController;
  late AppLocalePreference localePreference;

  @override
  void initState() {
    super.initState();
    final config = widget.settingsController.config;
    localePreference = widget.settingsController.localePreference;
    gatewayUrlController = TextEditingController(text: config.gatewayUrl);
    authTokenController = TextEditingController(text: config.authToken);
    sessionIdController = TextEditingController(text: config.sessionId);
    localeController = TextEditingController(text: config.locale);
    timeoutController = TextEditingController(text: '${config.timeoutMs}');
  }
```

```dart
    final l10n = AppLocalizations.of(context)!;
```

```dart
                        Text(l10n.settingsTitle,
                            style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text(
                          l10n.settingsIntro,
                          style: theme.textTheme.bodySmall,
                        ),
```

```dart
                    tooltip: l10n.settingsCloseTooltip,
```

```dart
                      Text(
                        l10n.gatewayConfigurationTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.gatewayConfigurationSubtitle,
                        style: theme.textTheme.bodySmall,
                      ),
```

```dart
                      SettingsForm(
                        localePreference: localePreference,
                        sessionIdController: sessionIdController,
                        localeController: localeController,
                        timeoutController: timeoutController,
                        onLocalePreferenceChanged: (next) async {
                          setState(() {
                            localePreference = next;
                          });
                          await widget.settingsController
                              .saveLocalePreference(next);
                        },
                        onSave: _saveSettings,
                      ),
```

- [ ] **Step 4: Add the selector and relabel the gateway locale field in SettingsForm**

Update `flutter_openclaw/lib/src/presentation/widgets/settings_form.dart`:

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../domain/models/app_locale_preference.dart';
```

```dart
  const SettingsForm({
    super.key,
    required this.localePreference,
    required this.sessionIdController,
    required this.localeController,
    required this.timeoutController,
    required this.onLocalePreferenceChanged,
    required this.onSave,
  });

  final AppLocalePreference localePreference;
  final ValueChanged<AppLocalePreference> onLocalePreferenceChanged;
```

```dart
    final l10n = AppLocalizations.of(context)!;
```

```dart
        Text(
          l10n.settingsFormIntro,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<AppLocalePreference>(
          value: localePreference,
          decoration: InputDecoration(
            labelText: l10n.appLanguageLabel,
          ),
          items: <DropdownMenuItem<AppLocalePreference>>[
            DropdownMenuItem(
              value: AppLocalePreference.system,
              child: Text(l10n.followSystemLabel),
            ),
            DropdownMenuItem(
              value: AppLocalePreference.english,
              child: Text(l10n.englishLabel),
            ),
            DropdownMenuItem(
              value: AppLocalePreference.simplifiedChinese,
              child: Text(l10n.simplifiedChineseLabel),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onLocalePreferenceChanged(value);
            }
          },
        ),
```

```dart
          decoration: InputDecoration(
            labelText: l10n.sessionIdLabel,
            hintText: l10n.sessionIdHint,
          ),
```

```dart
                decoration: InputDecoration(
                  labelText: l10n.gatewayLocaleLabel,
                  hintText: l10n.gatewayLocaleHint,
                ),
```

```dart
                decoration: InputDecoration(
                  labelText: l10n.timeoutLabel,
                  hintText: l10n.timeoutHint,
                ),
```

```dart
              label: Text(l10n.saveSettingsLabel),
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS for the settings selector test plus the locale override tests.

- [ ] **Step 6: Commit**

```bash
git add lib/src/presentation/screens/settings_screen.dart lib/src/presentation/widgets/settings_form.dart test/widget_test.dart
git commit -m "feat: add settings language selector"
```

## Task 4: Localize The Remaining UI Copy And Map Dynamic Gateway/Chat State In The Presentation Layer

**Files:**
- Create: `flutter_openclaw/lib/src/presentation/localization/localized_gateway_text.dart`
- Modify: `flutter_openclaw/lib/src/application/controllers/chat_controller.dart`
- Modify: `flutter_openclaw/lib/src/presentation/screens/chat_screen.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/connection_summary_card.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/chat_composer.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/message_bubble.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/status_badge.dart`
- Modify: `flutter_openclaw/test/application/chat_controller_test.dart`
- Modify: `flutter_openclaw/test/widget_test.dart`

- [ ] **Step 1: Write the failing controller and widget tests**

Append this test to `flutter_openclaw/test/application/chat_controller_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_openclaw/src/domain/models/chat_message.dart';
import 'package:flutter_openclaw/src/domain/repositories/chat_repository.dart';
```

```dart
    test('send failure preserves raw error text for localized presentation',
        () async {
      final controller = ChatController(
        chatRepository: _ThrowingChatRepository(),
        sessionIdProvider: () => 'session-1',
      );

      await controller.send(
        ChatDraft(text: 'hello', attachments: const []),
      );

      expect(controller.errorMessage, contains('operator.write'));
      expect(controller.messages.last.text, contains('operator.write'));
    });
```

Append the fake repository at the bottom of the test file:

```dart
class _ThrowingChatRepository implements ChatRepository {
  @override
  Stream<ChatMessage> sendMessage(
    ChatDraft draft, {
    required String sessionId,
  }) async* {
    throw Exception('missing scope: operator.write');
  }
}
```

Append this test to `flutter_openclaw/test/widget_test.dart`:

```dart
testWidgets('localized chat screen shows translated blocked reason in chinese',
    (WidgetTester tester) async {
  tester.binding.platformDispatcher.localeTestValue =
      const Locale('zh', 'CN');
  addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

  final connectionController = ConnectionController.fake()
    ..phase = 'ready'
    ..grantedScopes = ['operator.read'];
  final chatController = ChatController.fake();

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChatScreen(
        chatController: chatController,
        connectionController: connectionController,
        settingsController: SettingsController.fake(),
      ),
    ),
  );

  expect(find.text('缺少权限：operator.write。'), findsOneWidget);
  expect(find.text('连接'), findsNothing);
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/application/chat_controller_test.dart test/widget_test.dart`
Expected: FAIL because chat errors are still pre-localized Chinese strings in the controller and the presentation layer still uses hardcoded English/Chinese copy.

- [ ] **Step 3: Preserve raw error reasons in ChatController so UI can localize by locale**

Update the `catch` block in `flutter_openclaw/lib/src/application/controllers/chat_controller.dart`:

```dart
    } catch (error) {
      final rawReason = error.toString();
      _messages.removeWhere(
        (message) =>
            message.role == MessageRole.assistant &&
            message.isStreaming &&
            message.text.isEmpty,
      );
      errorMessage = rawReason;
      openClawLog(
        'ChatController',
        'send failed',
        fields: <String, Object?>{
          'error': rawReason,
        },
      );
      _messages.add(
        ChatMessage(
          id: 'error-${_messages.length}',
          role: MessageRole.error,
          text: rawReason,
        ),
      );
      notifyListeners();
    }
```

- [ ] **Step 4: Add presentation-layer helpers for localized phase, blocked, and failure copy**

Create `flutter_openclaw/lib/src/presentation/localization/localized_gateway_text.dart`:

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../domain/models/gateway_failure.dart';

String localizedPhaseLabel(AppLocalizations l10n, String phase) {
  return switch (phase) {
    'idle' => l10n.phaseIdle,
    'connecting' => l10n.phaseConnecting,
    'waitingChallenge' => l10n.phaseWaitingChallenge,
    'authenticating' => l10n.phaseAuthenticating,
    'ready' => l10n.phaseReady,
    'reconnecting' => l10n.phaseReconnecting,
    'failed' => l10n.phaseFailed,
    _ => phase,
  };
}

String localizedBlockedReason(AppLocalizations l10n, String rawReason) {
  if (rawReason.contains('operator.write')) {
    return l10n.blockedReasonMissingWriteScope;
  }
  if (rawReason.contains('connection not ready')) {
    return l10n.blockedReasonNotReady;
  }
  return rawReason;
}

String localizedGatewayFailure(
  AppLocalizations l10n, {
  GatewayFailure? failure,
  String? rawReason,
}) {
  final resolvedFailure = failure ??
      GatewayFailure.fromCode(
        code: 'UNKNOWN',
        reason: rawReason ?? 'unknown',
      );

  return switch (resolvedFailure.type) {
    GatewayFailureType.missingWriteScope =>
      l10n.gatewayFailureMissingWriteScope,
    GatewayFailureType.pairingRequired =>
      l10n.gatewayFailurePairingRequired,
    GatewayFailureType.timeout => l10n.gatewayFailureTimeout,
    GatewayFailureType.disconnect => l10n.gatewayFailureDisconnect,
    GatewayFailureType.authFailed => l10n.gatewayFailureAuthFailed,
    GatewayFailureType.protocolError => l10n.gatewayFailureProtocolError,
    GatewayFailureType.unknown => l10n.gatewayFailureUnknown(
        resolvedFailure.code,
        resolvedFailure.reason,
      ),
  };
}
```

- [ ] **Step 5: Replace the remaining hardcoded UI copy with AppLocalizations and helper-based dynamic text**

Update `flutter_openclaw/lib/src/presentation/screens/chat_screen.dart`:

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../localization/localized_gateway_text.dart';
```

```dart
        final l10n = AppLocalizations.of(context)!;
```

Add this line at the top of `_pickImages()`:

```dart
final l10n = AppLocalizations.of(context)!;
```

```dart
          appBar: AppBar(
            title: Text(l10n.chatScreenTitle, style: theme.textTheme.titleMedium),
            actions: [
              StatusBadge(label: widget.connectionController.phase),
              const SizedBox(width: 6),
              IconButton(
                onPressed: widget.settingsController == null
                    ? null
                    : _openSettings,
                icon: const Icon(Icons.settings_rounded),
                tooltip: l10n.settingsOpenTooltip,
              ),
```

```dart
        final blockedReason = localizedBlockedReason(
          l10n,
          widget.connectionController.sendBlockedReason,
        );
        final localizedFailureMessage = connectionStatus.failure == null
            ? ''
            : localizedGatewayFailure(
                l10n,
                failure: connectionStatus.failure,
              );
```

```dart
                    if (connectionStatus.isReady && blockedReason.isNotEmpty) ...[
                      _ChatBanner(
                        message: blockedReason,
                        color: const Color(0xFFFFF2D9),
                        textColor: const Color(0xFF8A5A00),
                      ),
```

```dart
                    if (localizedFailureMessage.isNotEmpty) ...[
                      _ChatBanner(
                        message: localizedFailureMessage,
                        color: theme.colorScheme.errorContainer,
                        textColor: theme.colorScheme.onErrorContainer,
                      ),
```

```dart
            ? l10n.connectionConnectingTitle
            : connectionStatus.failure != null
                ? localizedGatewayFailure(l10n, failure: connectionStatus.failure)
                : l10n.connectionStatusSubtitle(
                    localizedPhaseLabel(l10n, status.phase.value),
                  );
```

```dart
            child: Text(l10n.connectionButtonLabel),
```

```dart
              _presentPickerError(
                error.code == 'channel-error'
                    ? l10n.pickerErrorChannel
                    : l10n.pickerErrorGeneric,
              );
```

```dart
      _presentPickerError(l10n.pickerErrorUnavailable);
```

```dart
      _presentPickerError(l10n.pickerErrorGeneric);
```

Update `flutter_openclaw/lib/src/presentation/widgets/connection_summary_card.dart`:

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../localization/localized_gateway_text.dart';
```

```dart
    final l10n = AppLocalizations.of(context)!;
```

```dart
            Text(l10n.connectionOverviewTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              l10n.connectionOverviewSubtitle,
              style: theme.textTheme.bodySmall,
            ),
```

```dart
                _SummaryTile(
                  label: l10n.phaseLabel,
                  value: localizedPhaseLabel(l10n, phase),
                ),
                _SummaryTile(label: l10n.deviceIdLabel, value: deviceId),
                _SummaryTile(
                  label: l10n.grantedScopesLabel,
                  value: scopes.isEmpty ? l10n.noneLabel : scopes.join(', '),
                  isWide: true,
                ),
```

Update `flutter_openclaw/lib/src/presentation/widgets/chat_composer.dart`:

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

```dart
    final l10n = AppLocalizations.of(context)!;
```

```dart
                tooltip: l10n.addImagesTooltip,
```

```dart
                    hintText: l10n.messageHint,
```

```dart
                child: Text(isSending ? l10n.sendingLabel : l10n.sendLabel),
```

Update `flutter_openclaw/lib/src/presentation/widgets/message_bubble.dart`:

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../localization/localized_gateway_text.dart';
```

```dart
    final l10n = AppLocalizations.of(context)!;
```

```dart
      final textSegment = segment as MessageTextSegment;
      final localizedText = isUser || message.role != MessageRole.error
          ? textSegment.text
          : localizedGatewayFailure(
              l10n,
              rawReason: textSegment.text,
            );
      return Text(
        localizedText,
```

```dart
                  l10n.streamingResponseLabel,
```

Update `flutter_openclaw/lib/src/presentation/widgets/status_badge.dart`:

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../localization/localized_gateway_text.dart';
```

```dart
    final l10n = AppLocalizations.of(context)!;
```

```dart
        localizedPhaseLabel(l10n, label),
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/application/chat_controller_test.dart test/widget_test.dart`
Expected: PASS for raw error preservation, locale override behavior, settings selector copy, and localized blocked-reason rendering.

- [ ] **Step 7: Commit**

```bash
git add lib/src/application/controllers/chat_controller.dart lib/src/presentation/localization/localized_gateway_text.dart lib/src/presentation/screens/chat_screen.dart lib/src/presentation/widgets/connection_summary_card.dart lib/src/presentation/widgets/chat_composer.dart lib/src/presentation/widgets/message_bubble.dart lib/src/presentation/widgets/status_badge.dart test/application/chat_controller_test.dart test/widget_test.dart
git commit -m "feat: localize openclaw chat and gateway copy"
```

## Task 5: Run The Full Verification Loop

**Files:**
- Modify: `flutter_openclaw/pubspec.yaml`
- Create: `flutter_openclaw/lib/l10n/app_en.arb`
- Create: `flutter_openclaw/lib/l10n/app_zh.arb`
- Create: `flutter_openclaw/lib/src/domain/models/app_locale_preference.dart`
- Create: `flutter_openclaw/lib/src/domain/repositories/app_locale_preference_repository.dart`
- Create: `flutter_openclaw/lib/src/infrastructure/storage/shared_prefs_app_locale_preference_repository.dart`
- Modify: `flutter_openclaw/lib/src/application/controllers/settings_controller.dart`
- Modify: `flutter_openclaw/lib/src/app/app_dependencies.dart`
- Modify: `flutter_openclaw/lib/src/app/openclaw_app.dart`
- Create: `flutter_openclaw/lib/src/presentation/localization/localized_gateway_text.dart`
- Modify: `flutter_openclaw/lib/src/application/controllers/chat_controller.dart`
- Modify: `flutter_openclaw/lib/src/presentation/screens/settings_screen.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/settings_form.dart`
- Modify: `flutter_openclaw/lib/src/presentation/screens/chat_screen.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/connection_summary_card.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/chat_composer.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/message_bubble.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/status_badge.dart`
- Create: `flutter_openclaw/test/infrastructure/shared_prefs_app_locale_preference_repository_test.dart`
- Modify: `flutter_openclaw/test/application/chat_controller_test.dart`
- Modify: `flutter_openclaw/test/widget_test.dart`

- [ ] **Step 1: Run static analysis**

Run: `flutter analyze`
Expected: No analysis errors.

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: All tests PASS, including config persistence, app-locale persistence, widget localization, and chat controller coverage.

- [ ] **Step 3: Review the final diff**

Run: `git diff -- pubspec.yaml lib/l10n/app_en.arb lib/l10n/app_zh.arb lib/src/domain/models/app_locale_preference.dart lib/src/domain/repositories/app_locale_preference_repository.dart lib/src/infrastructure/storage/shared_prefs_app_locale_preference_repository.dart lib/src/application/controllers/settings_controller.dart lib/src/app/app_dependencies.dart lib/src/app/openclaw_app.dart lib/src/presentation/localization/localized_gateway_text.dart lib/src/application/controllers/chat_controller.dart lib/src/presentation/screens/settings_screen.dart lib/src/presentation/widgets/settings_form.dart lib/src/presentation/screens/chat_screen.dart lib/src/presentation/widgets/connection_summary_card.dart lib/src/presentation/widgets/chat_composer.dart lib/src/presentation/widgets/message_bubble.dart lib/src/presentation/widgets/status_badge.dart test/infrastructure/shared_prefs_app_locale_preference_repository_test.dart test/application/chat_controller_test.dart test/widget_test.dart`
Expected: Diff contains only localization setup, app-language preference plumbing, and UI text updates.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml lib/l10n/app_en.arb lib/l10n/app_zh.arb lib/src/domain/models/app_locale_preference.dart lib/src/domain/repositories/app_locale_preference_repository.dart lib/src/infrastructure/storage/shared_prefs_app_locale_preference_repository.dart lib/src/application/controllers/settings_controller.dart lib/src/app/app_dependencies.dart lib/src/app/openclaw_app.dart lib/src/presentation/localization/localized_gateway_text.dart lib/src/application/controllers/chat_controller.dart lib/src/presentation/screens/settings_screen.dart lib/src/presentation/widgets/settings_form.dart lib/src/presentation/screens/chat_screen.dart lib/src/presentation/widgets/connection_summary_card.dart lib/src/presentation/widgets/chat_composer.dart lib/src/presentation/widgets/message_bubble.dart lib/src/presentation/widgets/status_badge.dart test/infrastructure/shared_prefs_app_locale_preference_repository_test.dart test/application/chat_controller_test.dart test/widget_test.dart
git commit -m "feat: add app-wide english and chinese localization"
```

## Plan Self-Review

### Spec Coverage

- English and Simplified Chinese support: Task 2
- default follow-system behavior: Task 2
- persisted app-language override: Tasks 1 and 2
- settings-page language switcher: Task 3
- separation from gateway locale: Task 3
- full current UI copy migration: Task 4
- dynamic connection/chat failure localization: Task 4
- future-language-friendly structure: Tasks 1 and 2

### Placeholder Scan

- No `TODO`, `TBD`, or “implement later” placeholders remain
- Every task names exact files
- Every code-writing step includes concrete code snippets
- Every verification step includes an exact command and expected result

### Type Consistency

- `AppLocalePreference.system`, `.english`, and `.simplifiedChinese` are used consistently across repository, controller, and widgets
- `SettingsController.localePreference` and `saveLocalePreference(...)` are defined before the widgets consume them
- Dynamic gateway/chat localization uses one presentation helper file instead of repeating inference logic across widgets
