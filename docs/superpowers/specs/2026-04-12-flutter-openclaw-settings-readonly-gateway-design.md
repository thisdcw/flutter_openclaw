# Flutter OpenClaw Settings Readonly Gateway Design

**Date:** 2026-04-12
**Status:** Approved in chat, written for review
**Target Project:** `flutter_openclaw`

## Goal

Refine the settings screen so app-level preferences are separated from gateway details, while making the gateway configuration clearly read-only.

## Scope

### In Scope

- Move the app language selector into a new "Basic Settings" card
- Make the gateway configuration section display-only
- Remove the save-settings action from the settings screen
- Preserve the current language preference behavior

### Out of Scope

- Any change to gateway protocol, storage schema, or controller data model
- Any new editable gateway fields
- Any change to chat connection flow outside of settings presentation

## Product Intent

The settings screen currently mixes app preferences with technical gateway session details. That makes the screen feel heavier than necessary and suggests that users can edit gateway data that should remain fixed in the client.

The updated screen should communicate two different responsibilities:

- app-level preferences belong in a lightweight "Basic Settings" area
- gateway values are informational and not meant to be changed from the UI

## Information Architecture

The settings screen should keep the existing header and connection summary, then present two separate cards:

1. Basic Settings
   - contains the app language selector only
   - remains interactive
   - continues to save immediately when the value changes
2. Gateway Configuration
   - contains current gateway session details as read-only rows
   - does not render editable text fields
   - does not include a save button

## UI Behavior

### Basic Settings Card

- Show a dedicated section title for general app preferences
- Keep the app language dropdown and its current callback wiring
- Preserve immediate persistence through `saveLocalePreference`

### Gateway Configuration Card

- Keep the existing title and descriptive copy, or equivalent wording
- Present session ID, gateway locale, and timeout as non-editable values
- Use a display style that reads like metadata rather than a form
- Do not show a save or submit action

## Technical Boundaries

This change should stay within the presentation layer plus any tests needed to protect the new layout.

Expected files:

- `lib/src/presentation/screens/settings_screen.dart`
- `lib/src/presentation/widgets/settings_form.dart`
- widget tests covering the updated settings structure

`SettingsController` should continue to support locale preference persistence without requiring new behavior.

## Testing Strategy

The change should be covered with widget-level verification that confirms:

- the language selector appears under a new basic-settings section
- the gateway section no longer exposes editable fields or a save button
- existing localized labels still render correctly

## Delivery Criteria

This work is complete when:

- the settings screen has a clear "Basic Settings" card
- app language is no longer grouped under gateway configuration
- gateway details are visible but not editable
- the save-settings action is removed
- tests cover the new structure
