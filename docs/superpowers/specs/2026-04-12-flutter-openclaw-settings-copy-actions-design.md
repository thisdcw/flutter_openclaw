# Flutter OpenClaw Settings Copy Actions Design

**Date:** 2026-04-12
**Status:** Approved in chat, written for review
**Target Project:** `flutter_openclaw`

## Goal

Add elegant one-tap copy actions for the settings screen's device ID and granted scopes, with lightweight success feedback.

## Scope

### In Scope

- Add copy affordances to the connection summary card
- Support copying the device ID value
- Support copying the granted scopes value
- Show a success confirmation after each copy

### Out of Scope

- Copy actions for the phase field
- New settings sections or larger layout changes
- Any change to connection data sources or controller behavior

## Product Intent

The settings screen already surfaces technical values that users may need to paste elsewhere. Device ID and granted scopes are the two values most likely to be reused, so they should be easy to copy without making the screen feel noisy or overly utilitarian.

The interaction should feel subtle and polished:

- the content remains the main focus
- the copy action is easy to discover
- feedback confirms success without interrupting the user

## Interaction Design

- Add a low-contrast copy icon at the end of the value row for:
  - device ID
  - granted scopes
- Keep the phase tile display-only
- Keep the icon visually secondary to the value text
- Let long values use the available width while keeping the icon visible at the trailing edge

## Feedback Design

- On tap, copy the value to the system clipboard immediately
- Show a lightweight `SnackBar` confirming success
- Use field-specific confirmation copy, such as:
  - copied device ID
  - copied granted scopes
- Avoid dialogs, full-width banners, or persistent success state

## Technical Boundaries

This change should stay in the presentation and localization layers.

Expected files:

- `lib/src/presentation/widgets/connection_summary_card.dart`
- localization files needed for tooltip and success-feedback copy

## Delivery Criteria

This work is complete when:

- device ID can be copied from the settings screen
- granted scopes can be copied from the settings screen
- both actions show a success prompt
- the summary card still feels visually clean
