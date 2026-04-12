# Flutter OpenClaw Settings Copy Actions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add elegant one-tap copy actions for device ID and granted scopes in the settings connection summary, with lightweight success feedback.

**Architecture:** Keep the change inside the presentation layer by enhancing the existing summary-tile widget to optionally support a trailing copy action. Add small localization strings for copy tooltips and success feedback, then wire clipboard writes and `SnackBar` feedback directly from the widget.

**Tech Stack:** Flutter, Material 3, `Clipboard`, app localization

---

### Task 1: Add localized copy labels and feedback strings

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_zh.arb`
- Modify: `lib/l10n/app_localizations.dart`
- Modify: `lib/l10n/app_localizations_en.dart`
- Modify: `lib/l10n/app_localizations_zh.dart`

- [ ] **Step 1: Add English localization entries**

```json
"copyValueTooltip": "Copy",
"copiedDeviceIdMessage": "Copied device ID",
"copiedGrantedScopesMessage": "Copied granted scopes",
```

- [ ] **Step 2: Add Chinese localization entries**

```json
"copyValueTooltip": "复制",
"copiedDeviceIdMessage": "已复制设备 ID",
"copiedGrantedScopesMessage": "已复制已授予权限",
```

- [ ] **Step 3: Mirror the new getters in generated localization classes**

```dart
/// In `app_localizations.dart`
String get copyValueTooltip;
String get copiedDeviceIdMessage;
String get copiedGrantedScopesMessage;
```

```dart
/// In `app_localizations_en.dart`
@override
String get copyValueTooltip => 'Copy';

@override
String get copiedDeviceIdMessage => 'Copied device ID';

@override
String get copiedGrantedScopesMessage => 'Copied granted scopes';
```

```dart
/// In `app_localizations_zh.dart`
@override
String get copyValueTooltip => '复制';

@override
String get copiedDeviceIdMessage => '已复制设备 ID';

@override
String get copiedGrantedScopesMessage => '已复制已授予权限';
```

- [ ] **Step 4: Review the string set for consistency**

Check that:
- tooltip text is generic
- success text is field-specific
- English and Chinese wording both match the approved design

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_zh.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_zh.dart
git commit -m "feat: add localization for settings copy actions"
```

### Task 2: Add copy affordances to the connection summary card

**Files:**
- Modify: `lib/src/presentation/widgets/connection_summary_card.dart`

- [ ] **Step 1: Import clipboard support**

```dart
import 'package:flutter/services.dart';
```

- [ ] **Step 2: Extend the summary tile API for optional copy actions**

```dart
class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    this.isWide = false,
    this.copyValue,
    this.copiedMessage,
  });

  final String label;
  final String value;
  final bool isWide;
  final String? copyValue;
  final String? copiedMessage;
}
```

- [ ] **Step 3: Wire copy-enabled tiles from `ConnectionSummaryCard`**

```dart
_SummaryTile(
  label: l10n.deviceIdLabel,
  value: deviceId,
  copyValue: deviceId,
  copiedMessage: l10n.copiedDeviceIdMessage,
),
_SummaryTile(
  label: l10n.grantedScopesLabel,
  value: scopes.isEmpty ? l10n.noneLabel : scopes.join(', '),
  isWide: true,
  copyValue: scopes.isEmpty ? l10n.noneLabel : scopes.join(', '),
  copiedMessage: l10n.copiedGrantedScopesMessage,
),
```

- [ ] **Step 4: Render a lightweight trailing copy icon and success feedback**

```dart
final l10n = AppLocalizations.of(context)!;
final canCopy = copyValue != null && copiedMessage != null;

Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      child: Text(
        value,
        style: theme.textTheme.bodyMedium,
      ),
    ),
    if (canCopy) ...[
      const SizedBox(width: 8),
      IconButton(
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: copyValue!));
          if (!context.mounted) {
            return;
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(copiedMessage!),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
        },
        tooltip: l10n.copyValueTooltip,
        visualDensity: VisualDensity.compact,
        splashRadius: 18,
        iconSize: 18,
        color: theme.colorScheme.onSurfaceVariant,
        icon: const Icon(Icons.content_copy_rounded),
      ),
    ],
  ],
),
```

- [ ] **Step 5: Keep phase display-only**

Leave this tile unchanged:

```dart
_SummaryTile(
  label: l10n.phaseLabel,
  value: localizedPhaseLabel(l10n, phase),
),
```

- [ ] **Step 6: Commit**

```bash
git add lib/src/presentation/widgets/connection_summary_card.dart
git commit -m "feat: add copy actions to settings summary"
```

### Task 3: Final review without automated verification

**Files:**
- Modify: `lib/src/presentation/widgets/connection_summary_card.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_zh.arb`
- Modify: `lib/l10n/app_localizations.dart`
- Modify: `lib/l10n/app_localizations_en.dart`
- Modify: `lib/l10n/app_localizations_zh.dart`

- [ ] **Step 1: Inspect layout details manually in code**

Check these points in the final diff:
- copy icon is only present on device ID and granted scopes
- icon sits at the trailing edge of the value row
- long values still use `Expanded`
- phase tile remains unchanged

- [ ] **Step 2: Inspect feedback details manually in code**

Check these points in the final diff:
- clipboard writes use the value shown to the user
- `SnackBar` message is field-specific
- `SnackBar` is floating and short-lived
- a second tap replaces the previous success message cleanly

- [ ] **Step 3: Inspect localization coverage manually in code**

Check these points in the final diff:
- English and Chinese both include tooltip and success strings
- getter names match across all localization files
- no old string names are reused incorrectly

- [ ] **Step 4: Commit**

```bash
git add lib/src/presentation/widgets/connection_summary_card.dart lib/l10n/app_en.arb lib/l10n/app_zh.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_zh.dart
git commit -m "refactor: polish settings copy feedback"
```
