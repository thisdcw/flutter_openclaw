# Flutter OpenClaw Multimodal Chat And Auto Connect Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add multi-image chat input with base64 image payloads, move manual connection into the chat page, and auto-connect once when the app opens.

**Architecture:** Keep the existing receive path mostly intact and upgrade the outbound send path from plain text to a structured `content` array. Implement chat-page auto-connect and a compact non-ready connection strip in the presentation layer, while keeping settings as a configuration surface and adding Android image-picker support.

**Tech Stack:** Flutter, Dart, `image_picker`, Android manifest permissions, existing OpenClaw gateway WebSocket stack

---

## File Structure

- Create: `flutter_openclaw/lib/src/domain/models/chat_draft.dart`
- Create: `flutter_openclaw/lib/src/domain/models/chat_input_part.dart`
- Create: `flutter_openclaw/lib/src/domain/models/selected_image_attachment.dart`
- Create: `flutter_openclaw/lib/src/presentation/widgets/attachment_preview_strip.dart`
- Modify: `flutter_openclaw/lib/src/domain/models/chat_message.dart`
- Modify: `flutter_openclaw/lib/src/application/controllers/chat_controller.dart`
- Modify: `flutter_openclaw/lib/src/application/controllers/connection_controller.dart`
- Modify: `flutter_openclaw/lib/src/application/use_cases/send_chat_message_use_case.dart`
- Modify: `flutter_openclaw/lib/src/domain/repositories/chat_repository.dart`
- Modify: `flutter_openclaw/lib/src/infrastructure/gateway/live_chat_repository.dart`
- Modify: `flutter_openclaw/lib/src/presentation/screens/chat_screen.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/chat_composer.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/message_bubble.dart`
- Modify: `flutter_openclaw/lib/src/presentation/screens/settings_screen.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/settings_form.dart`
- Modify: `flutter_openclaw/android/app/src/main/AndroidManifest.xml`
- Modify: `flutter_openclaw/pubspec.yaml`
- Create: `flutter_openclaw/test/domain/models/chat_input_part_test.dart`
- Create: `flutter_openclaw/test/application/controllers/connection_controller_test.dart`
- Modify: `flutter_openclaw/test/widget_test.dart`

## Task 1: Add Outbound Multimodal Models

**Files:**
- Create: `flutter_openclaw/lib/src/domain/models/selected_image_attachment.dart`
- Create: `flutter_openclaw/lib/src/domain/models/chat_draft.dart`
- Create: `flutter_openclaw/lib/src/domain/models/chat_input_part.dart`
- Create: `flutter_openclaw/test/domain/models/chat_input_part_test.dart`

- [ ] **Step 1: Write the failing model tests**

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_openclaw/src/domain/models/chat_draft.dart';
import 'package:flutter_openclaw/src/domain/models/chat_input_part.dart';
import 'package:flutter_openclaw/src/domain/models/selected_image_attachment.dart';

void main() {
  test('serializes text and image parts in order', () {
    final draft = ChatDraft(
      text: 'analyze these',
      attachments: const <SelectedImageAttachment>[
        SelectedImageAttachment(
          id: 'image-1',
          fileName: 'sample.jpg',
          mimeType: 'image/jpeg',
          bytes: <int>[1, 2, 3],
        ),
      ],
    );

    final parts = draft.toGatewayContent();
    expect(parts.first, const ChatInputTextPart('analyze these'));
    expect(parts.last, isA<ChatInputImagePart>());
    expect(
      (parts.last as ChatInputImagePart).source.data,
      base64.encode(<int>[1, 2, 3]),
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/models/chat_input_part_test.dart`
Expected: FAIL with missing model symbols.

- [ ] **Step 3: Implement the outbound model layer**

`selected_image_attachment.dart`

```dart
class SelectedImageAttachment {
  const SelectedImageAttachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String id;
  final String fileName;
  final String mimeType;
  final List<int> bytes;
}
```

`chat_input_part.dart`

```dart
import 'dart:convert';
import 'selected_image_attachment.dart';

sealed class ChatInputPart {
  const ChatInputPart();
  Map<String, Object?> toJson();
}

class ChatInputTextPart extends ChatInputPart {
  const ChatInputTextPart(this.text);
  final String text;
  @override
  Map<String, Object?> toJson() => {'type': 'text', 'text': text};
  @override
  bool operator ==(Object other) =>
      other is ChatInputTextPart && other.text == text;
  @override
  int get hashCode => text.hashCode;
}

class ChatInputImageSource {
  const ChatInputImageSource({
    required this.type,
    required this.mimeType,
    required this.data,
  });

  final String type;
  final String mimeType;
  final String data;

  Map<String, Object?> toJson() =>
      {'type': type, 'mimeType': mimeType, 'data': data};
}

class ChatInputImagePart extends ChatInputPart {
  const ChatInputImagePart({required this.source});
  final ChatInputImageSource source;

  factory ChatInputImagePart.fromAttachment(SelectedImageAttachment value) {
    return ChatInputImagePart(
      source: ChatInputImageSource(
        type: 'base64',
        mimeType: value.mimeType,
        data: base64.encode(value.bytes),
      ),
    );
  }

  @override
  Map<String, Object?> toJson() => {'type': 'image', 'source': source.toJson()};
}
```

`chat_draft.dart`

```dart
import 'chat_input_part.dart';
import 'selected_image_attachment.dart';

class ChatDraft {
  const ChatDraft({
    required this.text,
    required this.attachments,
  });

  final String text;
  final List<SelectedImageAttachment> attachments;

  String get normalizedText => text.trim();
  bool get hasSendableContent => normalizedText.isNotEmpty || attachments.isNotEmpty;

  List<ChatInputPart> toGatewayContent() {
    final parts = <ChatInputPart>[];
    if (normalizedText.isNotEmpty) {
      parts.add(ChatInputTextPart(normalizedText));
    }
    for (final attachment in attachments) {
      parts.add(ChatInputImagePart.fromAttachment(attachment));
    }
    return parts;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/models/chat_input_part_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/src/domain/models/selected_image_attachment.dart lib/src/domain/models/chat_draft.dart lib/src/domain/models/chat_input_part.dart test/domain/models/chat_input_part_test.dart
git commit -m "feat: add multimodal chat draft models"
```

## Task 2: Upgrade the Send Pipeline

**Files:**
- Modify: `flutter_openclaw/lib/src/domain/models/chat_message.dart`
- Modify: `flutter_openclaw/lib/src/application/controllers/chat_controller.dart`
- Modify: `flutter_openclaw/lib/src/application/use_cases/send_chat_message_use_case.dart`
- Modify: `flutter_openclaw/lib/src/domain/repositories/chat_repository.dart`
- Modify: `flutter_openclaw/lib/src/infrastructure/gateway/live_chat_repository.dart`

- [ ] **Step 1: Write the failing controller test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_openclaw/src/application/controllers/chat_controller.dart';
import 'package:flutter_openclaw/src/domain/models/chat_draft.dart';
import 'package:flutter_openclaw/src/domain/models/selected_image_attachment.dart';

void main() {
  test('chat controller accepts image-only draft', () async {
    final controller = ChatController.fake();

    await controller.send(
      const ChatDraft(
        text: '',
        attachments: <SelectedImageAttachment>[
          SelectedImageAttachment(
            id: 'image-1',
            fileName: 'a.png',
            mimeType: 'image/png',
            bytes: <int>[1, 2],
          ),
        ],
      ),
    );

    expect(controller.messages, isNotEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/application/controllers/chat_controller_test.dart`
Expected: FAIL because `ChatController.send` still expects `String`.

- [ ] **Step 3: Implement minimal pipeline changes**

`chat_message.dart`

```dart
import 'selected_image_attachment.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.isStreaming = false,
    this.attachments = const <SelectedImageAttachment>[],
  });

  final List<SelectedImageAttachment> attachments;
}
```

`chat_controller.dart`

```dart
import '../../domain/models/chat_draft.dart';

Future<void> send(ChatDraft draft) async {
  if (!draft.hasSendableContent) {
    return;
  }

  _messages.add(
    ChatMessage(
      id: 'user-${_messages.length}',
      role: MessageRole.user,
      text: draft.normalizedText,
      attachments: List<SelectedImageAttachment>.from(draft.attachments),
    ),
  );

  final stream = sendChatMessageUseCase != null && configProvider != null
      ? sendChatMessageUseCase.call(draft, config: configProvider())
      : repository!.sendMessage(draft, sessionId: sessionIdProvider!());
}
```

`chat_repository.dart`

```dart
import '../models/chat_draft.dart';

abstract class ChatRepository {
  Stream<ChatMessage> sendMessage(
    ChatDraft draft, {
    required String sessionId,
  });
}
```

`send_chat_message_use_case.dart`

```dart
import '../../domain/models/chat_draft.dart';

Stream<ChatMessage> call(
  ChatDraft draft, {
  required GatewayConfig config,
}) async* {
  yield* repository.sendMessage(draft, sessionId: config.sessionId);
}
```

`live_chat_repository.dart`

```dart
import '../../domain/models/chat_draft.dart';

Stream<ChatMessage> sendMessage(
  ChatDraft draft, {
  required String sessionId,
}) {
  final content = draft.toGatewayContent()
      .map((part) => part.toJson())
      .toList(growable: false);

  _client.send({
    'type': 'req',
    'id': requestId,
    'method': 'chat.send',
    'params': {
      'sessionKey': sessionId,
      'content': content,
      'idempotencyKey': _uuid.v4(),
    },
  });
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/application/controllers/chat_controller_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/src/domain/models/chat_message.dart lib/src/application/controllers/chat_controller.dart lib/src/application/use_cases/send_chat_message_use_case.dart lib/src/domain/repositories/chat_repository.dart lib/src/infrastructure/gateway/live_chat_repository.dart test/application/controllers/chat_controller_test.dart
git commit -m "feat: send multimodal chat drafts through gateway"
```

## Task 3: Add Auto-Connect and Chat-Page Connection Strip

**Files:**
- Modify: `flutter_openclaw/lib/src/application/controllers/connection_controller.dart`
- Modify: `flutter_openclaw/lib/src/presentation/screens/chat_screen.dart`
- Create: `flutter_openclaw/test/application/controllers/connection_controller_test.dart`
- Modify: `flutter_openclaw/test/widget_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_openclaw/src/application/controllers/connection_controller.dart';

void main() {
  test('connectIfNeeded does not re-enter when already ready', () async {
    final controller = ConnectionController.fake()..phase = 'ready';
    await controller.connectIfNeeded();
    expect(controller.phase, 'ready');
  });
}
```

```dart
testWidgets('chat screen shows connection strip when not ready',
    (WidgetTester tester) async {
  final connectionController = ConnectionController.fake()..phase = 'failed';
  final chatController = ChatController.fake();

  await tester.pumpWidget(
    MaterialApp(
      home: ChatScreen(
        chatController: chatController,
        connectionController: connectionController,
      ),
    ),
  );

  expect(find.text('Connection'), findsOneWidget);
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/application/controllers/connection_controller_test.dart test/widget_test.dart`
Expected: FAIL because `connectIfNeeded` and the new strip do not exist yet.

- [ ] **Step 3: Implement guarded auto-connect**

`connection_controller.dart`

```dart
bool _hasAttemptedAutoConnect = false;

Future<void> connectIfNeeded({bool auto = false}) async {
  if (_status.phase == ConnectionPhase.connecting ||
      _status.phase == ConnectionPhase.ready) {
    return;
  }
  if (auto && _hasAttemptedAutoConnect) {
    return;
  }
  if (auto) {
    _hasAttemptedAutoConnect = true;
  }
  await testConnection();
}
```

`chat_screen.dart`

```dart
@override
void initState() {
  super.initState();
  composerController = TextEditingController();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    widget.connectionController.connectIfNeeded(auto: true);
  });
}
```

```dart
if (!widget.connectionController.canSend) ...[
  _ConnectionStrip(
    phase: widget.connectionController.phase,
    errorMessage: widget.connectionController.errorMessage,
    onConnect: () {
      widget.connectionController.connectIfNeeded();
    },
  ),
  const SizedBox(height: 8),
],
```

```dart
class _ConnectionStrip extends StatelessWidget {
  const _ConnectionStrip({
    required this.phase,
    required this.errorMessage,
    required this.onConnect,
  });

  final String phase;
  final String? errorMessage;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final description = phase == 'connecting'
        ? 'Connecting to your OpenClaw gateway...'
        : (errorMessage?.isNotEmpty ?? false)
            ? errorMessage!
            : 'Connection is required before sending messages.';

    return Row(
      children: [
        Expanded(child: Text(description)),
        if (phase != 'connecting')
          FilledButton(
            onPressed: onConnect,
            child: const Text('Connection'),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/application/controllers/connection_controller_test.dart test/widget_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/src/application/controllers/connection_controller.dart lib/src/presentation/screens/chat_screen.dart test/application/controllers/connection_controller_test.dart test/widget_test.dart
git commit -m "feat: auto connect on chat entry with compact connection strip"
```

## Task 4: Add Multi-Image Picker UI

**Files:**
- Create: `flutter_openclaw/lib/src/presentation/widgets/attachment_preview_strip.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/chat_composer.dart`
- Modify: `flutter_openclaw/lib/src/presentation/screens/chat_screen.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/message_bubble.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
testWidgets('chat composer shows attachment preview tiles',
    (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ChatComposer(
          controller: TextEditingController(),
          enabled: true,
          isSending: false,
          attachments: const <SelectedImageAttachment>[
            SelectedImageAttachment(
              id: 'image-1',
              fileName: 'preview.png',
              mimeType: 'image/png',
              bytes: <int>[1, 2, 3],
            ),
          ],
          onPickImages: () async {},
          onRemoveAttachment: (_) {},
          onSend: () async {},
        ),
      ),
    ),
  );

  expect(find.text('preview.png'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because `ChatComposer` does not support attachments yet.

- [ ] **Step 3: Implement attachment preview and richer composer**

`attachment_preview_strip.dart`

```dart
import 'package:flutter/material.dart';
import '../../domain/models/selected_image_attachment.dart';

class AttachmentPreviewStrip extends StatelessWidget {
  const AttachmentPreviewStrip({
    super.key,
    required this.attachments,
    required this.enabled,
    required this.onRemove,
  });

  final List<SelectedImageAttachment> attachments;
  final bool enabled;
  final ValueChanged<SelectedImageAttachment> onRemove;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          return Row(
            children: [
              Text(attachment.fileName),
              IconButton(
                onPressed: enabled ? () => onRemove(attachment) : null,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

`chat_composer.dart`

```dart
import '../../domain/models/selected_image_attachment.dart';
import 'attachment_preview_strip.dart';

final List<SelectedImageAttachment> attachments;
final Future<void> Function() onPickImages;
final ValueChanged<SelectedImageAttachment> onRemoveAttachment;
```

```dart
Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    AttachmentPreviewStrip(
      attachments: attachments,
      enabled: enabled && !isSending,
      onRemove: onRemoveAttachment,
    ),
    Row(
      children: [
        IconButton(
          onPressed: enabled && !isSending ? () => onPickImages() : null,
          icon: const Icon(Icons.add_photo_alternate_rounded),
        ),
        Expanded(child: TextField(controller: controller)),
        FilledButton(onPressed: () => onSend(), child: const Text('Send')),
      ],
    ),
  ],
)
```

`message_bubble.dart`

```dart
if (message.attachments.isNotEmpty)
  Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final attachment in message.attachments)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(attachment.fileName),
        ),
    ],
  ),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/src/presentation/widgets/attachment_preview_strip.dart lib/src/presentation/widgets/chat_composer.dart lib/src/presentation/widgets/message_bubble.dart test/widget_test.dart
git commit -m "feat: add multi-image attachment preview to chat composer"
```

## Task 5: Wire Image Picking, Settings Cleanup, and Android Support

**Files:**
- Modify: `flutter_openclaw/lib/src/presentation/screens/chat_screen.dart`
- Modify: `flutter_openclaw/lib/src/presentation/screens/settings_screen.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/settings_form.dart`
- Modify: `flutter_openclaw/android/app/src/main/AndroidManifest.xml`
- Modify: `flutter_openclaw/pubspec.yaml`

- [ ] **Step 1: Add dependency and Android manifest entries**

`pubspec.yaml`

```yaml
dependencies:
  image_picker: ^1.1.2
```

`AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission
    android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
```

- [ ] **Step 2: Wire image picking in `ChatScreen`**

```dart
import 'package:image_picker/image_picker.dart';
import '../../domain/models/chat_draft.dart';
import '../../domain/models/selected_image_attachment.dart';

late final ImagePicker _imagePicker;
final List<SelectedImageAttachment> _attachments = <SelectedImageAttachment>[];
```

```dart
Future<void> _pickImages() async {
  final files = await _imagePicker.pickMultiImage();
  if (files.isEmpty) return;

  final attachments = <SelectedImageAttachment>[];
  for (final file in files) {
    attachments.add(
      SelectedImageAttachment(
        id: file.path,
        fileName: file.name,
        mimeType: _mimeTypeFromPath(file.name),
        bytes: await file.readAsBytes(),
      ),
    );
  }

  if (!mounted) return;
  setState(() {
    _attachments
      ..clear()
      ..addAll(attachments);
  });
}
```

```dart
await widget.chatController.send(
  ChatDraft(
    text: composerController.text,
    attachments: List<SelectedImageAttachment>.from(_attachments),
  ),
);
setState(() {
  _attachments.clear();
});
composerController.clear();
```

- [ ] **Step 3: Remove connection as a settings action**

`settings_form.dart`

```dart
class SettingsForm extends StatelessWidget {
  const SettingsForm({
    super.key,
    required this.onSave,
  });

  final Future<void> Function() onSave;
}
```

```dart
FilledButton.icon(
  onPressed: () {
    onSave();
  },
  icon: const Icon(Icons.save_rounded),
  label: const Text('Save Settings'),
)
```

Update `settings_screen.dart` to pass only `onSave: _saveSettings`.

- [ ] **Step 4: Run targeted verification**

Run: `flutter test test/domain/models/chat_input_part_test.dart test/application/controllers/chat_controller_test.dart test/application/controllers/connection_controller_test.dart test/widget_test.dart`
Expected: PASS

Run: `flutter analyze`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml android/app/src/main/AndroidManifest.xml lib/src/presentation/screens/chat_screen.dart lib/src/presentation/screens/settings_screen.dart lib/src/presentation/widgets/settings_form.dart
git commit -m "feat: add image picker support and chat-first connection flow"
```

## Plan Self-Review

### Spec Coverage

- multi-image upload: Task 4 and Task 5
- base64 image payloads: Task 1 and Task 2
- structured `content` payload: Task 1 and Task 2
- auto-connect on app entry: Task 3
- compact connection strip: Task 3
- settings as configuration-only surface: Task 5
- Android picker support: Task 5

### Placeholder Scan

- no `TBD`, `TODO`, or deferred steps remain
- each task lists exact files
- code steps include concrete snippets
- verification steps include exact commands

### Type Consistency

- `ChatDraft` is the shared send model across controller, use case, repository, and gateway
- `SelectedImageAttachment` is reused for preview state and transcript rendering
- `connectIfNeeded` is the guarded auto-connect/manual-connect entrypoint
- `ChatInputPart` serialization feeds `LiveChatRepository` `params.content`
