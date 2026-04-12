# Flutter OpenClaw Chat Sessions, Markdown, And Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the current single in-memory transcript into a local-first multi-conversation chat client with UUID-backed sessions, Markdown-friendly rendering, message copy actions, and image preview/download support.

**Architecture:** Add a dedicated conversation store that persists an index plus per-conversation message files under the app documents directory. Upgrade `ChatController` to own active conversation state and summaries, wire active session ids into send flow, then update the presentation layer with a lightweight conversation list, Markdown-aware message content, and image action surfaces.

**Tech Stack:** Flutter, Dart, local file storage via `dart:io` and `path_provider`, native platform channels for gallery/photo saving

---

## File Structure

- Create: `lib/src/domain/models/chat_conversation_summary.dart`
- Create: `lib/src/domain/models/chat_conversation_record.dart`
- Create: `lib/src/domain/models/chat_store_snapshot.dart`
- Create: `lib/src/domain/repositories/chat_conversation_store.dart`
- Create: `lib/src/infrastructure/storage/file_chat_conversation_store.dart`
- Create: `lib/src/infrastructure/platform/image_save_service.dart`
- Modify: `lib/src/application/controllers/chat_controller.dart`
- Modify: `lib/src/application/use_cases/send_chat_message_use_case.dart`
- Modify: `lib/src/app/app_dependencies.dart`
- Modify: `lib/src/infrastructure/config/dev_defaults.dart`
- Modify: `lib/src/presentation/screens/chat_screen.dart`
- Modify: `lib/src/presentation/screens/settings_screen.dart`
- Modify: `lib/src/presentation/widgets/message_bubble.dart`
- Modify: `lib/src/presentation/widgets/message_content_parser.dart`
- Create: `lib/src/presentation/widgets/conversation_list_sheet.dart`
- Create: `lib/src/presentation/widgets/chat_markdown_text.dart`
- Create: `lib/src/presentation/screens/image_preview_screen.dart`
- Modify: `android/app/src/main/kotlin/com/cw/claw/flutter_openclaw/MainActivity.kt`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/AppDelegate.swift`
- Modify: `ios/Runner/Info.plist`

## Task 1: Add Persistent Conversation Models And Store

**Files:**
- Create: `lib/src/domain/models/chat_conversation_summary.dart`
- Create: `lib/src/domain/models/chat_conversation_record.dart`
- Create: `lib/src/domain/models/chat_store_snapshot.dart`
- Create: `lib/src/domain/repositories/chat_conversation_store.dart`
- Create: `lib/src/infrastructure/storage/file_chat_conversation_store.dart`
- Modify: `lib/src/infrastructure/config/dev_defaults.dart`

- [ ] Define conversation summary, record, and bootstrap snapshot models with JSON serialization.
- [ ] Add a `ChatConversationStore` repository contract for bootstrap, create, switch, and save operations.
- [ ] Implement a file-backed store under the app documents directory with `index.json`, per-conversation JSON files, and media subdirectories.
- [ ] Move the fixed default session strategy out of `defaultGatewayConfig` so the app no longer ships with `cli-session-default` as real chat identity.
- [ ] Ensure the store creates a first conversation with UUIDv4 session id on first launch and restores the previously active conversation afterwards.

## Task 2: Upgrade Chat Controller Into Multi-Conversation State

**Files:**
- Modify: `lib/src/application/controllers/chat_controller.dart`
- Modify: `lib/src/application/use_cases/send_chat_message_use_case.dart`
- Modify: `lib/src/app/app_dependencies.dart`

- [ ] Inject the conversation store and bootstrap snapshot into `ChatController`.
- [ ] Add controller state for `conversationSummaries`, `activeConversation`, and active `messages`.
- [ ] Add controller methods for `createConversation()`, `switchConversation()`, and internal persistence of active transcript changes.
- [ ] Route outgoing send requests through the active conversation `sessionId` instead of the old fixed config-backed session id.
- [ ] Replace the old local `/new` history-clear behavior with creation of a fresh conversation carrying a new UUIDv4 session id.

## Task 3: Add Markdown-Friendly Message Rendering And Long-Press Actions

**Files:**
- Create: `lib/src/presentation/widgets/chat_markdown_text.dart`
- Modify: `lib/src/presentation/widgets/message_content_parser.dart`
- Modify: `lib/src/presentation/widgets/message_bubble.dart`

- [ ] Extend the message content parser so ordered text and image segments still survive mixed Markdown and remote image content.
- [ ] Introduce a focused Markdown-aware text renderer for text segments covering headings, lists, block quotes, fenced code blocks, inline code, and links well enough for OpenClaw responses.
- [ ] Update `MessageBubble` to render user attachments and remote message images through one consistent image surface.
- [ ] Add message long-press actions with at least copy text, and conditionally preview/download image actions when the message contains images.
- [ ] Keep streaming states and failure states readable after the renderer changes.

## Task 4: Add Image Preview And Platform Save Support

**Files:**
- Create: `lib/src/infrastructure/platform/image_save_service.dart`
- Create: `lib/src/presentation/screens/image_preview_screen.dart`
- Modify: `android/app/src/main/kotlin/com/cw/claw/flutter_openclaw/MainActivity.kt`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/AppDelegate.swift`
- Modify: `ios/Runner/Info.plist`

- [ ] Create a small Flutter service that talks to a native method channel to save image bytes into the system image surface.
- [ ] Implement Android save logic using MediaStore and runtime permission handling where needed.
- [ ] Implement iOS save logic using Photos add-only permission and photo library write APIs.
- [ ] Add the needed manifest and plist permission declarations.
- [ ] Build a fullscreen image preview route with zoom/pan and a download action that uses the save service and reports success/failure.

## Task 5: Ship Conversation List, New Conversation, And Active Session UI

**Files:**
- Create: `lib/src/presentation/widgets/conversation_list_sheet.dart`
- Modify: `lib/src/presentation/screens/chat_screen.dart`
- Modify: `lib/src/presentation/screens/settings_screen.dart`

- [ ] Add a lightweight conversation list sheet or drawer reachable from the chat app bar.
- [ ] Show recent conversations, active conversation state, and a create-new-conversation action.
- [ ] Update the chat header to reflect the active conversation title.
- [ ] Wire list actions into `ChatController.createConversation()` and `ChatController.switchConversation()`.
- [ ] Update settings so the readonly session id reflects the active conversation session id instead of a fixed app-level constant.

## Task 6: Non-Test Verification Pass

**Files:**
- Modify: `lib/src/application/controllers/chat_controller.dart`
- Modify: `lib/src/application/use_cases/send_chat_message_use_case.dart`
- Modify: `lib/src/presentation/screens/chat_screen.dart`
- Modify: `lib/src/presentation/widgets/message_bubble.dart`
- Modify: `lib/src/presentation/widgets/message_content_parser.dart`
- Create: `lib/src/presentation/widgets/chat_markdown_text.dart`
- Create: `lib/src/presentation/widgets/conversation_list_sheet.dart`
- Create: `lib/src/presentation/screens/image_preview_screen.dart`
- Create: `lib/src/infrastructure/storage/file_chat_conversation_store.dart`
- Create: `lib/src/infrastructure/platform/image_save_service.dart`

- [ ] Run `dart format` across the touched Dart files.
- [ ] Run `flutter analyze` only if dependency surface remains unchanged and the environment allows it; otherwise record the blocker instead of forcing it.
- [ ] Manually inspect the active diff to confirm session flow, persistence flow, and image-save integration are limited to the intended files.
- [ ] Summarize any residual risks created by intentionally skipping automated test execution in this task.

## Plan Self-Review

### Spec Coverage

- UUIDv4 session-per-conversation model: Tasks 1 and 2
- durable local persistence with future multi-session basis: Tasks 1 and 2
- conversation list, new conversation, switching UI: Task 5
- Markdown-friendly message display: Task 3
- long-press copy: Task 3
- image preview and download with permissions: Task 4
- active session id reflected in settings: Task 5

### Placeholder Scan

- No `TODO`, `TBD`, or deferred placeholders remain
- Each task maps to explicit file paths
- Verification expectations are concrete and limited to this user-approved no-test scope

### Type Consistency

- The plan consistently uses `conversation`, `summary`, and `sessionId` terminology
- Storage responsibility stays in the new conversation store, not in config storage
- Platform image saving stays behind one service boundary used by presentation
