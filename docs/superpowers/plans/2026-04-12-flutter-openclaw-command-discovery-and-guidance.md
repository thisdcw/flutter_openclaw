# Flutter OpenClaw Command Discovery And Guidance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add lightweight command discovery and guidance to the chat screen so users can discover common OpenClaw commands, get slash suggestions while typing, and see rule-aware command hints before sending.

**Architecture:** Keep all new behavior in the presentation layer. Add a small command-assist helper for metadata and draft analysis, then wire it into the chat empty state and composer so command UX remains lightweight and does not change controller or gateway behavior.

**Tech Stack:** Flutter, Material 3, generated Flutter localization (`arb` + `gen-l10n`)

---

### Task 1: Add localized copy and command-assist metadata

**Files:**
- Create: `lib/src/presentation/widgets/chat_command_assist.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_zh.arb`
- Modify: `lib/l10n/app_localizations.dart`
- Modify: `lib/l10n/app_localizations_en.dart`
- Modify: `lib/l10n/app_localizations_zh.dart`

- [ ] **Step 1: Add the new localized strings to both ARB files**

Add keys for:

- upgraded composer hint
- empty-state command labels and descriptions
- suggestion section labels
- semantic guidance messages

Use concrete keys similar to:

```json
{
  "messageHintWithCommands": "Message OpenClaw or type / for commands",
  "commandGroupSession": "Session",
  "commandGroupStatus": "Status",
  "commandGroupSettings": "Common Settings",
  "commandNewLabel": "/new",
  "commandNewDescription": "Start a new session",
  "commandStatusLabel": "/status",
  "commandStatusDescription": "Check current session state",
  "commandModelDescription": "Switch or inspect model",
  "commandThinkDescription": "Change reasoning depth",
  "commandHelpDescription": "See available help",
  "commandHintStandalone": "This will be sent as a Gateway command.",
  "commandHintDirectiveInline": "Detected an inline directive. It likely applies only to this message.",
  "commandHintStandaloneRecommended": "This command is usually sent as its own message.",
  "commandHintLocalClear": "/clear is a local app command."
}
```

- [ ] **Step 2: Create the command-assist helper**

Add a focused helper that contains:

- the lightweight command catalog
- command grouping data
- prefix filtering
- draft analysis for semantic hints

Use a small API like:

```dart
enum ChatCommandHintKind {
  none,
  standaloneGateway,
  inlineDirective,
  standaloneRecommended,
  localCommand,
}

class ChatCommandSuggestion {
  const ChatCommandSuggestion({
    required this.command,
    required this.groupKey,
    required this.descriptionKey,
    required this.template,
  });

  final String command;
  final String groupKey;
  final String descriptionKey;
  final String template;
}

class ChatCommandAssistResult {
  const ChatCommandAssistResult({
    required this.suggestions,
    required this.hintKind,
  });

  final List<ChatCommandSuggestion> suggestions;
  final ChatCommandHintKind hintKind;
}

ChatCommandAssistResult analyzeChatDraft(String draft) {
  // prefix-only filtering for slash suggestions
  // narrow semantic hints for /clear, standalone commands, and inline directives
}
```

- [ ] **Step 3: Regenerate localization output**

Run:

```bash
flutter gen-l10n
```

Expected:

- `app_localizations.dart`
- `app_localizations_en.dart`
- `app_localizations_zh.dart`

contain getters for the new command guidance strings.

- [ ] **Step 4: Commit the metadata and copy scaffold**

Run:

```bash
git add lib/l10n/app_en.arb lib/l10n/app_zh.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_zh.dart lib/src/presentation/widgets/chat_command_assist.dart
git commit -m "feat: add chat command guidance metadata"
```

### Task 2: Add empty-state command discovery to the chat screen

**Files:**
- Modify: `lib/src/presentation/screens/chat_screen.dart`
- Modify: `lib/src/presentation/widgets/chat_command_assist.dart`

- [ ] **Step 1: Add a command-fill callback in the chat screen state**

Add a small helper so both empty-state chips and composer suggestions can populate the text field without sending:

```dart
void _applyCommandTemplate(String template) {
  composerController.value = TextEditingValue(
    text: template,
    selection: TextSelection.collapsed(offset: template.length),
  );
  FocusScope.of(context).requestFocus(FocusNode());
  setState(() {});
}
```

Refine it so it reuses a persistent `FocusNode` instead of creating one on demand.

- [ ] **Step 2: Replace the plain empty state with command discovery chips**

Pass a command list and callback into `_ChatEmptyState`, then render compact chips under the title/subtitle.

The widget shape should move toward:

```dart
class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({
    required this.l10n,
    required this.discoveryCommands,
    required this.onCommandSelected,
  });

  final AppLocalizations l10n;
  final List<ChatCommandSuggestion> discoveryCommands;
  final ValueChanged<String> onCommandSelected;
}
```

Inside the layout, add a wrapped chip row:

```dart
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    for (final command in discoveryCommands)
      ActionChip(
        label: Text(command.command),
        onPressed: () => onCommandSelected(command.template),
      ),
  ],
)
```

- [ ] **Step 3: Keep the empty state lightweight**

Do not add large cards or a full command drawer. Keep the existing welcome icon/title structure, then add one short line of explanation and the wrapped chips underneath.

Use short secondary text such as:

```dart
Text(
  l10n.chatEmptyCommandPrompt,
  style: theme.textTheme.bodySmall,
  textAlign: TextAlign.center,
)
```

- [ ] **Step 4: Commit the empty-state discovery work**

Run:

```bash
git add lib/src/presentation/screens/chat_screen.dart lib/src/presentation/widgets/chat_command_assist.dart
git commit -m "feat: add empty-state command discovery"
```

### Task 3: Upgrade the composer with slash suggestions and semantic guidance

**Files:**
- Modify: `lib/src/presentation/widgets/chat_composer.dart`
- Modify: `lib/src/presentation/screens/chat_screen.dart`
- Modify: `lib/src/presentation/widgets/chat_command_assist.dart`

- [ ] **Step 1: Expand `ChatComposer` props for command assistance**

Add props for:

- current command suggestions
- current semantic hint
- callback for selecting a suggestion

For example:

```dart
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.enabled,
    required this.hasContent,
    required this.isSending,
    required this.attachments,
    required this.commandSuggestions,
    required this.commandHintKind,
    required this.onSelectCommandSuggestion,
    required this.onPickImages,
    required this.onRemoveAttachment,
    required this.onSend,
  });
}
```

- [ ] **Step 2: Render the semantic guidance banner above the input row**

Add a small tinted guidance container that only appears when the draft analysis returns a non-`none` hint kind.

The widget can stay inline with the existing composer column:

```dart
if (commandHintKind != ChatCommandHintKind.none) ...[
  _ComposerCommandHint(
    text: _hintTextFor(commandHintKind, l10n),
  ),
  const SizedBox(height: 8),
]
```

Keep styling lightweight:

- compact padding
- subtle border
- no danger-red treatment unless the message is actually invalid

- [ ] **Step 3: Render the slash suggestion panel when the draft starts with `/`**

Insert a compact wrapped suggestion surface above the text field when `commandSuggestions.isNotEmpty`.

The rendering shape can be:

```dart
if (commandSuggestions.isNotEmpty) ...[
  _ComposerCommandSuggestions(
    suggestions: commandSuggestions,
    onSelected: onSelectCommandSuggestion,
  ),
  const SizedBox(height: 8),
]
```

Inside the panel:

- show a small section label per group
- render compact chips or pills
- fill the composer with the suggestion template on tap

- [ ] **Step 4: Use the upgraded composer hint**

Change the text field hint from the current single-mode copy to the new dual-mode copy:

```dart
hintText: l10n.messageHintWithCommands,
```

Keep the rest of the input behavior unchanged:

- same send enablement
- same attachment strip
- same send callback

- [ ] **Step 5: Wire command analysis from `ChatScreen` into the composer**

In `build`, derive assist data from the current composer text:

```dart
final commandAssist = analyzeChatDraft(composerController.text);
```

Then pass:

```dart
commandSuggestions: commandAssist.suggestions,
commandHintKind: commandAssist.hintKind,
onSelectCommandSuggestion: _applyCommandTemplate,
```

Also pass the discovery commands to the empty state from the same helper so the command catalog stays consistent.

- [ ] **Step 6: Commit the composer guidance work**

Run:

```bash
git add lib/src/presentation/widgets/chat_composer.dart lib/src/presentation/screens/chat_screen.dart lib/src/presentation/widgets/chat_command_assist.dart
git commit -m "feat: add slash suggestions and command hints"
```

### Task 4: Regenerate outputs and run lightweight verification

**Files:**
- Modify: generated localization files if `gen-l10n` updates them

- [ ] **Step 1: Regenerate localization one more time after final copy changes**

Run:

```bash
flutter gen-l10n
```

Expected:

- localization getters stay in sync with the final ARB contents

- [ ] **Step 2: Run static analysis only**

The user explicitly requested no tests, so do not run or add test cases in this task.

Run:

```bash
flutter analyze
```

Expected:

- no errors from new command-assist code
- no undefined localization getters
- no constructor or parameter mismatch in `ChatScreen` / `ChatComposer`

- [ ] **Step 3: Review the diff for scope control**

Check:

- only command discovery and guidance UI changed
- no controller or gateway behavior changed
- no advanced command catalog was accidentally surfaced

Run:

```bash
git diff -- lib/src/presentation/screens/chat_screen.dart lib/src/presentation/widgets/chat_composer.dart lib/src/presentation/widgets/chat_command_assist.dart lib/l10n/app_en.arb lib/l10n/app_zh.arb
```

- [ ] **Step 4: Commit the finished implementation**

Run:

```bash
git add lib/src/presentation/screens/chat_screen.dart lib/src/presentation/widgets/chat_composer.dart lib/src/presentation/widgets/chat_command_assist.dart lib/l10n/app_en.arb lib/l10n/app_zh.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_zh.dart
git commit -m "feat: improve chat command discovery"
```

## Self-Review

### Spec Coverage

Covered spec requirements:

- empty-state command discovery: Task 2
- inline slash suggestions: Task 3
- semantic pre-send hints for standalone commands, directives, misuse, and `/clear`: Task 3
- lightweight visual treatment and chat-first scope: Tasks 2 and 3
- localization-aware user-facing copy: Task 1

No spec gap remains for the approved scope.

### Placeholder Scan

The plan uses exact file paths, concrete commands, concrete helper names, and explicit verification commands. No `TBD`, `TODO`, or vague “handle later” placeholders remain.

### Type Consistency

The plan consistently uses:

- `ChatCommandSuggestion`
- `ChatCommandHintKind`
- `ChatCommandAssistResult`
- `analyzeChatDraft`
- `_applyCommandTemplate`

These names should remain stable during implementation to avoid widget wiring drift.
