# Flutter OpenClaw Global Error Experience Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a lightweight global error center so chat, connection, and uncaught app failures surface as friendly, actionable notices instead of raw exceptions.

**Architecture:** Introduce a small shared error notice model plus a global error controller, then wire feature controllers and the app root into that path. Keep page-scoped errors as inline banners, and route uncaught framework or zone errors through a root snackbar with a copy-details affordance.

**Tech Stack:** Flutter, Dart, Material, existing app controllers and localization helpers

---

### Task 1: Shared Error Model

**Files:**
- Create: `lib/src/application/models/app_error_notice.dart`

- [ ] Define shared error enums for scope, presentation, and known error kinds.
- [ ] Add a lightweight `AppErrorNotice` model with raw details, kind inference, and copyable diagnostics text.
- [ ] Keep the model UI-agnostic so both local banners and global snackbars can reuse it.

### Task 2: Global Error Controller

**Files:**
- Create: `lib/src/application/controllers/app_error_controller.dart`

- [ ] Add a `ChangeNotifier` that stores the active global error notice.
- [ ] Add helpers for publishing and clearing notices.
- [ ] Add a helper for reporting uncaught exceptions as global user-facing notices.

### Task 3: User-Facing Error Rendering

**Files:**
- Create: `lib/src/presentation/localization/localized_app_error_text.dart`
- Create: `lib/src/presentation/widgets/error_notice_banner.dart`

- [ ] Centralize friendly user-facing copy for known and unknown errors.
- [ ] Support concise summary text plus optional action hint.
- [ ] Add inline details expand/collapse and copy actions for local banners.

### Task 4: Wire Controllers To Shared Errors

**Files:**
- Modify: `lib/src/application/controllers/chat_controller.dart`
- Modify: `lib/src/application/controllers/connection_controller.dart`
- Modify: `lib/src/app/app_dependencies.dart`

- [ ] Route chat send failures through inline notices instead of exposing only raw strings.
- [ ] Route connection failures through inline notices while keeping connection status logic intact.
- [ ] Publish unexpected controller-level failures to the global controller when appropriate.
- [ ] Provide the new global error controller through app dependencies.

### Task 5: Wire Root App To Uncaught Errors

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/src/app/openclaw_app.dart`

- [ ] Capture `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and `runZonedGuarded`.
- [ ] Report uncaught exceptions to the global error controller.
- [ ] Add a root-level listener that displays global snackbars with copy-details support.

### Task 6: Upgrade Existing Screens

**Files:**
- Modify: `lib/src/presentation/screens/chat_screen.dart`
- Modify: `lib/src/presentation/screens/settings_screen.dart`

- [ ] Replace raw-string local error banners with the shared inline error banner component.
- [ ] Preserve existing connection-strip UX while improving local error detail handling.
- [ ] Keep current page layout stable and avoid adding new navigation surfaces.

### Task 7: Final Manual Diff Review

**Files:**
- Verify only

- [ ] Review the diff to confirm changes stay limited to error modeling, wiring, and presentation.
- [ ] Do not run tests for this task per user instruction.
- [ ] If future localization generation becomes necessary, delegate that step to the user.
