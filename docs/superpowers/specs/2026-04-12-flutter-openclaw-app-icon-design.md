# Flutter OpenClaw App Icon Design

**Date:** 2026-04-12
**Status:** Approved in chat, written for review
**Target Project:** `flutter_openclaw`

## Goal

Design a distinctive production-ready app icon for Flutter OpenClaw that feels like a real AI product, reflects the `OpenClaw` name through an `O/C + claw` symbol, and works well across Android, iOS, macOS, and web icon surfaces.

## Scope

### In Scope

- A new brand-oriented app icon concept for Flutter OpenClaw
- A symbol built from `O` and `C` letterforms with subtle claw semantics
- Icon color direction aligned with the app's light cool-toned UI
- Platform-friendly icon composition that remains legible at small sizes
- Guidance for final exported assets and implementation targets

### Out of Scope

- A full brand system beyond the app icon
- A mascot-style lobster or crab illustration
- In-app UI redesign beyond maintaining visual alignment with the current theme
- Animated icon behavior
- Marketing illustrations, splash screens, or store banners

## Product Intent

Flutter OpenClaw is not a game and should not look playful or novelty-first. It is a technical AI client connected to a live OpenClaw gateway, with chat, multimodal input, and future canvas-host capability. The icon should therefore feel:

- productized
- intelligent
- technical without looking developer-only
- memorable without becoming cartoonish

The icon should make the app feel closer to a polished AI operator tool than a default Flutter shell.

## Chosen Direction

The approved direction is **letterform fusion**:

- combine `O` and `C` into one compact brand mark
- embed the idea of a claw in the geometry rather than by drawing an animal
- keep the overall tone between pure enterprise minimalism and overt character design

This gives the icon a professional silhouette first, with the claw idea appearing as a second-read detail.

## Core Concept

The icon should use a rounded-square app tile with a cool dark-to-mid-tone background. Inside it sits a single fused symbol:

- an outer `O`-like enclosure or arc that gives the mark stability
- an inner `C`-like form that reads clearly at icon size
- a sharpened opening or notch on the `C` that suggests a claw tip

The mark should feel like it is slightly opening or reaching forward, not static or closed. This helps connect the symbol to the product's agentic, responsive personality without adding literal motion effects.

## Visual Character

The icon should land in the approved **middle state**:

- more professional than expressive
- more distinctive than generic SaaS geometry
- slightly alive in the details, especially at the claw opening

It should avoid:

- cute lobster faces
- obvious pincers mirrored left and right
- overcomplicated negative space puzzles
- generic gradient blobs
- sharp cyberpunk neon styling

## Shape System

### Tile

- Use a rounded square app tile suitable for iOS and adaptable to Android and web
- Keep edge softness modern, but not overly bubbly
- Preserve enough interior padding so the symbol breathes on smaller launchers

### Symbol

- Build a single centered mark rather than separate letters
- The `O` structure should provide the container and overall silhouette
- The `C` structure should create the main directional read
- The claw expression should come from one deliberate cut, taper, or angled gap

### Small-Size Legibility

The mark must still read cleanly at:

- 16 px favicon scale
- 32 px desktop dock/taskbar scale
- 48 px to 64 px Android launcher scale

To support this:

- avoid thin strokes
- avoid multiple tiny internal counters
- keep the main notch large enough to survive downscaling
- prefer bold silhouette over fine detail

## Color Direction

The approved palette direction is **cool cyan-green AI glow**, adapted to the existing blue UI rather than replacing it entirely.

### Palette Intent

- primary energy from cyan-blue
- secondary highlight from cool aqua/green
- grounding depth from deep ocean blue

### Usage

- dark or mid-dark tile background for contrast on bright launchers
- brighter cyan/aqua treatment on the symbol
- controlled highlight edge or gradient shift to give the icon a current AI-product feel

### Color Constraints

- do not use loud fluorescent green
- do not drift into purple
- do not use flat white as the main tile background
- keep enough contrast for the symbol to hold on light and dark surrounding environments

## Relationship To Existing UI

The app theme already uses light cool backgrounds with blue accents. The icon should feel like the concentrated, higher-contrast expression of that same product world:

- same family as the app's blue-first palette
- slightly deeper and more premium than the in-app surfaces
- distinct enough that the icon does not look like the default Flutter placeholder

This means the icon can be darker and more saturated than the app screens, while still belonging to the same brand language.

## Implementation Guidance

The final asset set should be created from one master source, then exported consistently across platform requirements.

Expected outputs:

- master icon artwork at 1024 x 1024
- Android launcher-ready foreground/background or full adaptive-safe export
- iOS app icon exports
- macOS app icon exports
- web icons and favicon replacements

If only one master visual is produced first, it should be designed with safe margins so it can be adapted into all launcher and maskable contexts without redrawing the symbol.

## Delivery Criteria

The icon design is successful if:

- it is recognizably different from the default Flutter icon
- it reads as a modern software product icon, not a mascot badge
- `O/C` structure is visible without requiring explanation
- the claw idea is present but subtle
- it remains identifiable at small sizes
- it visually fits the current OpenClaw app theme

## Verification Strategy

Before replacing platform assets, the implementation phase should verify:

- the symbol remains readable at 1024 px, 192 px, 64 px, 32 px, and 16 px
- the icon still works when viewed on light and dark launcher backgrounds
- Android adaptive and web maskable crops do not cut into the core symbol
- exported assets are updated consistently across Android, iOS, macOS, and web

## Open Questions Resolved In Chat

- Primary concept: `O/C` letterform fusion
- Palette direction: cool cyan-green AI tone
- Brand personality: professional core with slight claw character
- Review style: skip intermediate visual previews and present finished work
