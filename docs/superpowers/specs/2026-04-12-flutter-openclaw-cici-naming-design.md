# Flutter OpenClaw Cici Naming Design

**Date:** 2026-04-12
**Status:** Approved in chat, written for review
**Target Project:** `flutter_openclaw`

## Goal

Rename the user-visible product identity of Flutter OpenClaw to `Cici`, using a short English name that reflects the AI assistant persona while keeping internal technical identifiers stable.

## Scope

### In Scope

- Rename all user-visible app names and titles to `Cici`
- Update in-app localized titles that currently expose `OpenClaw`
- Update platform display names for Android, iOS, macOS, web, and Windows where the user sees the product name
- Keep the naming consistent with the newly created app icon branding

### Out of Scope

- Renaming the repository folder
- Renaming Dart package imports such as `flutter_openclaw`
- Renaming Android application ID, Kotlin package, or iOS/macOS bundle identifiers
- Rewriting protocol documentation that discusses OpenClaw as the backend technology
- Introducing a second public-facing brand such as `Cici AI` or `Hey Cici`

## Product Intent

The app should feel like a polished AI assistant with a memorable assistant-style name rather than a technical shell around OpenClaw. The user chose:

- English name
- short and memorable
- all user-visible naming should become `Cici`

This means the visible product identity should shift fully to `Cici`, while the underlying implementation can continue to reference OpenClaw where it is functioning as a technical platform name.

## Chosen Naming Direction

The approved naming direction is:

- Public product name: `Cici`
- Public chat title: `Cici`
- Assistant persona name: `Cici`

Rejected alternatives:

- `Cee`: too abstract and less assistant-like
- `Xi`: closer to the original sound but weaker as a friendly AI brand
- `Cici AI`: more explanatory, but less clean and less app-like

## Naming Rules

### User-Visible Surfaces

Every user-facing product label should prefer `Cici` over `OpenClaw`.

This includes:

- localized app title strings
- chat screen title
- Android launcher label
- iOS display name
- web page title and mobile web app title
- Windows and macOS visible app name where configured

### Internal Technical Surfaces

Internal identifiers should remain unchanged unless there is a strong technical need.

Keep unchanged:

- repository name `flutter_openclaw`
- Dart package name `flutter_openclaw`
- Android application ID
- Kotlin package path
- Xcode target and product internals unless required for visible naming only

This keeps rename risk low while still delivering a complete public rebrand.

## Tone And Brand Fit

`Cici` should feel:

- short
- friendly
- lightweight
- assistant-oriented
- compatible with the new icon mark

It should not be expanded into a longer marketing name in the current app shell.

## UX Implications

The rename should make the app feel less like a protocol client and more like a product.

Examples of the intended shift:

- `OpenClaw` -> `Cici`
- `OpenClaw Chat` -> `Cici`
- `flutter_openclaw` on launcher or browser title -> `Cici`

This should reduce visible technical friction for end users without changing any backend behavior.

## Technical Boundaries

The implementation should prefer shallow, safe renaming on presentation and platform metadata surfaces.

Expected touch points include:

- localization source files under `lib/l10n/`
- Android `android:label`
- iOS `CFBundleDisplayName`
- web manifest and HTML title metadata
- Windows and macOS app-display metadata where currently defaulting to `flutter_openclaw`

The implementation should avoid touching import paths, package declarations, or protocol-layer wording unless those strings are directly presented to the user as the product name.

## Delivery Criteria

The rename is successful if:

- the user sees `Cici` as the app name across supported surfaces
- in-app titles no longer say `OpenClaw`
- technical identifiers remain stable behind the scenes
- no new mixed-brand state is introduced in normal user-facing screens

## Validation Strategy

Verification should focus on visible naming consistency rather than backend behavior.

Minimum checks:

- localized app title resolves to `Cici`
- chat title resolves to `Cici`
- Android launcher label is `Cici`
- iOS display name is `Cici`
- web title and manifest name are `Cici`
- Windows/macOS visible name no longer exposes `flutter_openclaw` where configurable

## Open Questions Resolved In Chat

- Naming language: English
- Final name: `Cici`
- User-visible naming policy: rename all visible product naming to `Cici`
- Technical identifiers: keep stable unless necessary for display-only metadata
