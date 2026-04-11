# Flutter OpenClaw UI Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refresh the Flutter OpenClaw settings and chat UI so it feels like a polished AI assistant app without changing any existing feature behavior.

**Architecture:** Keep all changes inside the theme and presentation layer. Build one coherent soft-futurist design system in `app_theme.dart`, then update the settings and chat surfaces to consume that system while preserving all current controller callbacks and state-driven rendering.

**Tech Stack:** Flutter, Dart, Material 3, `flutter_test`

---

## File Structure

- Modify: `flutter_openclaw/lib/src/app/app_theme.dart`
  Define the new cool-toned palette, typography, shapes, card treatment, button styling, chip styling, and input styling.
- Modify: `flutter_openclaw/lib/src/presentation/screens/settings_screen.dart`
  Recompose the settings surface into hero, connection overview, configuration card, and primary chat entry.
- Modify: `flutter_openclaw/lib/src/presentation/widgets/connection_summary_card.dart`
  Turn the plain summary into a stronger status panel.
- Modify: `flutter_openclaw/lib/src/presentation/widgets/settings_form.dart`
  Restyle fields and action layout without changing callbacks or field semantics.
- Modify: `flutter_openclaw/lib/src/presentation/screens/chat_screen.dart`
  Upgrade top bar, banners, empty state, transcript framing, and input dock.
- Modify: `flutter_openclaw/lib/src/presentation/widgets/status_badge.dart`
  Replace the default `Chip` feel with a status pill.
- Modify: `flutter_openclaw/lib/src/presentation/widgets/message_bubble.dart`
  Differentiate user, assistant, error, and streaming states.
- Modify: `flutter_openclaw/lib/src/presentation/widgets/chat_composer.dart`
  Convert the basic row into an assistant-style composer surface.
- Modify: `flutter_openclaw/test/widget_test.dart`
  Update widget expectations to match the refreshed copy and layout while preserving blocked-send coverage.

## Task 1: Lock The New Theme And Settings-Screen Expectations

**Files:**
- Modify: `flutter_openclaw/lib/src/app/app_theme.dart`
- Modify: `flutter_openclaw/test/widget_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
testWidgets('settings screen shows the AI assistant hero copy',
    (WidgetTester tester) async {
  await tester.pumpWidget(OpenClawApp(dependencies: AppDependencies.fake()));

  expect(find.text('OpenClaw Assistant'), findsOneWidget);
  expect(
    find.text('Connect your gateway and start chatting with OpenClaw.'),
    findsOneWidget,
  );
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because the current screen still renders `OpenClaw Gateway`.

- [ ] **Step 3: Replace the theme with the soft-futurist design system**

Use these values in `flutter_openclaw/lib/src/app/app_theme.dart`:

```dart
const background = Color(0xFFF3F7FC);
const surface = Color(0xFFFDFEFF);
const surfaceStrong = Color(0xFFF2F7FF);
const ink = Color(0xFF142033);
const mutedInk = Color(0xFF5C6B80);
const primary = Color(0xFF2F6BFF);
const secondary = Color(0xFF5BC7FF);
const outline = Color(0xFFD6E3F5);
```

```dart
inputDecorationTheme: InputDecorationTheme(
  filled: true,
  fillColor: surfaceStrong,
  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: const BorderSide(color: outline),
  ),
),
```

```dart
filledButtonTheme: FilledButtonThemeData(
  style: FilledButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
  ),
),
```

- [ ] **Step 4: Run test to verify the remaining failure is only missing hero content**

Run: `flutter test test/widget_test.dart`
Expected: FAIL on missing text, with no new theme compilation errors.

- [ ] **Step 5: Commit**

```bash
git add lib/src/app/app_theme.dart test/widget_test.dart
git commit -m "feat: add openclaw ai assistant theme system"
```

## Task 2: Refresh The Settings Experience Without Changing Behavior

**Files:**
- Modify: `flutter_openclaw/lib/src/presentation/screens/settings_screen.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/connection_summary_card.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/settings_form.dart`
- Modify: `flutter_openclaw/test/widget_test.dart`

- [ ] **Step 1: Expand the settings widget test**

```dart
testWidgets('settings screen shows the refreshed AI assistant layout',
    (WidgetTester tester) async {
  await tester.pumpWidget(OpenClawApp(dependencies: AppDependencies.fake()));

  expect(find.text('OpenClaw Assistant'), findsOneWidget);
  expect(find.text('Gateway Configuration'), findsOneWidget);
  expect(find.text('Connection Overview'), findsOneWidget);
  expect(find.text('Open Chat'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because the settings screen still uses the old stacked layout.

- [ ] **Step 3: Recompose the settings screen around four sections**

Use this structure in `flutter_openclaw/lib/src/presentation/screens/settings_screen.dart`:

```dart
ListView(
  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
  children: [
    _HeroCard(
      title: 'OpenClaw Assistant',
      subtitle: 'Connect your gateway and start chatting with OpenClaw.',
      phase: connectionController.phase,
      sessionId: sessionIdController.text,
    ),
    const SizedBox(height: 18),
    ConnectionSummaryCard(
      phase: connectionController.phase,
      deviceId: deviceId,
      scopes: connectionController.grantedScopes,
    ),
    const SizedBox(height: 18),
    Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gateway Configuration', style: theme.textTheme.titleLarge),
            const SizedBox(height: 18),
            SettingsForm(
              gatewayUrlController: gatewayUrlController,
              authTokenController: authTokenController,
              sessionIdController: sessionIdController,
              localeController: localeController,
              timeoutController: timeoutController,
              onSave: _saveSettings,
              onTestConnection: _testConnection,
              onClearDeviceToken: _clearDeviceToken,
              onResetDeviceIdentity: _resetDeviceIdentity,
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 18),
    FilledButton.icon(
      onPressed: _openChat,
      icon: const Icon(Icons.auto_awesome_rounded),
      label: const Text('Open Chat'),
    ),
  ],
)
```

- [ ] **Step 4: Upgrade the summary card and form styling only**

Use this shape in `flutter_openclaw/lib/src/presentation/widgets/connection_summary_card.dart`:

```dart
Text('Connection Overview', style: theme.textTheme.titleLarge),
const SizedBox(height: 18),
Wrap(
  spacing: 12,
  runSpacing: 12,
  children: [
    _SummaryTile(label: 'Phase', value: phase),
    _SummaryTile(label: 'Device ID', value: deviceId),
    _SummaryTile(
      label: 'Granted Scopes',
      value: scopes.isEmpty ? '(none)' : scopes.join(', '),
      isWide: true,
    ),
  ],
),
```

Use this action layout in `flutter_openclaw/lib/src/presentation/widgets/settings_form.dart`:

```dart
Wrap(
  spacing: 12,
  runSpacing: 12,
  children: [
    FilledButton.icon(
      onPressed: () { onSave(); },
      icon: const Icon(Icons.save_rounded),
      label: const Text('Save Settings'),
    ),
    FilledButton.tonalIcon(
      onPressed: () { onTestConnection(); },
      icon: const Icon(Icons.wifi_tethering_rounded),
      label: const Text('Test Connection'),
    ),
    OutlinedButton(
      onPressed: () { onClearDeviceToken(); },
      child: const Text('Clear Device Token'),
    ),
    OutlinedButton(
      onPressed: () { onResetDeviceIdentity(); },
      child: const Text('Reset Device Identity'),
    ),
  ],
),
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS for the refreshed settings layout test and the existing blocked-send coverage.

- [ ] **Step 6: Commit**

```bash
git add lib/src/presentation/screens/settings_screen.dart lib/src/presentation/widgets/connection_summary_card.dart lib/src/presentation/widgets/settings_form.dart test/widget_test.dart
git commit -m "feat: refresh openclaw settings assistant surface"
```

## Task 3: Refresh The Chat Surface And Empty State

**Files:**
- Modify: `flutter_openclaw/lib/src/presentation/screens/chat_screen.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/status_badge.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/message_bubble.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/chat_composer.dart`
- Modify: `flutter_openclaw/test/widget_test.dart`

- [ ] **Step 1: Add the failing chat empty-state test**

```dart
testWidgets('chat screen shows assistant empty state copy',
    (WidgetTester tester) async {
  final connectionController = ConnectionController.fake()
    ..phase = 'ready'
    ..grantedScopes = ['operator.read', 'operator.write'];
  final chatController = ChatController.fake();

  await tester.pumpWidget(
    MaterialApp(
      home: ChatScreen(
        chatController: chatController,
        connectionController: connectionController,
      ),
    ),
  );

  expect(find.text('Ask anything once your gateway is ready.'), findsOneWidget);
  expect(find.text('No messages yet.'), findsNothing);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because the current chat screen still shows `No messages yet.`

- [ ] **Step 3: Upgrade the chat widgets with assistant-style presentation**

Use this structure in `flutter_openclaw/lib/src/presentation/widgets/status_badge.dart`:

```dart
final background = lower == 'ready'
    ? const Color(0xFFE4F7EC)
    : lower.contains('fail')
        ? theme.colorScheme.errorContainer
        : const Color(0xFFEAF2FF);
```

```dart
return Container(
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  decoration: BoxDecoration(
    color: background,
    borderRadius: BorderRadius.circular(999),
  ),
  child: Text(
    label,
    style: theme.textTheme.labelMedium?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w700,
    ),
  ),
);
```

Use this message treatment in `flutter_openclaw/lib/src/presentation/widgets/message_bubble.dart`:

```dart
final backgroundColor = isError
    ? theme.colorScheme.errorContainer
    : isUser
        ? theme.colorScheme.primary
        : Colors.white;
```

```dart
borderRadius: BorderRadius.only(
  topLeft: const Radius.circular(24),
  topRight: const Radius.circular(24),
  bottomLeft: Radius.circular(isUser ? 24 : 8),
  bottomRight: Radius.circular(isUser ? 8 : 24),
),
```

Use this dock in `flutter_openclaw/lib/src/presentation/widgets/chat_composer.dart`:

```dart
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.92),
    borderRadius: BorderRadius.circular(26),
    border: Border.all(color: theme.colorScheme.outline),
  ),
  child: Row(
    children: [
      Expanded(
        child: TextField(
          controller: controller,
          enabled: enabled && !isSending,
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Message OpenClaw',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
        ),
      ),
      FilledButton.icon(
        onPressed: enabled && !isSending ? () { onSend(); } : null,
        icon: const Icon(Icons.arrow_upward_rounded),
        label: Text(isSending ? 'Sending' : 'Send'),
      ),
    ],
  ),
)
```

- [ ] **Step 4: Recompose the chat screen with banners, framed transcript, and empty state**

Use this structure in `flutter_openclaw/lib/src/presentation/screens/chat_screen.dart`:

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    if (blockedReason.isNotEmpty)
      _ChatBanner(
        message: blockedReason,
        color: const Color(0xFFFFF2D9),
        textColor: const Color(0xFF8A5A00),
      ),
    if ((widget.chatController.errorMessage ?? '').isNotEmpty)
      _ChatBanner(
        message: widget.chatController.errorMessage!,
        color: theme.colorScheme.errorContainer,
        textColor: theme.colorScheme.onErrorContainer,
      ),
    Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.72),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: messages.isEmpty
            ? const _ChatEmptyState()
            : ListView.separated(
                itemCount: messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return MessageBubble(message: messages[index]);
                },
              ),
      ),
    ),
    const SizedBox(height: 14),
    ChatComposer(
      controller: composerController,
      enabled: widget.connectionController.canSend,
      isSending: widget.chatController.isSending,
      onSend: () async {
        await widget.chatController.send(composerController.text);
        composerController.clear();
      },
    ),
  ],
)
```

Use this empty-state copy:

```dart
Text('Ask anything once your gateway is ready.')
Text(
  'Your assistant replies will stream here as soon as the connection is ready and operator.write is available.',
)
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS for settings, blocked-send, and assistant empty-state coverage.

- [ ] **Step 6: Commit**

```bash
git add lib/src/presentation/screens/chat_screen.dart lib/src/presentation/widgets/status_badge.dart lib/src/presentation/widgets/message_bubble.dart lib/src/presentation/widgets/chat_composer.dart test/widget_test.dart
git commit -m "feat: refresh openclaw chat assistant surface"
```

## Task 4: Verify That The Refresh Stayed Presentation-Only

**Files:**
- Modify: `flutter_openclaw/lib/src/app/app_theme.dart`
- Modify: `flutter_openclaw/lib/src/presentation/screens/settings_screen.dart`
- Modify: `flutter_openclaw/lib/src/presentation/screens/chat_screen.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/connection_summary_card.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/settings_form.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/status_badge.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/message_bubble.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/chat_composer.dart`
- Modify: `flutter_openclaw/test/widget_test.dart`

- [ ] **Step 1: Run analysis**

Run: `flutter analyze`
Expected: No analysis errors.

- [ ] **Step 2: Run tests**

Run: `flutter test`
Expected: All existing tests PASS, proving the refresh did not break controller-driven behavior.

- [ ] **Step 3: Inspect the final UI-only diff**

Run: `git diff -- lib/src/app/app_theme.dart lib/src/presentation/screens/settings_screen.dart lib/src/presentation/screens/chat_screen.dart lib/src/presentation/widgets/connection_summary_card.dart lib/src/presentation/widgets/settings_form.dart lib/src/presentation/widgets/status_badge.dart lib/src/presentation/widgets/message_bubble.dart lib/src/presentation/widgets/chat_composer.dart test/widget_test.dart`
Expected: Diff is limited to theme, presentation widgets, screens, and widget expectations.

- [ ] **Step 4: Commit**

```bash
git add lib/src/app/app_theme.dart lib/src/presentation/screens/settings_screen.dart lib/src/presentation/screens/chat_screen.dart lib/src/presentation/widgets/connection_summary_card.dart lib/src/presentation/widgets/settings_form.dart lib/src/presentation/widgets/status_badge.dart lib/src/presentation/widgets/message_bubble.dart lib/src/presentation/widgets/chat_composer.dart test/widget_test.dart
git commit -m "feat: deliver flutter openclaw ai assistant ui refresh"
```

## Plan Self-Review

### Spec Coverage

- Theme refresh and soft-futurist direction: Task 1
- Settings hero, connection overview, configuration card, and primary chat action: Task 2
- Chat badge, banners, transcript frame, empty state, and composer dock: Task 3
- Verification that the work stayed in presentation/theme scope: Task 4

### Placeholder Scan

- No placeholder markers remain
- Each task lists exact files
- Each code step includes concrete snippets
- Each verification step includes exact commands and expected results

### Type Consistency

- `SettingsForm` keeps `Future<void> Function()` callbacks
- `ChatComposer` keeps `isSending` and async `onSend`
- `ConnectionSummaryCard`, `StatusBadge`, and `MessageBubble` continue to consume the same view data as the current implementation
