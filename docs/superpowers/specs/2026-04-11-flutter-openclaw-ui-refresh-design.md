# Flutter OpenClaw UI Refresh Design

**Date:** 2026-04-11
**Status:** Approved in chat, written for review
**Target Project:** `flutter_openclaw`

## Goal

Refresh the current Flutter OpenClaw interface so it feels like a polished AI assistant app while preserving all existing behavior, data flow, and feature logic.

## Scope

### In Scope

- Visual refresh for the current settings and chat experience
- Theme upgrade for color, typography, spacing, shape, and component styling
- Layout refinement for the settings screen and chat screen
- Improved visual hierarchy for connection state, errors, actions, and empty states
- Safer, clearer presentation of existing status information

### Out of Scope

- Any change to OpenClaw protocol behavior
- Any change to controllers, use cases, repositories, or storage behavior
- New product features
- New navigation paths
- New data requirements
- Message history persistence or session-management expansion

## Product Intent

The current app is functional but visually plain. The refresh should make the product feel like a real AI assistant app instead of a development prototype, while still reflecting that OpenClaw is connected to a live gateway and connection state matters.

The desired result is:

- calm and modern
- intelligent and productized
- mobile-friendly
- slightly technical, without looking like a debug console

## Visual Direction

The chosen direction is **soft futurism**.

This means:

- a light, cool-toned background instead of flat white
- blue-cyan accents instead of warm orange
- elevated surfaces with gentle contrast and rounded corners
- a cleaner hierarchy between app shell, status cards, forms, and conversation
- an interface that feels closer to a modern AI assistant than a default Flutter form layout

The design should avoid:

- loud neon sci-fi styling
- generic SaaS card piles
- overly playful consumer-chat visuals
- harsh dark-mode-only presentation

## Design Principles

- Preserve behavior exactly; only the presentation layer changes
- Make the primary path obvious: configure, test, then enter chat
- Let connection state feel important without overwhelming the UI
- Give the chat experience more product polish than the settings experience
- Use a single coherent visual system across buttons, cards, inputs, chips, and banners

## Information Architecture

### Settings Screen

The settings screen should shift from a plain stacked form into four clear sections:

1. Hero header
   - product name
   - short assistant-oriented subtitle
   - current connection phase shown prominently
2. Connection summary card
   - current phase
   - device ID summary
   - granted scopes summary
3. Configuration card
   - gateway and session fields grouped into one polished input surface
4. Action area
   - primary actions emphasized
   - destructive or reset-style actions visually secondary
   - `Open Chat` presented as the natural continuation of the setup flow

### Chat Screen

The chat screen should feel like the main AI assistant experience rather than a basic message list.

It should contain:

1. Refined top bar
   - product/chat title
   - clearer live status badge
2. Inline status banners
   - blocked send reason
   - chat error state
3. Conversation area
   - improved empty state that invites first use
   - more polished assistant and user message styling
4. Composer dock
   - visually separated input surface
   - stronger AI-assistant affordance

## Component Refresh Plan

### Theme

`app_theme.dart` should define the visual system for the whole app:

- light cool-neutral background
- blue-cyan primary palette
- consistent rounded corners
- softer card and surface treatment
- improved input decoration theme
- clearer button hierarchy
- refined chip styling for connection state

### Connection Summary Card

`connection_summary_card.dart` should become a higher-signal status panel:

- stronger heading treatment
- grouped rows or tiles for phase, device ID, and scopes
- better contrast between labels and values
- more deliberate spacing and surface styling

### Settings Form

`settings_form.dart` should remain behaviorally identical but visually upgraded:

- inputs styled as a cohesive group
- more comfortable spacing rhythm
- button layout that reflects primary and secondary actions
- no changes to callback wiring or field semantics

### Status Badge

`status_badge.dart` should move beyond a default `Chip` feel:

- more refined shape and padding
- color treatment that maps well to connection status
- better visual consistency with the new theme

### Message Bubbles

`message_bubble.dart` should better distinguish:

- user messages
- assistant messages
- error messages
- streaming state

The refresh should rely on spacing, surface, and color rather than dramatic effects.

### Chat Composer

`chat_composer.dart` should feel like a modern assistant input dock:

- clearer container styling around the input
- improved button prominence
- stronger visual relationship between input and send action
- same enable/disable and sending logic as today

## Motion And Interaction

Motion should be subtle and low-risk:

- soft transitions from existing Material behavior
- no dependency on custom animation packages
- no complex choreography
- no interaction changes that alter how the app is used

## Technical Boundaries

This work is limited to presentation-layer files and theme wiring:

- `lib/src/app/app_theme.dart`
- `lib/src/presentation/screens/settings_screen.dart`
- `lib/src/presentation/screens/chat_screen.dart`
- `lib/src/presentation/widgets/connection_summary_card.dart`
- `lib/src/presentation/widgets/settings_form.dart`
- `lib/src/presentation/widgets/status_badge.dart`
- `lib/src/presentation/widgets/message_bubble.dart`
- `lib/src/presentation/widgets/chat_composer.dart`

The following must not change in behavior:

- `SettingsController`
- `ConnectionController`
- `ChatController`
- use cases, repositories, storage, crypto, and gateway logic

## Accessibility And Responsiveness

The refresh should preserve good readability on phone-sized layouts and remain usable on larger widths.

Requirements:

- sufficient text contrast
- clear button labels
- no hidden critical state behind color alone
- layouts that still work when text wraps
- no fragile assumptions about exact screen width

## Validation Strategy

Verification should focus on making sure presentation changed while behavior remained intact.

Minimum checks:

- Flutter analysis passes
- existing tests still pass
- screen structure still exposes the same actions
- send/disabled states remain driven by the same controller logic

## Delivery Criteria

This refresh is complete when:

- the app clearly reads as an AI assistant product
- the settings page feels intentional rather than like a raw form
- the chat page feels like the primary product surface
- connection and error states are more legible
- no feature behavior has changed

## Risks And Mitigations

### Risk: Visual changes accidentally alter behavior

Mitigation:

- keep edits scoped to theme and presentation widgets
- preserve all existing callbacks and controller checks

### Risk: Overdesign makes the app harder to scan

Mitigation:

- keep the palette calm
- prioritize hierarchy and clarity over decoration

### Risk: Mobile layout becomes fragile

Mitigation:

- use flexible layout primitives already present in Flutter
- avoid overfitting to a single device size
