# Flutter OpenClaw Chat Density And Inline Images Design

**Date:** 2026-04-12
**Status:** Approved in chat, written for review
**Target Project:** `flutter_openclaw`

## Goal

Improve the chat experience so it behaves more like a practical AI assistant conversation surface:

- the chat layout should be denser and fit more visible conversation on screen
- assistant message content should render inline images when the message contains Markdown image syntax or standalone image URLs

## Scope

### In Scope

- reduce vertical space usage in the chat screen
- simplify the large card-like chat framing
- shrink message bubble visual weight
- slim down the composer area
- reduce header and prompt-card height
- parse and render inline images from message text
- support both Markdown image syntax and plain image URLs

### Out of Scope

- changes to chat sending logic
- changes to controller state transitions
- changes to stream aggregation or message storage
- changes to gateway protocol behavior
- full Markdown rendering beyond lightweight image extraction

## Product Intent

The app is moving closer to a real AI assistant experience. The chat screen should prioritize message visibility over decorative framing. Messages need to feel easy to scan, and generated content that references images should display those images inline instead of showing raw markup or raw URLs.

## Design Direction

The existing soft-futurist look remains, but the chat screen becomes more utility-focused and information-dense.

That means:

- less vertical chrome
- less oversized panel framing
- smaller bubble padding
- more transcript visible at once
- image rendering treated as part of the natural message flow

## Layout Changes

### Header

The top app bar should stay present, but use less height.

Adjustments:

- smaller subtitle presence
- tighter spacing around status and settings
- no extra decorative vertical padding

### Connection / Setup Prompt

The current setup prompt is too large for a primary chat surface.

It should become:

- a compact inline prompt
- short title + short description
- one small settings action
- visually distinct but not dominant

### Chat Transcript Container

The outer conversation panel should be lighter and less bulky.

Adjustments:

- reduce or remove the thick card feeling
- use smaller padding around the transcript
- preserve enough contrast to separate transcript from page background
- maximize usable message area

### Composer

The composer should become flatter and thinner.

Adjustments:

- smaller padding
- reduced border radius
- less decorative shadow
- keep send affordance clear

## Message Bubble Changes

### Density

Message bubbles should use:

- smaller inner padding
- reduced vertical margins
- reduced corner radius
- softer or no heavy shadow

The goal is to keep bubbles readable while fitting more content on screen.

### Role Separation

User, assistant, and error messages still need clear distinction, but via subtle styling rather than oversized surfaces.

## Inline Image Rendering

### Supported Formats

The renderer should support:

1. Markdown image syntax
   - `![alt text](https://example.com/image.png)`
2. Plain image URLs inside message text
   - `https://example.com/image.png`

### Rendering Rules

The message renderer should split message text into ordered content blocks.

Supported block types:

- plain text
- image

If a message contains both text and images, blocks should render in original order.

Examples:

- text only -> render as text
- image only -> render image
- text + image + text -> render text block, image block, text block

### Scope Of Rendering

This image parsing should apply to displayed message content, not just assistant-only output. Any message shown in the transcript that includes a supported image pattern may render the image inline.

### Failure Handling

If an image fails to load:

- the rest of the message must still render
- show a lightweight fallback state
- preserve access to the URL or image reference in some readable form

## Technical Approach

The implementation should stay inside the presentation layer.

Expected file surface:

- `lib/src/presentation/screens/chat_screen.dart`
- `lib/src/presentation/widgets/message_bubble.dart`
- `lib/src/presentation/widgets/chat_composer.dart`

Optional support extraction if helpful:

- a small private parser/helper in `message_bubble.dart`
- or a focused presentation helper file if the parsing logic becomes too large for the widget file

No domain or controller layer changes are required for this iteration.

## Content Parsing Strategy

Use a lightweight parser rather than introducing a full Markdown rendering dependency.

Required behavior:

- detect Markdown image tokens
- detect standalone image URLs
- preserve non-image text
- keep original order stable

The parser should be conservative:

- only recognize obvious image patterns
- avoid turning arbitrary non-image links into images unless they clearly match image usage expectations

## Accessibility And Usability

- text remains readable at smaller visual density
- images should respect available width
- images should use rounded corners consistent with the app
- image loading states should not collapse layout unpredictably
- long conversations should remain easy to scroll

## Delivery Criteria

This work is complete when:

- chat screen visibly shows more conversation content at once
- large chat card framing no longer dominates the layout
- prompt and composer occupy less vertical space
- Markdown image syntax renders as inline images
- plain image URLs render as inline images
- mixed text and images preserve ordering
- failed image loads degrade gracefully
- no controller or gateway logic has changed

## Risks And Mitigations

### Risk: image parsing incorrectly breaks normal text

Mitigation:

- keep parsing rules narrow
- preserve unmatched content as plain text

### Risk: denser layout becomes harder to scan

Mitigation:

- reduce visual weight without removing role distinction
- keep enough spacing between messages

### Risk: image rendering introduces oversized content

Mitigation:

- constrain image width to available chat width
- preserve consistent image styling and spacing
