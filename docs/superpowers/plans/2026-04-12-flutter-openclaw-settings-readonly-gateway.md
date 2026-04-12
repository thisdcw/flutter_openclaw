# Flutter OpenClaw Settings Readonly Gateway Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Separate app language into a basic-settings card and make gateway configuration read-only without a save action.

**Architecture:** Keep the change in the presentation layer. Rework the settings screen into two cards, simplify the settings form to only own app-language controls, and cover the new structure with a widget test before changing implementation.

**Tech Stack:** Flutter, Material 3 widgets, flutter_test

---

### Task 1: Protect the new settings information architecture with a widget test

**Files:**
- Modify: `test/widget_test.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('settings screen separates basic settings from readonly gateway details',
    (WidgetTester tester) async {
  final dependencies = AppDependencies.fake();

  await tester.pumpWidget(
    OpenClawApp(dependencies: dependencies),
  );

  await tester.tap(find.byTooltip('Open settings'));
  await tester.pumpAndSettle();

  expect(find.text('Basic Settings'), findsOneWidget);
  expect(find.text('App Language'), findsOneWidget);
  expect(find.text('Gateway Configuration'), findsOneWidget);
  expect(find.text('Save Settings'), findsNothing);
  expect(find.byType(TextField), findsNothing);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because the current settings screen still renders gateway form fields and a save action.

- [ ] **Step 3: Write minimal implementation**

```dart
// Update the settings screen so it renders:
// - a basic-settings card with the locale dropdown
// - a readonly gateway-details card with plain text rows
// - no save button and no editable gateway text fields
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/widget_test.dart lib/src/presentation/screens/settings_screen.dart lib/src/presentation/widgets/settings_form.dart
git commit -m "feat: simplify settings information architecture"
```

### Task 2: Restructure the settings UI with clear card boundaries

**Files:**
- Modify: `lib/src/presentation/screens/settings_screen.dart`
- Modify: `lib/src/presentation/widgets/settings_form.dart`

- [ ] **Step 1: Write the failing test**

```dart
// Re-run the same widget test after confirming the old UI still fails it.
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL on the pre-change layout.

- [ ] **Step 3: Write minimal implementation**

```dart
// In SettingsScreen:
// - remove gateway TextEditingController usage
// - add a basic settings card around SettingsForm
// - keep a gateway card with readonly detail rows
//
// In SettingsForm:
// - keep only the locale dropdown
// - remove gateway locale, timeout, session, and save button UI
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/widget_test.dart lib/src/presentation/screens/settings_screen.dart lib/src/presentation/widgets/settings_form.dart
git commit -m "feat: make gateway settings readonly"
```

### Task 3: Verify no regression in the touched presentation flow

**Files:**
- Modify: `test/widget_test.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// If needed, tighten the settings test assertions so it checks for the
// locale dropdown plus readonly gateway values by label.
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL until the assertions and implementation align.

- [ ] **Step 3: Write minimal implementation**

```dart
// Adjust labels or readonly rows so the final settings structure is explicit
// and testable without depending on fragile widget internals.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS with the new settings assertions plus existing chat tests still green.

- [ ] **Step 5: Commit**

```bash
git add test/widget_test.dart lib/src/presentation/screens/settings_screen.dart lib/src/presentation/widgets/settings_form.dart
git commit -m "test: cover readonly settings layout"
```
