# Flutter OpenClaw Multimodal Chat And Auto Connect Design

## Goal

Upgrade `flutter_openclaw` from text-only chat to multimodal chat with multi-image upload, while also moving the connection action into the chat screen and triggering one automatic connection attempt when the app opens.

The experience should feel like a modern AI assistant app:

- chat remains the default home screen
- users can pick and send multiple images in one message
- images are sent as structured multimodal input, not text placeholders
- the app auto-connects on first entry
- the chat screen shows a compact connection strip only when the app is not ready
- settings remains available for configuration, but is no longer the primary place for connection actions

## Non-Goals

- redesigning gateway authentication or pairing behavior
- changing streaming response behavior
- changing the assistant response protocol
- redesigning the settings page beyond removing connection as the main action surface
- introducing upload-to-URL flows or external object storage
- changing existing markdown image rendering for assistant replies

## User-Confirmed Product Decisions

- multi-image upload should be supported
- image payloads should use `base64`
- the connection action should move back to the chat page
- the connection action should only appear when not connected
- entering the app should trigger an automatic connection attempt
- if automatic connection fails, the chat page should show the error text and a compact `Connection` button
- the user does not want tests run by the agent
- the user does not want formatting run by the agent

## Recommended Approach

Use a structured `content` array for outgoing messages, modeled after GPT and Gemini style multimodal input.

Example outgoing request:

```json
{
  "type": "req",
  "id": "req-123",
  "method": "chat.send",
  "params": {
    "sessionKey": "session-id",
    "content": [
      { "type": "text", "text": "请分析这几张图片" },
      {
        "type": "image",
        "source": {
          "type": "base64",
          "mimeType": "image/jpeg",
          "data": "..."
        }
      },
      {
        "type": "image",
        "source": {
          "type": "base64",
          "mimeType": "image/png",
          "data": "..."
        }
      }
    ],
    "idempotencyKey": "uuid"
  }
}
```

This is preferred over `message + images[]` because it preserves text/image order, scales to future media types, and matches mainstream multimodal chat APIs.

## Architecture

The implementation should keep the current receive path mostly intact and only expand the send path.

### 1. Outgoing Message Model

Add dedicated send-side models instead of overloading the current assistant transcript model:

- `ChatInputPart`
- `ChatInputTextPart`
- `ChatInputImagePart`
- `ImageInputSource`
- `SelectedImageAttachment`

These models exist only to support building outbound chat payloads and local UI preview state.

The existing `ChatMessage` model should remain in place for streamed transcript rendering, but it should be extended just enough to display user-side selected images after send.

### 2. Chat Send Pipeline

Current flow:

- `ChatScreen`
- `ChatController.send(String text)`
- `SendChatMessageUseCase.call(String text, config: ...)`
- `ChatRepository.sendMessage(String text, sessionId: ...)`
- `LiveChatRepository` sends `params.message`

Target flow:

- `ChatScreen`
- `ChatController.send(ChatDraft draft)`
- `SendChatMessageUseCase.call(ChatDraft draft, config: ...)`
- `ChatRepository.sendMessage(ChatDraft draft, sessionId: ...)`
- `LiveChatRepository` sends `params.content`

`ChatDraft` should contain:

- optional trimmed text
- zero or more selected images

Validation rules:

- if text is empty and no images are selected, do not send
- if text exists and images exist, send both in order
- if text is empty and images exist, sending is still valid

### 3. Local Attachment Encoding

Before the gateway request is sent, selected images should be converted into:

- `mimeType`
- `base64 data`

Encoding should happen in the send pipeline, not in the widget layer.

The widget layer should only manage:

- image picking
- attachment preview
- remove attachment
- disabled state while sending

### 4. Connection UX

The app should attempt one automatic connection when the user first lands on chat.

Auto-connect rules:

- trigger from chat-screen lifecycle, not from `build`
- do not re-trigger if already `connecting`
- do not re-trigger if already `ready`
- do not re-trigger repeatedly on every navigation back to chat during the same active lifecycle

Chat-page connection strip rules:

- shown only when the app is not ready to send
- while connecting: show compact status text only
- when failed or blocked: show compact error/support text plus `Connection` button
- when ready: hide the strip entirely

The settings page should remain available from the top-right settings icon, but connection should no longer be the primary action surface there.

## UI Behavior

### Chat Screen

The chat screen remains the home screen.

New behavior:

- on first entry, start auto-connect
- if not ready, show a compact connection strip above the transcript
- if ready, show only the transcript and composer
- keep the screen dense and transcript-first

### Composer

The composer should support:

- image-picker button
- multiple image selection
- horizontal image preview strip
- one-tap remove per image
- disabled edits while sending

The composer should remain visually compact and should not fall back to oversized cards.

### User Message Rendering

User messages should render:

- the sent text, when present
- the sent local images, when present

Assistant messages should keep:

- normal streamed text rendering
- existing inline markdown image / image URL rendering

This keeps the transcript visually coherent for both outbound and inbound multimodal messages.

## Android Support

Add support for Android image picking with compatible manifest declarations.

Requirements:

- keep existing `INTERNET`
- keep existing `usesCleartextTraffic` setting
- add image-picking dependency in `pubspec.yaml`
- add Android image-read compatibility permissions in `AndroidManifest.xml`

Recommended manifest coverage:

- `android.permission.READ_MEDIA_IMAGES`
- `android.permission.READ_EXTERNAL_STORAGE` for older Android compatibility

The implementation should prefer modern picker behavior where the plugin supports it, but the manifest should still be compatible with devices that rely on permission-based access.

## File-Level Plan

### New Models

Expected new model files or equivalent additions:

- outbound chat draft model
- outbound chat input part model
- selected image attachment model

### Existing Files To Modify

- `lib/src/application/controllers/chat_controller.dart`
- `lib/src/application/controllers/connection_controller.dart`
- `lib/src/application/use_cases/send_chat_message_use_case.dart`
- `lib/src/domain/repositories/chat_repository.dart`
- `lib/src/infrastructure/gateway/live_chat_repository.dart`
- `lib/src/presentation/screens/chat_screen.dart`
- `lib/src/presentation/widgets/chat_composer.dart`
- `lib/src/presentation/widgets/message_bubble.dart`
- `android/app/src/main/AndroidManifest.xml`
- `pubspec.yaml`

### New UI Helpers

Expected new presentation helper files:

- attachment preview strip
- image attachment chip or tile

## Error Handling

### Connection Errors

If auto-connect fails:

- preserve the mapped connection error text
- surface it in the compact chat-page connection strip
- allow the user to manually tap `Connection`

### Image Send Errors

If image encoding fails:

- fail the send action cleanly
- surface the mapped chat error in the transcript/error area
- do not leave stale sending state behind

### Partial UI Safety

If image preview cannot render:

- keep the attachment in state if it is still valid
- fall back to filename or generic image placeholder text

## State Management Boundaries

Widget responsibilities:

- pick images
- preview selected images
- remove selected images
- invoke send

Controller / use-case responsibilities:

- validate draft
- encode image bytes to base64
- build structured gateway payload
- manage send lifecycle
- preserve connection state transitions

Repository responsibilities:

- serialize `content` payload into gateway request format
- continue handling streamed assistant responses as before

## Testing Notes

The user explicitly asked the agent not to run tests. Implementation should still be structured so tests can be added later for:

- content payload serialization
- empty-vs-image-only send validation
- attachment preview behavior
- auto-connect one-shot behavior

## Risks

### Protocol Drift

If the server-side image input schema differs from the proposed `content` format, the Flutter client must align to the actual accepted keys before release.

### Payload Size

Multiple base64 images can significantly increase frame size. This is acceptable for the current goal, but very large image batches may later need compression or upload indirection.

### Auto-Connect Re-Entrancy

If auto-connect is triggered from the wrong lifecycle point, the app may repeatedly reconnect. The implementation must guard against duplicate attempts.

## Final Recommendation

Implement multimodal sending with a `content` array and base64 image parts, keep chat as the default home screen, auto-connect once on entry, and move the manual connection entry into a compact chat-page strip that only appears when the app is not ready.

This delivers the AI-assistant-style experience the user wants without unnecessarily rewriting the rest of the gateway and transcript pipeline.
