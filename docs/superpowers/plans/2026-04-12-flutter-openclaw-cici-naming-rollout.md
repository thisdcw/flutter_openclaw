# Flutter OpenClaw Cici Naming Rollout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename every user-visible product name in the app from `OpenClaw` or `flutter_openclaw` to `Cici` while keeping internal package and project identifiers stable.

**Architecture:** Treat the rename as a presentation-and-metadata change, not a repo identity migration. Update localized strings first, then align mobile/web metadata, and finally patch desktop-facing names on macOS and Windows without touching package imports, Android application IDs, Kotlin package paths, or bundle identifiers.

**Tech Stack:** Flutter, Dart localization (`arb` + `flutter gen-l10n`), Android manifest metadata, iOS/macOS plist and xcconfig metadata, web HTML/manifest metadata, Windows runner metadata, Flutter widget tests

---

## File Structure

- Modify: `flutter_openclaw/lib/l10n/app_en.arb`
- Modify: `flutter_openclaw/lib/l10n/app_zh.arb`
- Modify: `flutter_openclaw/lib/l10n/app_localizations.dart`
- Modify: `flutter_openclaw/lib/l10n/app_localizations_en.dart`
- Modify: `flutter_openclaw/lib/l10n/app_localizations_zh.dart`
- Modify: `flutter_openclaw/test/widget_test.dart`
- Modify: `flutter_openclaw/android/app/src/main/AndroidManifest.xml`
- Modify: `flutter_openclaw/ios/Runner/Info.plist`
- Modify: `flutter_openclaw/web/index.html`
- Modify: `flutter_openclaw/web/manifest.json`
- Modify: `flutter_openclaw/macos/Runner/Configs/AppInfo.xcconfig`
- Modify: `flutter_openclaw/windows/runner/main.cpp`
- Modify: `flutter_openclaw/windows/runner/Runner.rc`
- Create: `flutter_openclaw/test/tool/user_visible_app_name_metadata_test.dart`

## Task 1: Rename In-App Localized Titles To Cici

**Files:**
- Modify: `flutter_openclaw/lib/l10n/app_en.arb`
- Modify: `flutter_openclaw/lib/l10n/app_zh.arb`
- Modify: `flutter_openclaw/lib/l10n/app_localizations.dart`
- Modify: `flutter_openclaw/lib/l10n/app_localizations_en.dart`
- Modify: `flutter_openclaw/lib/l10n/app_localizations_zh.dart`
- Modify: `flutter_openclaw/test/widget_test.dart`

- [ ] **Step 1: Update the existing widget test to the new public name**

Update `test/widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_openclaw/src/application/controllers/chat_controller.dart';
import 'package:flutter_openclaw/src/application/controllers/connection_controller.dart';
import 'package:flutter_openclaw/src/app/openclaw_app.dart';
import 'package:flutter_openclaw/src/app/app_dependencies.dart';
import 'package:flutter_openclaw/src/presentation/screens/chat_screen.dart';

void main() {
  testWidgets('chat screen is the home view', (WidgetTester tester) async {
    await tester.pumpWidget(OpenClawApp(dependencies: AppDependencies.fake()));

    expect(find.text('Cici'), findsOneWidget);
  });

  testWidgets('failed connection shows strip and Connection button',
      (WidgetTester tester) async {
    final connectionController = ConnectionController.fake()
      ..markFailed('Gateway unavailable');
    final chatController = ChatController.fake();

    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          chatController: chatController,
          connectionController: connectionController,
        ),
      ),
    );

    expect(find.text('Gateway unavailable'), findsOneWidget);
    expect(
      find.text('Check your gateway settings and tap Connection to retry.'),
      findsOneWidget,
    );
    expect(find.text('Connection'), findsOneWidget);
  });

  testWidgets('connecting state shows strip text and no Connection button',
      (WidgetTester tester) async {
    final connectionController = ConnectionController.fake()..markConnecting();
    final chatController = ChatController.fake();

    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          chatController: chatController,
          connectionController: connectionController,
        ),
      ),
    );

    expect(find.text('Connecting to gateway…'), findsOneWidget);
    expect(find.text('Connection'), findsNothing);
  });

  testWidgets('ready but blocked shows reason and no Connection button',
      (WidgetTester tester) async {
    final connectionController = ConnectionController.fake()
      ..phase = 'ready'
      ..grantedScopes = ['operator.read'];
    final chatController = ChatController.fake();

    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          chatController: chatController,
          connectionController: connectionController,
        ),
      ),
    );

    expect(find.text('missing scope: operator.write'), findsOneWidget);
    expect(find.text('Connection'), findsNothing);
  });
}
```

- [ ] **Step 2: Run the widget test to verify it fails before the rename**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because the app still renders `OpenClaw Chat` rather than `Cici`.

- [ ] **Step 3: Update the source localization strings**

Update `lib/l10n/app_en.arb`:

```json
{
  "@@locale": "en",
  "appTitle": "Cici",
  "chatScreenTitle": "Cici",
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
  "pendingDeviceLabel": "pending-device",
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
  "chatCommandDiscoveryPrompt": "Try `/new`, `/status`, `/model`, `/think`, or `/help` to see how commands behave.",
  "connectionButtonLabel": "Connection",
  "connectionConnectingTitle": "Connecting to gateway…",
  "connectionStartTitle": "Connect to gateway to start chatting.",
  "connectionRetrySubtitle": "Check your gateway settings and tap Connection to retry.",
  "connectionStatusSubtitle": "Status: {phase}.",
  "@connectionStatusSubtitle": {
    "placeholders": {
      "phase": {}
    }
  },
  "addImagesTooltip": "Add images",
  "messageHint": "Message Cici",
  "composerModeHint": "Type a message or start with / to run a command.",
  "sendLabel": "Send",
  "sendingLabel": "Sending...",
  "streamingResponseLabel": "Streaming response",
  "pickerErrorChannel": "Image picker is not fully registered yet. Fully restart the app and try again.",
  "pickerErrorUnavailable": "The image picker plugin is unavailable. Fully restart the app and try again.",
  "pickerErrorGeneric": "Picking images failed. Please try again.",
  "blockedReasonNotReady": "connection not ready",
  "blockedReasonMissingWriteScope": "missing scope: operator.write",
  "gatewayFailureNotConfigured": "Gateway is not configured yet.",
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
  "phaseFailed": "Failed",
  "commandGroupSessionLabel": "Session commands",
  "commandGroupStatusLabel": "Status & help",
  "commandGroupSettingsLabel": "Model & settings",
  "commandDescriptionNew": "Start a new session",
  "commandDescriptionStatus": "Check current session health",
  "commandDescriptionModel": "Inspect or switch models",
  "commandDescriptionThink": "Adjust the model's thinking depth",
  "commandDescriptionHelp": "See available help topics",
  "commandDescriptionReset": "Alias of /new",
  "commandDescriptionCompact": "Condense the current context",
  "commandDescriptionStop": "Stop the current response",
  "commandDescriptionFast": "Toggle faster response mode",
  "semanticHintGatewayStandalone": "This will be sent as a Gateway command.",
  "semanticHintInlineDirective": "This inline directive applies only to this message.",
  "semanticHintStandaloneRecommended": "This command is usually sent on its own.",
  "semanticHintLocalClear": "`/clear` is a local app command."
}
```

Update `lib/l10n/app_zh.arb`:

```json
{
  "@@locale": "zh",
  "appTitle": "Cici",
  "chatScreenTitle": "Cici",
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
  "pendingDeviceLabel": "设备准备中",
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
  "chatCommandDiscoveryPrompt": "试试 `/new`、`/status`、`/model`、`/think` 或 `/help` 来了解命令。",
  "connectionButtonLabel": "连接",
  "connectionConnectingTitle": "正在连接 Gateway…",
  "connectionStartTitle": "连接 Gateway 后即可开始聊天。",
  "connectionRetrySubtitle": "检查网关设置后，点击“连接”重试。",
  "connectionStatusSubtitle": "当前状态：{phase}。",
  "@connectionStatusSubtitle": {
    "placeholders": {
      "phase": {}
    }
  },
  "addImagesTooltip": "添加图片",
  "messageHint": "向 Cici 发送消息",
  "composerModeHint": "输入消息或以 / 开头使用命令。",
  "sendLabel": "发送",
  "sendingLabel": "发送中…",
  "streamingResponseLabel": "正在流式返回",
  "pickerErrorChannel": "图片选择器尚未完成原生注册，请完整重启应用后再试。",
  "pickerErrorUnavailable": "图片选择器插件不可用，请完整重启应用后再试。",
  "pickerErrorGeneric": "选择图片失败，请稍后重试。",
  "blockedReasonNotReady": "连接尚未就绪。",
  "blockedReasonMissingWriteScope": "缺少权限：operator.write。",
  "gatewayFailureNotConfigured": "Gateway 尚未配置完成。",
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
  "phaseFailed": "失败",
  "commandGroupSessionLabel": "会话命令",
  "commandGroupStatusLabel": "状态与帮助",
  "commandGroupSettingsLabel": "模型与设置",
  "commandDescriptionNew": "开启一个新会话",
  "commandDescriptionStatus": "查看当前会话状态",
  "commandDescriptionModel": "查看或切换模型",
  "commandDescriptionThink": "调整模型的思考深度",
  "commandDescriptionHelp": "查看可用帮助",
  "commandDescriptionReset": "等同于 /new",
  "commandDescriptionCompact": "压缩当前上下文",
  "commandDescriptionStop": "停止当前回复",
  "commandDescriptionFast": "切换快速响应模式",
  "semanticHintGatewayStandalone": "这会作为 Gateway 命令发送。",
  "semanticHintInlineDirective": "检测到的内联指令仅影响当前消息。",
  "semanticHintStandaloneRecommended": "该命令通常单独发送。",
  "semanticHintLocalClear": "`/clear` 是本地客户端命令。"
}
```

- [ ] **Step 4: Regenerate checked-in localization outputs**

Run: `flutter gen-l10n`
Expected: PASS and update `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, and `lib/l10n/app_localizations_zh.dart`.

- [ ] **Step 5: Run the widget test again**

Run: `flutter test test/widget_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_zh.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_zh.dart test/widget_test.dart
git commit -m "feat: rename in-app title strings to cici"
```

## Task 2: Update Mobile And Web Display Metadata

**Files:**
- Modify: `flutter_openclaw/android/app/src/main/AndroidManifest.xml`
- Modify: `flutter_openclaw/ios/Runner/Info.plist`
- Modify: `flutter_openclaw/web/index.html`
- Modify: `flutter_openclaw/web/manifest.json`
- Create: `flutter_openclaw/test/tool/user_visible_app_name_metadata_test.dart`

- [ ] **Step 1: Add a failing metadata verification test**

Create `test/tool/user_visible_app_name_metadata_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile and web metadata expose Cici', () {
    final androidManifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(androidManifest, contains('android:label="Cici"'));

    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();
    expect(iosInfo, contains('<key>CFBundleDisplayName</key>'));
    expect(iosInfo, contains('<string>Cici</string>'));

    final webIndex = File('web/index.html').readAsStringSync();
    expect(webIndex, contains('<meta name="apple-mobile-web-app-title" content="Cici">'));
    expect(webIndex, contains('<title>Cici</title>'));

    final webManifest = File('web/manifest.json').readAsStringSync();
    expect(webManifest, contains('"name": "Cici"'));
    expect(webManifest, contains('"short_name": "Cici"'));
  });
}
```

- [ ] **Step 2: Run the metadata verification test to confirm it fails**

Run: `flutter test test/tool/user_visible_app_name_metadata_test.dart`
Expected: FAIL because the metadata still uses `flutter_openclaw` or `OpenClaw`.

- [ ] **Step 3: Update Android, iOS, and web user-visible names**

Update `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:label="Cici"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:usesCleartextTraffic="true">
```

Update `ios/Runner/Info.plist`:

```xml
	<key>CFBundleDisplayName</key>
	<string>Cici</string>
```

Update `web/index.html`:

```html
  <meta name="description" content="Cici, your OpenClaw-powered assistant.">

  <!-- iOS meta tags & icons -->
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Cici">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">

  <!-- Favicon -->
  <link rel="icon" type="image/png" href="favicon.png"/>

  <title>Cici</title>
```

Update `web/manifest.json`:

```json
{
  "name": "Cici",
  "short_name": "Cici",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#0E1B2D",
  "theme_color": "#0E1B2D",
  "description": "Cici, your OpenClaw-powered assistant.",
  "orientation": "portrait-primary",
  "prefer_related_applications": false,
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-maskable-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable"
    },
    {
      "src": "icons/Icon-maskable-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ]
}
```

- [ ] **Step 4: Re-run the metadata verification test**

Run: `flutter test test/tool/user_visible_app_name_metadata_test.dart`
Expected: PASS for Android, iOS, and web checks.

- [ ] **Step 5: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist web/index.html web/manifest.json test/tool/user_visible_app_name_metadata_test.dart
git commit -m "feat: rename mobile and web app metadata to cici"
```

## Task 3: Update Desktop Visible Names Without Renaming Internal IDs

**Files:**
- Modify: `flutter_openclaw/macos/Runner/Configs/AppInfo.xcconfig`
- Modify: `flutter_openclaw/windows/runner/main.cpp`
- Modify: `flutter_openclaw/windows/runner/Runner.rc`
- Modify: `flutter_openclaw/test/tool/user_visible_app_name_metadata_test.dart`

- [ ] **Step 1: Extend the metadata verification test for desktop-facing names**

Update `test/tool/user_visible_app_name_metadata_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile and web metadata expose Cici', () {
    final androidManifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(androidManifest, contains('android:label="Cici"'));

    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();
    expect(iosInfo, contains('<key>CFBundleDisplayName</key>'));
    expect(iosInfo, contains('<string>Cici</string>'));

    final webIndex = File('web/index.html').readAsStringSync();
    expect(webIndex, contains('<meta name="apple-mobile-web-app-title" content="Cici">'));
    expect(webIndex, contains('<title>Cici</title>'));

    final webManifest = File('web/manifest.json').readAsStringSync();
    expect(webManifest, contains('"name": "Cici"'));
    expect(webManifest, contains('"short_name": "Cici"'));

    final macAppInfo =
        File('macos/Runner/Configs/AppInfo.xcconfig').readAsStringSync();
    expect(macAppInfo, contains('PRODUCT_NAME = Cici'));

    final windowsMain = File('windows/runner/main.cpp').readAsStringSync();
    expect(windowsMain, contains('window.Create(L"Cici"'));

    final windowsResources =
        File('windows/runner/Runner.rc').readAsStringSync();
    expect(windowsResources, contains('VALUE "FileDescription", "Cici"'));
    expect(windowsResources, contains('VALUE "ProductName", "Cici"'));
    expect(windowsResources, contains('VALUE "InternalName", "flutter_openclaw"'));
    expect(
      windowsResources,
      contains('VALUE "OriginalFilename", "flutter_openclaw.exe"'),
    );
  });
}
```

- [ ] **Step 2: Run the metadata test to confirm desktop names still fail**

Run: `flutter test test/tool/user_visible_app_name_metadata_test.dart`
Expected: FAIL because macOS and Windows metadata still expose `flutter_openclaw`.

- [ ] **Step 3: Update macOS and Windows visible naming only**

Update `macos/Runner/Configs/AppInfo.xcconfig`:

```xcconfig
// The application's name. By default this is also the title of the Flutter window.
PRODUCT_NAME = Cici
```

Update `windows/runner/main.cpp`:

```cpp
  if (!window.Create(L"Cici", origin, size)) {
    return EXIT_FAILURE;
  }
```

Update `windows/runner/Runner.rc`:

```rc
            VALUE "CompanyName", "com.cw.claw" "\0"
            VALUE "FileDescription", "Cici" "\0"
            VALUE "FileVersion", VERSION_AS_STRING "\0"
            VALUE "InternalName", "flutter_openclaw" "\0"
            VALUE "LegalCopyright", "Copyright (C) 2026 com.cw.claw. All rights reserved." "\0"
            VALUE "OriginalFilename", "flutter_openclaw.exe" "\0"
            VALUE "ProductName", "Cici" "\0"
            VALUE "ProductVersion", VERSION_AS_STRING "\0"
```

- [ ] **Step 4: Run the metadata verification test again**

Run: `flutter test test/tool/user_visible_app_name_metadata_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add macos/Runner/Configs/AppInfo.xcconfig windows/runner/main.cpp windows/runner/Runner.rc test/tool/user_visible_app_name_metadata_test.dart
git commit -m "feat: rename desktop-facing app name to cici"
```
