# Fixed Gateway Enforcement Design

## Overview
Ensure the app always connects to the fixed gateway `wss://thisdcw.cn/claw` regardless of any imported bootstrap payload, persisted config, or runtime overrides. The gateway address must be immutable from the client perspective.

## Goals
- Gateway URL is always `wss://thisdcw.cn/claw`.
- No input (bootstrap payload, stored config, runtime overrides) can change the gateway URL.
- UI and logs consistently show the fixed gateway.
- Connection logic always uses the fixed gateway even if a config object carries a different value.

## Non-Goals
- Changing pairing/authentication flows beyond the gateway URL enforcement.
- Modifying roles, scopes, device identity, or token handling semantics.

## Recommended Approach
Use a two-layer enforcement strategy:
1. **Config-layer lock**: normalize any loaded/saved `GatewayConfig` so `gatewayUrl` is always the fixed value.
2. **Connection-layer fallback**: before opening the WebSocket, force the gateway URL to the fixed value even if a config instance is malformed or manually constructed.

This combination guarantees correctness and keeps UI/logs aligned with actual connection behavior.

## Design Details

### 1) Config Repository Enforcement
- On `load()`: if persisted config has a different gateway URL, replace it with the fixed URL before returning.
- On `save()`: ignore any provided gateway URL and persist only the fixed URL.
- Result: any app surface that reads config will always see the fixed gateway.

### 2) Import Bootstrap Token
- When importing a bootstrap token, do **not** use any gateway URL embedded in the payload.
- Store only the token and set config gateway to the fixed URL.
- Any parsed gateway URL is treated as untrusted and ignored.

### 3) Connection Use-Case Enforcement
- Before creating the WebSocket channel, override `config.gatewayUrl` to the fixed URL.
- This is a safety net in case a `GatewayConfig` instance is constructed outside the repository or mutated unexpectedly.

### 4) UI Consistency
- Settings and status pages should reflect the fixed gateway value (no user-editable gateway field).
- This will naturally follow from the config-layer lock.

## Data Flow Summary
- **Bootstrap import** -> token stored, gateway forced to fixed value.
- **Config load/save** -> always normalizes to fixed value.
- **Connect flow** -> always uses fixed URL (even if passed a bad config).

## Error Handling & Edge Cases
- If a persisted config contains a different gateway URL, silently normalize it to the fixed URL.
- If a bootstrap payload contains a different gateway URL, ignore it and proceed with the fixed URL.
- No user-facing error is shown for mismatched gateway URLs since the system is authoritative.

## Backward Compatibility
- Existing installations with previously stored non-fixed gateway values will be corrected on the next load or save.
- No migration step required; normalization is implicit.

## Testing Strategy
- Unit tests (if applicable):
  - Config repository `load()` returns fixed gateway even when stored value differs.
  - Config repository `save()` persists fixed gateway regardless of input.
  - Import bootstrap uses fixed gateway.
  - Connection use-case uses fixed gateway even if `GatewayConfig` is wrong.
- Manual smoke: import a bootstrap code containing a different gateway URL and verify connection still uses `wss://thisdcw.cn/claw`.

## Rollout Notes
- Low risk change, isolated to config/import/connect layers.
- No changes to UI or public API required.
