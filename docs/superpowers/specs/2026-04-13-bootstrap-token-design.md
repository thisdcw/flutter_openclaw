# Bootstrap Token Import Design

## Overview
We are extending OpenClaw to remember a parsed bootstrap token payload for a short window so the app can finish its initial configuration without forcing the user to re-enter credentials. The feature has three pieces: a structured `BootstrapTokenState`, a `BootstrapPayloadParser`, and new application flows that load/save/expire that state while optionally updating the gateway URL configuration.

## Requirements captured
- The repository must track storage of the bootstrap token state (token, gatewayUrl, timestamps). A TTL of 10 minutes is the base default, overridable by callers of the import use case.
- Payloads arrive as either raw tokens or base64-encoded JSON with `url` and `bootstrapToken`. Parsing must fall back gracefully by treating invalid base64 as a raw token without URL.
- Importing a token must persist the structured state, update the gateway config when a URL is provided, and expose the state for later decision-making.
- Activating the app must clear any expired bootstrap token so we never re-use stale credentials.

## Data and parsing
- `BootstrapTokenState` mirrors the required fields plus `isExpired`. It exposes JSON ser/deser helpers with strict typing to avoid corrupt records.
- `BootstrapPayloadParser` tries to decode base64 → JSON → object, verifying `url` and `bootstrapToken`. Failures lead to `gatewayUrl: ''` plus the trimmed input as token so plain tokens still work.

## Repository interactions
- `AuthRepository` now owns load/save/clear lifecycle hooks for `BootstrapTokenState`. Secure storage uses a new key `openclaw.bootstrap_token` and stores JSON-serialized records via the existing `_decodeStoredJsonObject` helper.
- Clearing occurs in the bootstrap use case when a loaded state reports `isExpired` so the repository doesn't hand back useless tokens.

## Application flows
- A new `ImportBootstrapTokenUseCase` coordinates parsing, storing, TTL assignment, and optional gateway URL updates via `ConfigRepository`. The default TTL is 10 minutes, but callers (like unit tests or CLI utilities) can explicitly override via the parameter.
- `BootstrapAppUseCase` now checks the stored bootstrap token right after loading config/identities, clears it when expired, and otherwise leaves it untouched so other code can still read it later (if needed).

## Futureproofing
- Logging uses the existing logger helpers to note when bootstrap tokens are persisted or cleared (we already log repository reads/writes for other pieces). The parser swallow-all exception path keeps import flows resilient to user pasting raw tokens.
- No automated tests for this change set per instructions, but the design keeps each unit small so targeted unit tests could be added if desired later.

Please review this spec and let me know if it captures the intended flow before I go ahead and finalize the implementation plan.
