# Android Keystore signer + method channel

## Overview
- Add an Android-only keystore helper that can ensure an Ed25519 keypair, sign payloads, and clear the key.
- Expose keystore operations to Flutter via a new `openclaw/keystore` `MethodChannel` that lives alongside the existing `openclaw/media` channel in `MainActivity`.
- Keep the Dart-facing API simple: `result.success` / `result.error` only, mirroring the current `saveImage` handler.

## Constraints
- All native work lives inside `MainActivity` and a new `KeystoreSigner.kt`, without altering Flutter code.
- Base64 encoding: raw public key should be returned via regular base64, signatures via base64 URL-safe no padding, as the helper already exposes.
- No structured error codes; maintain the existing simple channel contract.
- This is a Kotlin-only change; no tests or Dart changes.

## Approaches
1. **New helper + dedicated channel (chosen)** – add `KeystoreSigner.kt` implementing the provided keystore logic, instantiate it in `MainActivity.configureFlutterEngine`, then wire the new `openclaw/keystore` channel to call `ensureKeypair`, `signPayload`, and `clearKeypair`. Pros: clean separation, reusable helper, matches requested API. Cons: touches two Kotlin files, but both are straightforward changes.
2. **Inline keystore logic inside `MainActivity`** – keep everything in `MainActivity` without a helper class. This would avoid adding a file but would clutter `MainActivity` with keystore boilerplate, hurting readability for future maintenance.
3. **Flutter plugin / external service** – expose keystore via a platform interface built in Dart. This adds unnecessary complexity and drift from the current simple channel-based integration, so it’s overkill for this task.

## Implementation Sketch
- Create `KeystoreSigner` as described: load AndroidKeyStore, lazily generate Ed25519 keypair, expose `ensureKeypair`, `sign`, `clear`, and helper methods for Base64 encodings.
- In `MainActivity.configureFlutterEngine`, instantiate `KeystoreSigner` once and add a second `MethodChannel` (`openclaw/keystore`). Handle `ensureKeypair`, `signPayload`, and `clearKeypair` exactly as the provided snippet shows, converting payload strings to UTF-8 bytes before signing.
- Share the existing `CHANNEL_NAME` constant namespace and add new constants for `KEYSTORE_CHANNEL`, `KEY_ALIAS`, and the keystore request code.
- Align the method handler with the saveImage handler style: call `result.success(...)` immediately, no additional threading or error wrapping beyond what Kotlin already throws.

## Risks & QA
- Keystore generation requires Ed25519 support (Android 11+). Testing on a device/emulator that uses the AndroidKeyStore is necessary to confirm no `IllegalStateException`. But per instructions, no automated tests are added.

## Questions
- Clarified: keep the method channel API matching `saveImage` semantics with `result.success` and `result.error`, and no structured error codes.
