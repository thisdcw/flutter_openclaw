# Flutter OpenClaw Localization Design

**Date:** 2026-04-12
**Status:** Approved in chat, written for review
**Target Project:** `flutter_openclaw`

## Goal

Add bilingual app localization for Flutter OpenClaw so the full current app interface can display in English or Simplified Chinese, with language selection available in settings and the default behavior following the system language.

## Scope

### In Scope

- full app UI localization for the current visible interface
- support for English and Simplified Chinese
- app language selection in the settings screen
- default language behavior that follows the system locale
- persisted user preference for app language override
- localization structure that can support more languages later

### Out of Scope

- translating OpenClaw gateway protocol values
- changing OpenClaw backend behavior
- changing connection, chat, or auth business logic
- adding languages beyond English and Simplified Chinese in this iteration
- redesigning navigation or page structure

## Product Intent

The current app feels like an English-only prototype. It should feel usable for Chinese-speaking users without losing the current English experience.

The desired result is:

- first launch respects the device language automatically
- users can explicitly switch the interface language in settings
- the setting applies to the full app, not just one page
- future languages can be added without changing the architecture again

## Design Principles

- keep UI language separate from gateway request configuration
- use Flutter's standard localization path instead of a custom string system
- make the language choice explicit and safe through fixed options, not free-form input
- preserve backward compatibility for existing stored configuration
- update visible text comprehensively so the UI does not become mixed-language

## Localization Architecture

### Chosen Approach

Use Flutter's official `gen_l10n` pipeline with generated `AppLocalizations`.

This is the right fit because it:

- integrates cleanly with `MaterialApp`
- scales to additional languages later
- supports placeholders and standard Flutter localization behavior
- avoids building and maintaining a custom translation layer

### Supported Languages

This iteration supports:

- English
- Simplified Chinese

The structure should leave room for future additions such as Traditional Chinese or Japanese by extending localization resources and the app language preference model.

## Locale Preference Model

### Separate UI Language From Gateway Locale

The app already has `GatewayConfig.locale`. That field appears to represent a gateway or session-level locale value and should not control the Flutter interface language.

The app needs a separate UI language preference so these concerns do not get coupled together.

Example of why separation matters:

- a user may want the app UI in Chinese
- the gateway session may still need to send `en-US` or another value

These are different concerns and should remain independently configurable.

### Preference States

The app language preference should support three stable states:

- `system`
- `en`
- `zh-Hans`

Behavior:

- `system` means the app follows the device locale
- `en` forces English
- `zh-Hans` forces Simplified Chinese

## App Wiring

### MaterialApp Integration

`OpenClawApp` should listen to the current app language preference from `SettingsController` and configure `MaterialApp` accordingly.

Expected behavior:

- when preference is `system`, `MaterialApp.locale` remains `null`
- when preference is `en`, `MaterialApp.locale` is set to English
- when preference is `zh-Hans`, `MaterialApp.locale` is set to Simplified Chinese

`MaterialApp` should also declare:

- generated localization delegates
- supported locales

This ensures both app text and built-in Flutter Material strings localize correctly.

### Top-Level Rebuild Behavior

Language changes must refresh the whole app surface, not only the settings page.

The easiest path in the current architecture is to have `OpenClawApp` rebuild when `SettingsController` notifies listeners after a language preference update.

## Persistence Strategy

### Separate Shared Preferences Key

Store the UI language preference independently from the current `gateway_config` JSON blob.

Recommended storage key:

- `app_locale_preference`

Recommended stored values:

- `system`
- `en`
- `zh-Hans`

### Migration Behavior

Existing installs should not require a migration step that rewrites old config data.

If no saved app language preference exists:

- default to `system`

This makes existing users automatically follow their device language after upgrading, while keeping the current stored gateway config untouched.

## Settings Experience

### App Language Control

The settings screen should gain a dedicated app language section.

The control should use explicit fixed options rather than a text input.

Options:

- Follow system
- English
- Simplified Chinese

This setting should:

- update immediately when changed
- persist immediately
- affect the full app interface

### Keep Gateway Locale Separate

The existing editable `locale` field in gateway settings should remain available because it serves a different purpose.

To reduce confusion, it should be relabeled explicitly as:

- `Gateway Locale`

This makes it clear that it is not the same as the app display language.

## Text Migration Plan

All current user-visible hardcoded interface text should move into localization resources.

Expected coverage includes:

- chat screen title and empty state
- settings screen title, subtitles, and card headings
- connection status helper text
- button labels
- tooltips
- form labels and hints
- chat and connection banners
- image picker error messages

The following should not be translated as user-facing copy unless intentionally mapped for display:

- protocol scopes such as `operator.write`
- raw phase values used as technical state identifiers
- storage keys and config property names

## Testing Strategy

### Unit Tests

Add tests for app language preference persistence:

- missing value defaults to `system`
- saved `en` value loads correctly
- saved `zh-Hans` value loads correctly

These tests should remain independent from `GatewayConfig` persistence tests.

### Widget Tests

Add widget coverage for app-level language application:

- system-follow behavior can display Chinese when the ambient device locale is Chinese
- explicit English preference renders English UI text
- explicit Simplified Chinese preference renders Chinese UI text

### Regression Checks

Verification should confirm:

- analysis still passes
- existing config persistence behavior still works
- the full app rebuilds after language changes
- no major page remains partially untranslated

## Delivery Criteria

This work is complete when:

- the current full app UI supports English and Simplified Chinese
- the default language follows the system locale
- settings offers a clear app language selector
- explicit language selection persists across launches
- UI language and gateway locale are stored and managed separately
- localization is wired through Flutter's standard localization system
- the code structure can accept more languages later without architectural rework

## Risks And Mitigations

### Risk: UI language gets coupled to gateway locale

Mitigation:

- introduce a dedicated app language preference model
- store it separately from `GatewayConfig`

### Risk: Some strings remain hardcoded and create a mixed-language UI

Mitigation:

- perform a full search across presentation files for visible text
- migrate labels, hints, buttons, tooltips, banners, and empty states together

### Risk: Language changes do not refresh already-open screens

Mitigation:

- make `OpenClawApp` rebuild from `SettingsController` notifications
- keep locale wiring at the app root

### Risk: The settings page becomes confusing because two locale concepts exist

Mitigation:

- label the new control clearly as app language
- relabel the existing config field as gateway locale

### Risk: Future language additions require repeated structural changes

Mitigation:

- use `gen_l10n`
- model the preference as stable enumerated values
- keep supported locales centralized at the app root
