# Flutter OpenClaw Chat Reset And Pairing Guidance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `/new` clear local chat history, hide `/model` and `/think` from command discovery, and replace reconnect with pairing guidance for `"no pair"` style failures.

**Architecture:** Keep the reset behavior in `ChatController`, keep command visibility changes in the command assist presentation layer, and let pairing guidance be driven by gateway failure classification plus chat-screen rendering rules. This keeps each change close to its existing responsibility and avoids introducing a second command or failure mapping path.

**Tech Stack:** Flutter, Dart, flutter_test, generated l10n

---

### Task 1: Lock `/new` Reset Behavior With Tests

**Files:**
- Modify: `test/application/chat_controller_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
test('clears local history before adding a new /new command message', () async {
  final controller = ChatController.fake();

  await controller.send(ChatDraft(text: 'hello', attachments: const []));
  await controller.send(ChatDraft(text: '/new', attachments: const []));

  expect(controller.messages, hasLength(1));
  expect(controller.messages.single.text, '/new');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/application/chat_controller_test.dart`
Expected: FAIL because the prior `hello` message is still present.

- [ ] **Step 3: Write minimal implementation**

```dart
if (normalized == '/new') {
  _messages.clear();
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/application/chat_controller_test.dart`
Expected: PASS

### Task 2: Lock Hidden Command Visibility

**Files:**
- Create: `test/presentation/chat_command_assist_test.dart`
- Modify: `lib/src/presentation/widgets/chat_command_assist.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_zh.arb`

- [ ] **Step 1: Write the failing tests**

```dart
test('slash suggestions hide model and think commands', () {
  final commands = filterSlashSuggestions('/').map((entry) => entry.command).toList();

  expect(commands, isNot(contains('/model')));
  expect(commands, isNot(contains('/think')));
});

test('discovery commands hide model and think commands', () {
  final commands = discoveryCommands.map((entry) => entry.command).toList();

  expect(commands, isNot(contains('/model')));
  expect(commands, isNot(contains('/think')));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/chat_command_assist_test.dart`
Expected: FAIL because both commands are still returned.

- [ ] **Step 3: Write minimal implementation**

```dart
final List<ChatCommandSuggestion> discoveryCommands = const [
  // keep /new, /status, /help
];

final List<ChatCommandSuggestion> slashSuggestionCandidates = const [
  // remove /model and /think
];
```

- [ ] **Step 4: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: SUCCESS and generated localization files update with the revised discovery prompt copy.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/presentation/chat_command_assist_test.dart`
Expected: PASS

### Task 3: Lock Pairing Guidance Behavior

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `lib/src/domain/models/gateway_failure.dart`
- Modify: `lib/src/infrastructure/util/failure_mapper.dart`
- Modify: `lib/src/presentation/screens/chat_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_zh.arb`

- [ ] **Step 1: Write the failing widget test**

```dart
testWidgets('no pair failure shows settings guidance and hides reconnect button',
    (WidgetTester tester) async {
  final connectionController = ConnectionController.fake()
    ..markFailed('no pair');

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChatScreen(
        chatController: ChatController.fake(),
        connectionController: connectionController,
      ),
    ),
  );

  expect(find.text('Go to Settings, copy the device ID, and send it to an administrator for authorization.'), findsOneWidget);
  expect(find.text('Connection'), findsNothing);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because `"no pair"` is treated like a generic retryable failure.

- [ ] **Step 3: Write minimal implementation**

```dart
if (normalizedReason.contains('no pair')) {
  return GatewayFailureType.pairingRequired;
}
```

```dart
final isPairingFailure =
    connectionStatus.failure?.type == GatewayFailureType.pairingRequired;
```

```dart
showButton: !isConnecting && !isPairingFailure,
```

- [ ] **Step 4: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: SUCCESS and generated localization files include the new pairing guidance subtitle.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/widget_test.dart`
Expected: PASS

### Task 4: Final Verification

**Files:**
- Verify only

- [ ] **Step 1: Run focused verification**

Run: `flutter test test/application/chat_controller_test.dart test/presentation/chat_command_assist_test.dart test/widget_test.dart`
Expected: PASS

- [ ] **Step 2: Review diff**

Run: `git diff -- docs/superpowers/specs/2026-04-12-flutter-openclaw-chat-reset-and-pairing-guidance-design.md docs/superpowers/plans/2026-04-12-flutter-openclaw-chat-reset-and-pairing-guidance.md lib/src/application/controllers/chat_controller.dart lib/src/presentation/widgets/chat_command_assist.dart lib/src/presentation/screens/chat_screen.dart lib/src/domain/models/gateway_failure.dart lib/src/infrastructure/util/failure_mapper.dart lib/l10n/app_en.arb lib/l10n/app_zh.arb test/application/chat_controller_test.dart test/presentation/chat_command_assist_test.dart test/widget_test.dart`
Expected: Diff shows only the planned chat reset, hidden command, pairing guidance, and docs changes.
