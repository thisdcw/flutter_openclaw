# Setup Code Gateway URL & Pairing Flow Design

## Overview
Adjust the client to use the setup code `url` as the authoritative `gatewayUrl` (no `/claw` appending), enforce import-time validation for legacy `/claw` URLs, and ensure `deviceToken` is only persisted from the **first successful** bootstrap connection response.

## Goals
- Use setup code `url` verbatim as `gatewayUrl`.
- Do **not** auto-append `/claw` anywhere.
- Reject setup codes whose `url` ends with `/claw` and prompt user to re-fetch.
- First connection uses `bootstrapToken` in `connect.auth.token`.
- On first successful bootstrap connection, persist `hello-ok.auth.deviceToken` and approved scopes, then clear `bootstrapToken`.
- Reconnects use `deviceToken` only.
- If stored `gatewayUrl` ends with `/claw`, block and prompt re-import.

## Non-Goals
- Changing roles, scopes, or device identity mechanics.
- Adding new UI screens beyond user-facing error messages for invalid setup codes.

## Key Decisions
1. **Setup code is the source of truth for `gatewayUrl`.**
2. **Import-time validation** rejects `/claw` URLs with a clear message.
3. **Runtime guard** blocks connections when stored `gatewayUrl` ends with `/claw`.
4. **`deviceToken` persistence is restricted to the first successful bootstrap connection.**

## Behavior Details

### Import Flow
- Decode setup code payload.
- Extract `url` (or `gatewayUrl` if present) and `bootstrapToken`.
- If `url` ends with `/claw`, reject import with a message like:
  - "配对码无效：请重新获取配对码（正确地址应为 wss://thisdcw.cn）。"
- If valid, store:
  - `gatewayUrl = url` (verbatim)
  - `bootstrapToken`

### First Connection (Bootstrap)
- Connect to stored `gatewayUrl` (expected `wss://thisdcw.cn`).
- Await `connect.challenge`.
- Sign challenge with device private key.
- Send `connect` with `auth.token = bootstrapToken`.
- On `hello-ok`:
  - Persist `deviceToken` **only if** this connection used `bootstrapToken`.
  - Persist approved scopes.
  - Clear stored `bootstrapToken`.

### Subsequent Reconnect
- Connect to stored `gatewayUrl`.
- Use `auth.token = deviceToken`.
- Ignore any `deviceToken` returned in responses (do not overwrite).

### Legacy `/claw` Config
- If stored `gatewayUrl` ends with `/claw`, block connection and surface a prompt:
  - "检测到旧版本网关地址，请重新导入配对码。"

## Data Persistence
- `gatewayUrl`: from setup code `url` only.
- `bootstrapToken`: stored only until first successful pairing; cleared after success.
- `deviceToken`: stored only from first successful bootstrap connection.
- `approvedScopes`: stored from the same `hello-ok` response as `deviceToken`.

## Error Handling
- Import error for `/claw` setup code URL with user-facing prompt.
- Runtime error if stored `gatewayUrl` ends with `/claw` with re-import guidance.

## Testing Strategy (No Execution Here)
- Unit: setup code parser returns `url` and `bootstrapToken`.
- Unit: import rejects `/claw` URLs.
- Unit: on successful bootstrap connection, `deviceToken` persisted and `bootstrapToken` cleared.
- Unit: on reconnect, `deviceToken` not overwritten.
- Unit: connection blocked if stored `gatewayUrl` ends with `/claw`.

## Rollout Notes
- This change intentionally diverges from the previous fixed `/claw` gateway enforcement.
- Users with cached `/claw` configs must re-import setup code.
