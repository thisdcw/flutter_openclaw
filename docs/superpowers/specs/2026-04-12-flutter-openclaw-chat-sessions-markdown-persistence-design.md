# Flutter OpenClaw Chat Sessions, Markdown, And Persistence Design

**Date:** 2026-04-12
**Status:** Approved in chat, written for implementation
**Target Project:** `flutter_openclaw`

## Goal

Upgrade the Flutter OpenClaw client so the chat experience is viable for daily use:

- chat sessions must no longer share one fixed `sessionId`
- assistant responses should render as Markdown instead of raw plain text
- all messages should support long-press actions, and images should support preview and download
- chat history should persist locally across app restarts
- the storage and state model should be ready for a future multi-session chat list instead of a single in-memory transcript

## Scope

### In Scope

- replace the fixed session identifier strategy with UUIDv4-based conversation sessions
- persist conversations locally and restore the last active conversation on startup
- introduce conversation list, conversation creation, and conversation switching UI
- render chat message content with Markdown-friendly presentation
- support long-press copy on messages
- support image preview and image download with platform permission handling
- keep the current connection and send flow intact except where session selection must be wired through

### Out Of Scope

- i18n text cleanup
- automated test authoring and execution for this change set
- cloud sync or account-backed history sync
- deleting conversations, pinning conversations, and full-text search
- message retry, edit, or regenerate actions

## Product Intent

The current app behaves like a single volatile transcript. That causes two problems:

1. the fixed `sessionId` risks context pollution between unrelated asks
2. the transcript disappears on restart and cannot grow into a real chat product

This iteration turns the app into a proper local-first multi-session client while staying intentionally modest:

- one active conversation at a time
- a lightweight conversation list
- durable local storage
- better message readability and operability

## Session Strategy

### Current Problem

The app currently uses a fixed default `sessionId` from config. That makes unrelated conversations share the same backend session context and can cause context bleed.

### New Rule

Each conversation owns its own OpenClaw `sessionId`, generated as UUIDv4.

That means:

- new conversation -> new UUIDv4 session id
- switching conversation -> switch the active OpenClaw session id
- restoring the last active conversation -> restore its saved session id

### Migration Rule

Existing installs may still contain the old fixed default session id in config.

On bootstrap:

- if a stored conversation index exists, trust it and restore the active conversation
- if no conversation store exists yet, create a new initial conversation with a fresh UUIDv4
- if config still contains the old default fixed session id, replace it with the new active conversation session id when persisting the active conversation state

### Config Relationship

`GatewayConfig.sessionId` remains as a readonly surfaced value for the currently active conversation, not as a user-editable static app setting.

## Local Persistence Design

### Storage Shape

Local persistence should move chat history out of `SharedPreferences`.

Use a file-backed store under the app documents directory:

- `chat_store/index.json`
  - schema version
  - active conversation id
  - ordered conversation summaries
- `chat_store/conversations/<conversationId>.json`
  - full message list for one conversation
- `chat_store/media/<conversationId>/<attachmentId>.<ext>`
  - copied local image attachments for user-originated uploads

### Why File Storage

This is the smallest durable design that still scales beyond one session:

- avoids stuffing large message payloads into `SharedPreferences`
- keeps summaries separate from full transcripts
- allows lazy loading per conversation
- leaves room to swap to a database later without rewriting controller semantics first

### Persisted Conversation Summary

Each conversation summary should include:

- `id`
- `sessionId`
- `title`
- `previewText`
- `updatedAt`
- `messageCount`

### Title Strategy

Keep title generation simple for now:

- first non-empty user text message becomes the preferred title source
- truncate to a short readable label
- if no user text exists yet, use a generic fallback such as `New chat`

### Message Persistence Timing

Persist on meaningful state transitions:

- after local user message append
- after assistant streaming updates
- after assistant final message completion
- after conversation creation or switch

Streaming writes can be debounced lightly inside the controller, but correctness matters more than perfect write minimization.

## Conversation State Model

### Active State

The chat controller should own:

- active conversation summary
- active conversation messages
- conversation summaries list

### Operations

Required controller-level operations:

- bootstrap from local store
- create new conversation
- switch conversation
- append user message
- upsert streaming assistant message
- persist active conversation after changes

### Slash Command Handling

The current local special-case for `/new` should be aligned with the new session model.

Recommended behavior:

- `/new`
- `/reset`

should create a fresh local conversation and switch to it instead of clearing the current in-memory transcript while reusing the old session id.

## Message Rendering

### Markdown Support

Assistant messages should render as Markdown-friendly content instead of raw plain text.

Required support:

- paragraphs
- headings
- bullet and numbered lists
- block quotes
- fenced code blocks
- inline code
- links
- Markdown images

The implementation does not need a full authoring toolchain; it needs stable display for typical OpenClaw responses.

### Image Handling

Two image sources must be supported:

1. user local attachments
2. remote image references embedded in message content

Both should support:

- tap to preview
- download action

### Long-Press Actions

Every message bubble should support long-press actions.

Minimum actions:

- copy message text

Conditional actions when images are present:

- preview image
- download image

## Image Preview And Download

### Preview

Image preview should open in a dedicated full-screen route with:

- dark background
- zoom/pan capable image view
- close action
- download action in the app bar or overlay

### Download

Download should save the image into the system image surface instead of only app-private storage.

Platform expectations:

- Android: save into Pictures / gallery-visible location
- iOS: save to Photos library

### Permission Handling

Permission handling must be explicit and platform aware:

- request write/add permission when needed
- handle denied and permanently denied states gracefully
- surface success and failure feedback in the UI

This work should not silently fail when the platform blocks writes.

## UI Changes

### Conversation List

The chat screen should expose a lightweight session list UI.

Required capabilities:

- view recent conversations
- create new conversation
- switch active conversation
- show which conversation is active

The list can ship as a drawer, sheet, or side panel as long as it stays light and does not take over the app structure.

### Active Session Visibility

The active conversation title should be visible in the chat screen chrome so users understand which conversation they are in.

### Settings Screen

Settings should continue to show the active session id as readonly information, but it should now reflect the active conversation session id instead of a fixed global constant.

## Technical Approach

### New Storage Layer

Add a dedicated storage repository for conversations instead of extending the config repository.

That repository is responsible for:

- bootstrapping store directories
- loading index and active conversation
- creating and persisting conversation files
- copying uploaded images into managed local media storage

### Existing Chat Flow Integration

Keep `SendChatMessageUseCase` and `LiveChatRepository` as the live transport path.

Adjust only what is needed so the active conversation `sessionId` is used for outgoing requests.

### Rendering Layer

The message bubble should stop treating all assistant text as plain `Text`.

Instead it should:

- split message content into ordered text/image blocks
- render text blocks with Markdown-aware widgets
- render image blocks with preview/download hooks

## Risks And Mitigations

### Risk: local store grows quickly

Mitigation:

- store summaries separately from full message files
- load only the active conversation messages into memory

### Risk: streaming persistence causes excessive writes

Mitigation:

- centralize persistence through controller methods
- allow light debounce for streaming updates if needed

### Risk: permission handling differs across platforms

Mitigation:

- isolate image-save behavior behind a platform-facing service
- provide clear user feedback for success, denial, and failure

### Risk: Markdown rendering breaks image extraction order

Mitigation:

- keep a focused content parser that preserves block order
- treat remote images as first-class content segments before text rendering

## Delivery Criteria

This work is complete when:

- the app no longer depends on a fixed default session id for chat context
- each new conversation gets a UUIDv4-backed session id
- the app restores the last active conversation after restart
- users can open a conversation list, create a conversation, and switch conversations
- assistant output renders as Markdown-friendly content
- all messages expose long-press copy
- images can be previewed fullscreen
- images can be downloaded into the system image surface with permission-aware handling
- active session id shown in settings reflects the selected conversation
