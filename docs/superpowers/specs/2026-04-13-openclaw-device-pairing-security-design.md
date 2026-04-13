# OpenClaw Device Pairing Security (Flutter Android)

## Summary
Harden the Flutter Android client so it no longer relies on a shared gateway token and no longer stores device private keys in app storage. The client will pair using a short-lived bootstrap token (manual input or QR import), then store the per-device `deviceToken`. Device identity and challenge signing are moved into Android Keystore with Ed25519 keys (API 28+).

## Goals
- Remove shared gateway token usage from the client’s long-term auth path.
- Use device-bound `deviceToken` after pairing, with challenge signing for every connect.
- Store device private keys only in Android Keystore (no PEM in app storage).
- Support bootstrap token import by manual input and QR scan.
- Enforce bootstrap token expiry (10 minutes) with friendly UI messaging.
- Provide recovery actions (clear pairing state, reset device identity).

## Non-Goals
- iOS implementation.
- Low Android API (<28) compatibility.
- Admin approval UI or server-side pairing workflow.

## Assumptions
- Minimum Android SDK is raised to API 28 (Android 9).
- Bootstrap token import is a base64-encoded JSON string with:
  - `url` (ws/wss)
  - `bootstrapToken`
- Bootstrap tokens expire in 10 minutes from import time.
- Pairing success is indicated by receiving `hello-ok.auth.deviceToken`.

## Architecture Overview
- **Device identity**: Generated and stored via Android Keystore. Flutter stores only `deviceId` and `publicKey`.
- **Auth flow**: Prefer `deviceToken` if present; otherwise use non-expired bootstrap token.
- **Persistence**:
  - `DeviceIdentity` (deviceId + publicKey) in secure storage.
  - `OperatorAuthState` (deviceToken + scopes) in secure storage.
  - `BootstrapTokenState` (token + url + importedAt + expiresAt) in secure storage.
- **Scopes**: Default to `operator.read` and `operator.write` only.

## Data Model Changes
### DeviceIdentity
- Remove `privateKeyPem` from the model and storage.
- Keep `id` and `publicKey`.

### New: BootstrapTokenState
Persisted securely with:
- `token` (string)
- `gatewayUrl` (string)
- `importedAt` (epoch ms)
- `expiresAt` (epoch ms)

Rules:
- On import, persist state immediately.
- On pairing success (deviceToken obtained), keep the bootstrap token only if it has not expired; otherwise clear it.
- If expired before pairing, clear and prompt user to re-import.

## Device Identity & Signing
- Add Android platform channel to:
  - Generate Ed25519 keypair in Keystore if missing.
  - Return public key bytes (base64).
  - Sign the connect payload and return signature (base64url).
- Flutter `ConnectSigner` will no longer handle private key decoding.
- Signature payload remains the same as current protocol logic.

## Connect Flow
1. Load device identity (id + publicKey). Create via Keystore if missing.
2. Resolve auth:
   - If `deviceToken` exists: use it.
   - Else if bootstrap token exists and not expired: use it.
   - Else: show “需要导入配对码” and abort.
3. Wait for `connect.challenge`.
4. Build connect payload and request signature from Keystore.
5. Send connect request.
6. On success:
   - Persist `deviceToken` + scopes.
   - If bootstrap token expired, clear it; otherwise keep it.

## UI & UX
- Settings screen: add “Pairing” card with:
  - Device ID
  - Pairing status (paired/unpaired)
  - Bootstrap token expiry time (if present)
- Add actions:
  - Import pairing code (manual input)
  - Scan pairing QR
  - Clear pairing state
  - Reset device identity
- Error messages:
  - Bootstrap token expired: prompt to re-import.
  - Pairing required: prompt to import or re-pair.

## Security Considerations
- No shared gateway token stored or used as a default auth path.
- Device private key never leaves Keystore.
- Bootstrap token is time-bounded and cleared on expiry.
- Scopes are restricted by default to least privilege.

## Migration
- Remove hardcoded gateway token from defaults.
- Existing stored PEM keys are ignored and cleared on next reset.
- Users will need to re-pair if they were using shared token.

## Testing
- Unit tests for:
  - Bootstrap token expiry logic.
  - Auth selection (deviceToken vs bootstrapToken).
- Integration tests for connect flow (mocking Keystore signer).

## Risks
- Keystore Ed25519 availability depends on API 28+.
- If Keystore signing fails, the app cannot authenticate.

## Rollout Notes
- Bump Android minSdk to 28.
- Communicate re-pairing requirement to existing users.
