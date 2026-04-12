# Flutter OpenClaw Global Error Experience Design

## Goal

Improve overall error handling UX so users see short, actionable, friendly messages instead of raw exceptions, while still keeping a way to inspect or copy technical details when needed.

## Scope

This design covers three error surfaces in the current Flutter client:

1. Page-scoped business errors that already appear in chat or settings.
2. Recoverable but currently unmapped exceptions that fall back to raw `error.toString()`.
3. Truly unhandled framework, async, or zone-level errors that currently have no consistent in-app UX path.

This design does not change gateway protocol behavior, retry policies, or admin authorization logic beyond improving how errors are surfaced.

## Current Project Context

The current app has a simple root:

- [main.dart](d:/openclaw/flutter_openclaw/lib/main.dart) creates dependencies and runs `OpenClawApp`.
- [openclaw_app.dart](d:/openclaw/flutter_openclaw/lib/src/app/openclaw_app.dart) builds a `MaterialApp` whose home is the chat screen.
- [app_dependencies.dart](d:/openclaw/flutter_openclaw/lib/src/app/app_dependencies.dart) wires `SettingsController`, `ConnectionController`, and `ChatController`.

Current error handling is fragmented:

- [chat_controller.dart](d:/openclaw/flutter_openclaw/lib/src/application/controllers/chat_controller.dart) stores a raw `errorMessage`.
- [connection_controller.dart](d:/openclaw/flutter_openclaw/lib/src/application/controllers/connection_controller.dart) maps some failures, but still relies on local state and screen-specific rendering.
- [chat_screen.dart](d:/openclaw/flutter_openclaw/lib/src/presentation/screens/chat_screen.dart) and [settings_screen.dart](d:/openclaw/flutter_openclaw/lib/src/presentation/screens/settings_screen.dart) render local banners.
- There is no unified in-app path for `FlutterError.onError`, `PlatformDispatcher.instance.onError`, or `runZonedGuarded` failures.

## Recommended Approach

Use a lightweight global error center with three layers:

1. **Error classification**
   Convert known raw exceptions into stable app-facing categories with short, human-readable copy and optional recovery guidance.

2. **Shared presentation model**
   Introduce a small app-level error notice model that holds:
   - severity
   - user-facing title/message
   - optional technical detail
   - optional recovery hint
   - whether the notice belongs to a local screen or global surface

3. **Central delivery**
   Route both business-layer and uncaught errors through one notifier so the app can decide whether to show:
   - a page-level banner when the error belongs to the current task
   - a global snackbar or top-level notice when the error has no page owner

This keeps the architecture small while giving the app one consistent UX language for errors.

## Alternatives Considered

### 1. Recommended: Global error center plus local banners

Pros:
- Consistent UX across chat, settings, and uncaught errors
- Preserves existing screen banners instead of replacing them
- Gives one place to improve copy and action guidance later

Cons:
- Requires a new lightweight controller/model
- Touches both app root and feature controllers

### 2. Local-only cleanup

Pros:
- Smaller edit footprint
- Fastest path for current known screens

Cons:
- Misses unhandled framework and async errors
- Leads to duplicated error mapping logic across controllers and screens

### 3. Global catch-only solution

Pros:
- Fast to wire at app entry
- Helps with true uncaught exceptions

Cons:
- Does not improve already-caught but poorly-presented business errors
- Leaves existing local UX inconsistent

## Design

### Error Model

Add an app-level notice model focused on UX, not transport internals. The model should support:

- short user-facing message
- optional action hint
- optional raw detail string
- display style (`inline`, `global`)
- category (`connection`, `chat`, `settings`, `system`, `unknown`)

This model becomes the single output of error classification.

### Global Error Controller

Add a lightweight controller, likely under `application/controllers`, responsible for:

- publishing the latest global notice
- clearing consumed notices
- receiving explicit reports from feature controllers
- receiving uncaught app errors from the root entrypoint

The controller should remain presentation-oriented and avoid direct gateway or storage logic.

### Root App Wiring

Wire the app entrypoint to catch uncaught errors from:

- `FlutterError.onError`
- `PlatformDispatcher.instance.onError`
- `runZonedGuarded`

These errors should be:

- logged through the existing logger
- converted into a generic user-facing notice
- delivered to the global error controller

The default user-facing copy for unknown global errors should stay short, such as “操作失败，请稍后重试” / “Something went wrong. Please try again.”

### Local Screen Behavior

Existing local banners should stay, but their inputs should be upgraded:

- Chat and connection controllers should stop exposing raw exception strings by default.
- Known errors should map to friendly copy.
- Unknown errors should map to a generic short message plus optional details.
- When a controller cannot confidently attach an error to a screen, it should also report it to the global error controller.

### Technical Details Access

For user support and admin debugging, each notice should optionally preserve raw detail text. The first version should keep this simple:

- inline errors can expose a small “查看详情” / “Details” affordance
- global notices can expose a “复制错误” / “Copy error” action

The default collapsed state should never show the raw stack trace to ordinary users.

### Copy Strategy

Use three copy tiers:

1. **Known action-oriented error**
   Example: missing pairing, missing scope, timeout

2. **Known but non-actionable error**
   Example: picker plugin unavailable

3. **Unknown fallback**
   Short friendly message plus detail affordance

This keeps the UI calm while still giving operators enough information when needed.

## Boundaries

This design intentionally does not include:

- a dedicated diagnostics screen
- remote crash reporting
- automatic bug report upload
- new retry orchestration logic

Those can be layered later on top of the shared error model.

## Implementation Notes

To match the current repo, the likely touch points are:

- [main.dart](d:/openclaw/flutter_openclaw/lib/main.dart)
- [openclaw_app.dart](d:/openclaw/flutter_openclaw/lib/src/app/openclaw_app.dart)
- [app_dependencies.dart](d:/openclaw/flutter_openclaw/lib/src/app/app_dependencies.dart)
- [chat_controller.dart](d:/openclaw/flutter_openclaw/lib/src/application/controllers/chat_controller.dart)
- [connection_controller.dart](d:/openclaw/flutter_openclaw/lib/src/application/controllers/connection_controller.dart)
- [chat_screen.dart](d:/openclaw/flutter_openclaw/lib/src/presentation/screens/chat_screen.dart)
- [settings_screen.dart](d:/openclaw/flutter_openclaw/lib/src/presentation/screens/settings_screen.dart)

If localized strings need regeneration, the generated i18n step should be run by the user, not by the agent in this task.

## Verification Constraint

Per user instruction for this task:

- do not run tests
- do not claim test-passing status
- if localization generation is needed, hand that step to the user
