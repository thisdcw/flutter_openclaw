# Flutter OpenClaw Command Discovery And Guidance Design

**Date:** 2026-04-12
**Status:** Approved in chat, written for review
**Target Project:** `flutter_openclaw`

## Goal

Improve the OpenClaw chat experience so command-related features are easier to discover and understand without turning the app into a developer console.

The primary product goal is to help users learn and safely use OpenClaw slash commands through lightweight in-context guidance.

## Scope

### In Scope

- improve command discoverability on the chat screen
- provide lightweight guidance for high-frequency commands
- show contextual suggestions when the user starts typing slash commands
- surface rule-aware hints based on the command guidance in `OPENCLAW_CHAT_COMMANDS.md`
- distinguish between Gateway commands, inline directives, inline shortcuts, and local commands in the UI copy
- keep the experience beginner-friendly and visually light

### Out of Scope

- implementing a full command center or advanced developer console
- changing Gateway protocol behavior
- changing send semantics or controller flow
- adding new backend command support beyond user guidance
- exposing high-risk admin or debug commands by default
- introducing tests for this iteration

## Product Intent

The app should feel like a polished AI assistant first and a command-driven system second.

Users should be able to:

- discover a small set of useful commands without reading external docs
- understand when a command should be sent alone
- understand when a directive only affects the current message
- recognize when a command is local to the client instead of a Gateway capability

The app should avoid:

- showing an overwhelming list of commands
- interrupting normal chat flow
- auto-sending commands without the user confirming intent
- presenting advanced operational commands to normal users

## Chosen Direction

The approved direction is **lightweight prompt-style guidance**.

This means the chat screen remains visually simple, but gains three layers of help:

1. empty-state command discovery
2. inline slash suggestions while typing
3. pre-send semantic guidance based on command shape

This is intentionally lighter than a command palette or settings-heavy control surface.

## UX Principles

- command help should appear where the user already looks
- command help should teach by doing, not by opening a manual
- suggestions should fill the composer, not send automatically
- warnings should clarify behavior, not block unless absolutely necessary
- the interface should keep prioritizing normal conversation

## Command Model For UX

The UI should reflect the command model described in `OPENCLAW_CHAT_COMMANDS.md`.

### Command Categories

The guidance layer should recognize four user-facing categories:

1. session commands
   - examples: `/new`, `/reset`, `/compact`, `/stop`
2. status and help commands
   - examples: `/status`, `/help`, `/commands`
3. directive-style settings
   - examples: `/model`, `/think`, `/fast`
4. local client commands
   - example: `/clear`

The app should not present these as equally interchangeable. The guidance should help users understand that some commands are session-level, some are inline-capable, and some are local convenience actions.

## Experience Design

### 1. Empty State Command Discovery

The empty state should evolve from a generic welcome card into a chat-first onboarding surface with lightweight command entry points.

### Content

Keep the welcome title and short assistant-oriented subtitle, then add a compact high-frequency command row or wrapped chip group.

Recommended default commands:

- `/new`
- `/status`
- `/model`
- `/think`
- `/help`

Each chip should include:

- command label
- short human explanation

Examples:

- `/new` - start a new session
- `/status` - check current session state
- `/model` - switch or inspect model
- `/think` - change reasoning depth
- `/help` - see available help

### Interaction

Selecting a chip should:

- populate the composer with the command template
- keep focus in the composer
- not auto-send

This preserves user control and avoids accidental command execution.

### 2. Composer Hint Upgrade

The composer hint should become slightly more informative.

Instead of feeling like a plain message-only field, it should acknowledge two valid modes:

- normal chat input
- slash command input

The hint copy should remain short, such as a message that implies both conversation and commands without becoming instructional text overload.

### 3. Inline Slash Suggestions

When the composer starts with `/`, the app should show a lightweight suggestion panel above the composer.

This panel should feel like a subtle assist layer rather than a modal or a large drawer.

### Default Suggestion Groups

Suggested groups:

- Session
  - `/new`
  - `/reset`
  - `/compact`
  - `/stop`
- Status
  - `/status`
  - `/help`
- Common Settings
  - `/model`
  - `/think`
  - `/fast`

### Filtering Behavior

Suggestions should filter by command prefix.

Examples:

- `/st` should narrow toward `/status` and `/stop`
- `/mo` should narrow toward `/model`

Filtering should remain simple and deterministic, based on prefix matching only.

### Suggestion Selection

Selecting a suggestion should insert a command template into the composer.

Examples:

- `/new`
- `/status`
- `/model `
- `/think high`
- `/fast on`

Templates may include a trailing space or a safe starter parameter where helpful, but must not auto-send.

### 4. Pre-Send Guidance Layer

Before the user sends a message, the composer area should display a compact semantic hint when the draft clearly matches a known command pattern.

This hint is informational, not a blocking confirmation dialog.

### Standalone Gateway Command

If the draft is a standalone command message, the UI should explain that it will be sent as a command to the Gateway.

Examples:

- `/new`
- `/status`
- `/model openai/gpt-5.4`

### Inline Directive Hint

If the draft contains directive-style commands inside otherwise normal text, the UI should explain that the directive behaves like a message-scoped hint instead of a persistent session change.

Examples:

- `请先 /think high 再帮我分析这段代码`
- `这次 /fast on 帮我快速总结`

This hint should only apply to known directive-style commands:

- `/think`
- `/fast`
- `/verbose`
- `/reasoning`
- `/model`
- `/queue`
- `/elevated`
- `/exec`

### Inline Misuse Hint

If the draft contains commands that usually need to be standalone but are embedded in ordinary text, the UI should warn lightly that these commands are usually sent as separate messages.

Examples:

- `帮我先 /new 然后继续`
- `你看下 /reset`

This hint is especially relevant for:

- `/new`
- `/reset`
- `/compact`
- `/stop`

### Local Command Hint

If the draft matches `/clear`, the UI should explain that this is treated as a client-local command rather than a stable Gateway slash command.

The app should not misrepresent `/clear` as part of the documented backend command set.

## Copy Strategy

Copy should be concise, product-like, and explanatory rather than technical.

Examples of desired tone:

- “This will be sent as a Gateway command.”
- “Detected an inline directive. It likely applies only to this message.”
- “This command is usually sent as its own message.”
- “`/clear` is a local app command.”

Avoid:

- stack-trace style wording
- internal parser jargon
- protocol-heavy implementation detail in default UI

## Visual Design

The existing soft-futurist chat styling should remain.

New guidance surfaces should feel lightweight:

- low-height cards or tinted capsules
- compact chips
- subtle borders
- no bulky drawers
- no strong warning styling unless there is real risk

The new UI should not visually compete with the transcript.

## Accessibility And Usability

- command chips must remain tappable on small screens
- hint copy must not rely on color alone
- suggestion rows should wrap cleanly when space is limited
- the composer should remain usable with long text and attachments
- guidance surfaces should disappear naturally when no longer relevant

## Technical Approach

This work should stay in the presentation layer.

Expected file surface:

- `lib/src/presentation/screens/chat_screen.dart`
- `lib/src/presentation/widgets/chat_composer.dart`

Optional focused support extraction is acceptable if it keeps widget code readable.

Reasonable support files:

- a small presentation helper for command metadata
- a small presentation helper for command draft analysis

No controller, repository, Gateway, or domain behavior change is required for this iteration unless a minimal presentation-facing helper model is clearly justified.

## Behavior Rules

### Supported Default Discovery Commands

The empty-state quick actions should prioritize high-frequency commands only:

- `/new`
- `/status`
- `/model`
- `/think`
- `/help`

### Supported Slash Suggestion Commands

The inline suggestion layer should focus on common and safe commands:

- `/new`
- `/reset`
- `/compact`
- `/stop`
- `/status`
- `/help`
- `/model`
- `/think`
- `/fast`

### Excluded From Default Discovery

These should not be surfaced in the default lightweight discovery layer:

- `/config`
- `/mcp`
- `/plugins`
- `/debug`
- `/bash`
- `/approve`
- `/allowlist`
- `/subagents`

Those belong to advanced or admin-oriented workflows and would conflict with the lightweight beginner-friendly goal.

## Delivery Criteria

This work is complete when:

- empty chat state exposes a compact set of high-frequency commands
- tapping a command chip fills the composer without auto-sending
- typing `/` reveals a lightweight filtered suggestion panel
- suggestion content reflects the command taxonomy from `OPENCLAW_CHAT_COMMANDS.md`
- the composer shows semantic hints for standalone commands, inline directives, inline misuse, and `/clear`
- the chat screen remains visually lightweight and chat-first
- no backend protocol behavior changes are introduced

## Risks And Mitigations

### Risk: guidance becomes too noisy

Mitigation:

- only show hints for clear command patterns
- keep copy short
- hide guidance when the draft no longer matches

### Risk: users assume every surfaced command is safe in all contexts

Mitigation:

- only surface safe, common commands in the lightweight layer
- keep admin and debug commands out of default discovery

### Risk: command heuristics misclassify free text

Mitigation:

- keep recognition rules narrow
- match only documented high-confidence patterns
- default to normal chat behavior when unsure

### Risk: `/clear` is confused with a backend command

Mitigation:

- explicitly label it as local
- do not present it beside stable Gateway commands in the empty-state quick actions
