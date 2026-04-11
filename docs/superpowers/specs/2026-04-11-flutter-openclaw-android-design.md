# Flutter OpenClaw Android Client Design

**Date:** 2026-04-11
**Status:** Approved in chat, written for review
**Target Project:** `flutter_openclaw`
**Reference Logic:** `my-openclaw/my-claw.js`

## Goal

Build the first Flutter OpenClaw client with Android as the primary platform. The first release must support complete device authentication and chat messaging against the OpenClaw Gateway, while keeping the app architecture clean enough to extend to iOS and desktop later.

## Scope

### In Scope

- Android-first Flutter application
- Device identity generation and local persistence
- `connect.challenge -> connect -> hello-ok` handshake flow
- `authToken` and `deviceToken` authentication paths
- Granted scope tracking and UI feedback
- Gateway WebSocket lifecycle management
- `chat.send` request handling
- Streaming assistant response rendering
- Manual `sessionId` switching
- In-app configuration page with development defaults
- Local persistence for config and auth/device state
- Clear error presentation for pairing, scope, timeout, and disconnect issues

### Out of Scope

- iOS, Windows, macOS, Linux production support
- Persistent message history
- Multi-session history or session list UI
- Push notifications
- File upload, image input, or multimodal support
- Analytics and telemetry backend
- Full i18n framework beyond a configurable locale field

## Product Intent

This client is not a consumer chat app yet. It is a developer-facing OpenClaw mobile client with a clean UI and strong protocol fidelity. The design prioritizes:

- Correctness of Gateway protocol behavior
- Clear visibility into connection and authorization state
- Fast iteration during OpenClaw protocol debugging
- A codebase that can grow into a broader client later

## Architecture

The app will use a single-app layered architecture:

- `presentation`
  Flutter pages, widgets, view models, and UI state mapping
- `application`
  Use cases and orchestration logic for connect, authenticate, send message, reconnect, and save config
- `domain`
  Core entities, value objects, enums, and repository/service contracts
- `infrastructure`
  WebSocket, storage, crypto, protocol frame parsing, and repository implementations

This keeps protocol logic separate from UI while avoiding premature package extraction. The first release stays in one Flutter app, but the boundaries are explicit so core logic can be moved into a shared Dart package later if needed.

## Module Breakdown

### 1. Config Module

Responsible for runtime configuration used by the Gateway client.

Data owned by this module:

- `gatewayUrl`
- `authToken`
- `sessionId`
- `timeoutMs`
- `locale`
- optional development defaults metadata

Behavior:

- Load saved config on app start
- Fall back to baked-in development defaults when no saved config exists
- Save user-edited config from the settings screen
- Expose effective config to the connection flow

### 2. Device Identity Module

Responsible for generating and restoring the device identity used during signed connection.

Data owned by this module:

- `deviceId`
- public key
- private key

Behavior:

- Generate a new identity when none exists
- Persist the identity locally
- Return the same identity on later launches
- Support explicit reset for debugging or re-pairing

### 3. Operator Auth Module

Responsible for storing and updating the current operator authorization state.

Data owned by this module:

- `deviceToken`
- granted `scopes`
- `role`

Behavior:

- Prefer `deviceToken` when available
- Fall back to `authToken` when `deviceToken` is absent
- Update persisted auth after `hello-ok`
- Clear auth state on user reset

### 4. Gateway Connection Module

Responsible for maintaining the WebSocket session with the OpenClaw Gateway.

Behavior:

- Open socket to `gatewayUrl`
- Wait for `connect.challenge`
- Build and send `connect`
- Track readiness state
- Detect disconnects
- Retry connection after disconnect
- Surface connection state changes to the UI

### 5. Chat Module

Responsible for request/response behavior for operator chat.

Behavior:

- Send `chat.send` using current `sessionId`
- Create request tracking by `requestId`
- Attach `runId` after initial response
- Aggregate assistant stream deltas
- Finish a message on `lifecycle:end` or `chat` final event
- Emit errors for timeout, empty response, or upstream failures

## Domain Model

The first release should define explicit models instead of passing maps through the app.

Expected core models:

- `GatewayConfig`
- `DeviceIdentity`
- `OperatorAuthState`
- `ConnectChallenge`
- `ConnectParams`
- `GrantedScopes`
- `ConnectionStatus`
- `ChatMessage`
- `ChatRequestState`
- `GatewayFailure`

Important enums:

- `ConnectionPhase`
  `idle`, `connecting`, `waitingChallenge`, `authenticating`, `ready`, `reconnecting`, `failed`
- `MessageRole`
  `user`, `assistant`, `system`, `error`
- `GatewayFailureType`
  `pairingRequired`, `missingWriteScope`, `timeout`, `disconnect`, `authFailed`, `protocolError`, `unknown`

## Protocol Fidelity Requirements

Flutter behavior must remain aligned with `my-openclaw/my-claw.js` for the following rules:

- Device identity is long-lived and persisted locally
- Connect signing payload uses the same data shape and order
- Requested scopes default to the operator scopes from the reference script
- `deviceToken` is preferred over `authToken` when available
- `connect.challenge` drives the auth handshake
- `hello-ok` updates granted scopes and persisted auth state
- `operator.write` is required before sending chat messages
- Requests are tracked first by `requestId`, then also by `runId`
- Assistant text is built by appending delta content from stream events

If any implementation detail must diverge from the JS script because of Dart or mobile platform constraints, the behavior should remain equivalent from the Gateway's point of view.

## App Flow

### Startup Flow

1. Load config, device identity, and auth state from storage
2. If device identity is missing, generate and persist it
3. Render the app shell
4. Show effective config and connection status in the UI
5. Do not auto-send chat on startup

### Connect Flow

1. User taps `Test Connection` on the config screen or `Reconnect` on the chat screen
2. App opens WebSocket to `gatewayUrl`
3. App waits for `connect.challenge`
4. App builds signed `connect` params
5. App authenticates with `deviceToken` or `authToken`
6. On `hello-ok`, app stores granted scopes and any returned `deviceToken`
7. UI transitions to ready state

### Chat Flow

1. User enters a message on the chat screen
2. App blocks send if connection is not ready
3. App blocks send if `operator.write` is absent
4. App sends `chat.send`
5. App creates pending request state with timeout handling
6. Stream events update the in-progress assistant message in real time
7. Final lifecycle or chat event completes the response
8. UI unlocks the input and keeps the transcript in memory

### Reset Flow

The settings screen must provide separate actions for:

- clearing `deviceToken` and auth state
- resetting the full device identity

This allows debugging pairing problems without forcing a full app reinstall.

## UI Design

The first release uses a developer-tool style UI rather than a consumer messenger style.

### Screen 1: Settings / Connection

Required fields:

- Gateway URL
- Auth Token
- Session ID
- Locale
- Timeout

Required actions:

- Save config
- Test connection
- Clear device token
- Reset device identity
- Navigate to chat screen

Required read-only state:

- Effective connection status
- Current device ID summary
- Current granted scopes summary

### Screen 2: Chat

Required sections:

- Header status bar
  - connection phase
  - current session ID
  - device ID summary
  - scopes summary
- message list
- composer area

Required actions:

- send message
- switch session ID
- reconnect
- open settings

Required states:

- sending
- streaming
- failed message display
- missing scope display
- reconnecting display

## State Management

The first release will use `ChangeNotifier`-backed controllers with constructor-based dependency injection. This keeps the stack small for the Android-first MVP while still making state transitions testable.

The state boundaries must map to these responsibilities:

- app settings state
- connection state
- chat transcript state
- pending request state

Controller design must satisfy these conditions:

- easy to unit test
- no protocol logic inside widgets
- streaming updates can render incrementally
- reconnection and auth changes propagate cleanly to the UI

## Storage Strategy

Local storage must cover two categories:

### User Config Storage

- gateway URL
- session ID
- locale
- timeout

### Device/Auth Storage

- auth token
- device identity
- device token
- granted scopes
- operator role

Storage implementation is fixed for the first release:

- use `shared_preferences` for non-sensitive user config
- use secure storage for `authToken`, private key material, `deviceToken`, and granted auth state

Storage must survive app restarts. Reset operations must target only the requested data and leave unrelated state intact.

## Security Notes

The first release is a development client, but these guardrails still apply:

- private key material must never be logged
- auth tokens must never be shown in plain text once saved unless explicitly edited
- error messages should be human-readable without dumping secrets
- reset actions that destroy device identity must require clear confirmation

## Error Handling Requirements

The UI must distinguish these cases clearly:

- pairing required
- missing `operator.write`
- auth rejected
- handshake failure
- timeout
- disconnect / reconnect
- empty response

The user should always know whether the problem is:

- connection reachability
- authentication
- authorization scope
- message execution

## Testing Strategy

### Unit Tests

- config load/save behavior
- device identity generation and restoration
- connect payload construction
- challenge signing helpers
- scope validation
- assistant delta extraction and response aggregation
- error mapping logic

### Integration Tests

- Gateway frame handling across connect/auth flow
- request tracking by `requestId` and `runId`
- persistence updates after `hello-ok`
- disconnect recovery and pending request cleanup

### Widget Tests

- settings form interactions
- chat screen send/disable behavior
- streaming UI updates
- error banners or status cards

## Delivery Criteria

The first release is considered complete when:

- the app runs on Android emulator or device
- config can be edited and persisted
- the app completes `connect.challenge -> connect -> hello-ok`
- device identity persists across launches
- `deviceToken` persists across launches
- granted scopes are visible in the UI
- user messages can be sent
- streaming assistant replies render incrementally
- disconnect, timeout, pairing, and missing-scope states are clearly visible

## Future Expansion Path

The design intentionally leaves room for:

- iOS enablement
- desktop enablement
- transcript persistence
- session list support
- packaging the Gateway client into a reusable Dart module

These are postponed to keep the first release small and testable.

## Constraints And Notes

- Android is the only platform that must work in the first release
- Other Flutter targets may continue to compile incidentally, but they are not release targets
- The reference project root is not currently a Git repository, so this spec cannot be committed yet
