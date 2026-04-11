# Flutter OpenClaw Chat Density And Inline Images Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the chat screen denser and render inline images from Markdown image syntax or plain image URLs without changing any chat logic.

**Architecture:** Keep all changes inside the presentation layer. Add one focused message-content parser helper for converting message text into ordered text/image segments, then update `MessageBubble`, `ChatScreen`, and `ChatComposer` to use a tighter layout with lower visual weight and more visible transcript space.

**Tech Stack:** Flutter, Dart, `flutter_test`

---

## File Structure

- Create: `flutter_openclaw/lib/src/presentation/widgets/message_content_parser.dart`
  Lightweight parser that turns raw message text into ordered text and image segments.
- Modify: `flutter_openclaw/lib/src/presentation/widgets/message_bubble.dart`
  Render compact message blocks and inline images in order.
- Modify: `flutter_openclaw/lib/src/presentation/screens/chat_screen.dart`
  Reduce header/prompts/transcript framing height and simplify transcript container.
- Modify: `flutter_openclaw/lib/src/presentation/widgets/chat_composer.dart`
  Slim down the composer surface.
- Create: `flutter_openclaw/test/presentation/message_content_parser_test.dart`
  Unit tests for Markdown image parsing and plain image URL parsing.
- Modify: `flutter_openclaw/test/widget_test.dart`
  Replace outdated settings-first expectations with dense-chat and inline-image widget expectations.

## Task 1: Build The Lightweight Message Content Parser

**Files:**
- Create: `flutter_openclaw/lib/src/presentation/widgets/message_content_parser.dart`
- Create: `flutter_openclaw/test/presentation/message_content_parser_test.dart`

- [ ] **Step 1: Write the failing parser tests**

Create `flutter_openclaw/test/presentation/message_content_parser_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_openclaw/src/presentation/widgets/message_content_parser.dart';

void main() {
  group('parseMessageContent', () {
    test('parses markdown image and surrounding text in order', () {
      final segments = parseMessageContent(
        'hello ![lake](https://example.com/lake.png) world',
      );

      expect(segments.length, 3);
      expect(segments[0], const MessageTextSegment('hello '));
      expect(
        segments[1],
        const MessageImageSegment(
          url: 'https://example.com/lake.png',
          altText: 'lake',
        ),
      );
      expect(segments[2], const MessageTextSegment(' world'));
    });

    test('parses plain image url as image segment', () {
      final segments = parseMessageContent(
        'https://example.com/sunset.jpg',
      );

      expect(
        segments,
        const <MessageContentSegment>[
          MessageImageSegment(
            url: 'https://example.com/sunset.jpg',
            altText: null,
          ),
        ],
      );
    });

    test('keeps normal text untouched when no images exist', () {
      final segments = parseMessageContent('just text');

      expect(segments, const <MessageContentSegment>[
        MessageTextSegment('just text'),
      ]);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/message_content_parser_test.dart`
Expected: FAIL with missing parser symbols.

- [ ] **Step 3: Implement the parser helper**

Create `flutter_openclaw/lib/src/presentation/widgets/message_content_parser.dart`:

```dart
sealed class MessageContentSegment {
  const MessageContentSegment();
}

class MessageTextSegment extends MessageContentSegment {
  const MessageTextSegment(this.text);

  final String text;

  @override
  bool operator ==(Object other) =>
      other is MessageTextSegment && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

class MessageImageSegment extends MessageContentSegment {
  const MessageImageSegment({
    required this.url,
    required this.altText,
  });

  final String url;
  final String? altText;

  @override
  bool operator ==(Object other) =>
      other is MessageImageSegment &&
      other.url == url &&
      other.altText == altText;

  @override
  int get hashCode => Object.hash(url, altText);
}

List<MessageContentSegment> parseMessageContent(String input) {
  if (input.isEmpty) {
    return const <MessageContentSegment>[MessageTextSegment('')];
  }

  final markdownPattern = RegExp(r'!\[([^\]]*)\]\((https?:\/\/[^\s)]+)\)');
  final urlPattern = RegExp(r'https?:\/\/[^\s]+');
  final matches = <_MatchToken>[];

  for (final match in markdownPattern.allMatches(input)) {
    matches.add(
      _MatchToken(
        start: match.start,
        end: match.end,
        segment: MessageImageSegment(
          url: match.group(2)!,
          altText: match.group(1),
        ),
      ),
    );
  }

  for (final match in urlPattern.allMatches(input)) {
    final overlapsMarkdown = matches.any(
      (token) => match.start >= token.start && match.end <= token.end,
    );
    if (!overlapsMarkdown) {
      matches.add(
        _MatchToken(
          start: match.start,
          end: match.end,
          segment: MessageImageSegment(
            url: match.group(0)!,
            altText: null,
          ),
        ),
      );
    }
  }

  if (matches.isEmpty) {
    return <MessageContentSegment>[MessageTextSegment(input)];
  }

  matches.sort((a, b) => a.start.compareTo(b.start));
  final result = <MessageContentSegment>[];
  var cursor = 0;

  for (final token in matches) {
    if (token.start > cursor) {
      result.add(MessageTextSegment(input.substring(cursor, token.start)));
    }
    result.add(token.segment);
    cursor = token.end;
  }

  if (cursor < input.length) {
    result.add(MessageTextSegment(input.substring(cursor)));
  }

  return result;
}

class _MatchToken {
  const _MatchToken({
    required this.start,
    required this.end,
    required this.segment,
  });

  final int start;
  final int end;
  final MessageImageSegment segment;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/message_content_parser_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/src/presentation/widgets/message_content_parser.dart test/presentation/message_content_parser_test.dart
git commit -m "feat: add lightweight chat message content parser"
```

## Task 2: Render Inline Images In Compact Message Bubbles

**Files:**
- Modify: `flutter_openclaw/lib/src/presentation/widgets/message_bubble.dart`
- Create: `flutter_openclaw/test/widget_test.dart`

- [ ] **Step 1: Write the failing widget test for inline images**

Replace `flutter_openclaw/test/widget_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_openclaw/src/domain/models/chat_message.dart';
import 'package:flutter_openclaw/src/presentation/widgets/message_bubble.dart';

void main() {
  testWidgets('message bubble renders markdown images inline',
      (WidgetTester tester) async {
    const message = ChatMessage(
      id: 'assistant-1',
      role: MessageRole.assistant,
      text: 'Look ![lake](https://example.com/lake.png)',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MessageBubble(message: message),
        ),
      ),
    );

    expect(find.text('Look '), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because `MessageBubble` still renders only raw text.

- [ ] **Step 3: Update the bubble to render ordered text and image segments with denser styling**

Replace `flutter_openclaw/lib/src/presentation/widgets/message_bubble.dart` with:

```dart
import 'package:flutter/material.dart';

import '../../domain/models/chat_message.dart';
import 'message_content_parser.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isError = message.role == MessageRole.error;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final theme = Theme.of(context);
    final backgroundColor = isError
        ? theme.colorScheme.errorContainer
        : isUser
            ? const Color(0xFF2F6BFF)
            : Colors.transparent;
    final textColor = isError
        ? theme.colorScheme.onErrorContainer
        : isUser
            ? Colors.white
            : theme.colorScheme.onSurface;
    final segments = parseMessageContent(message.text.isEmpty && message.isStreaming
        ? '...'
        : message.text);

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 6),
              bottomRight: Radius.circular(isUser ? 6 : 18),
            ),
            border: isUser || isError
                ? null
                : Border.all(color: const Color(0xFFDCE7F6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final segment in segments) ...[
                if (segment is MessageTextSegment && segment.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      segment.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        height: 1.32,
                      ),
                    ),
                  ),
                if (segment is MessageImageSegment)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        segment.url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: const EdgeInsets.all(10),
                            color: const Color(0xFFF2F6FB),
                            child: Text(
                              segment.altText ?? segment.url,
                              style: theme.textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
              if (message.isStreaming)
                Text(
                  'Streaming',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: textColor.withOpacity(0.72),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/src/presentation/widgets/message_bubble.dart test/widget_test.dart
git commit -m "feat: render inline images in compact message bubbles"
```

## Task 3: Densify The Chat Screen And Composer

**Files:**
- Modify: `flutter_openclaw/lib/src/presentation/screens/chat_screen.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/chat_composer.dart`
- Modify: `flutter_openclaw/test/widget_test.dart`

- [ ] **Step 1: Extend the widget test for the denser chat surface**

Append this test to `flutter_openclaw/test/widget_test.dart`:

```dart
import 'package:flutter_openclaw/src/application/controllers/chat_controller.dart';
import 'package:flutter_openclaw/src/application/controllers/connection_controller.dart';
import 'package:flutter_openclaw/src/presentation/screens/chat_screen.dart';

testWidgets('chat screen keeps settings prompt compact when blocked',
    (WidgetTester tester) async {
  final connectionController = ConnectionController.fake()
    ..phase = 'ready'
    ..grantedScopes = ['operator.read'];
  final chatController = ChatController.fake();

  await tester.pumpWidget(
    MaterialApp(
      home: ChatScreen(
        chatController: chatController,
        connectionController: connectionController,
      ),
    ),
  );

  expect(find.text('OpenClaw is not ready yet'), findsOneWidget);
  expect(find.text('Open Settings'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because the prompt is still a large card and the denser layout is not yet implemented.

- [ ] **Step 3: Compact the chat screen and composer**

Update `flutter_openclaw/lib/src/presentation/screens/chat_screen.dart` with these concrete layout changes:

```dart
title: Text('OpenClaw Chat', style: theme.textTheme.titleMedium),
```

```dart
padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
```

```dart
if (blockedReason.isNotEmpty) ...[
  _SetupPromptStrip(
    title: 'OpenClaw is not ready yet',
    description: 'Connection or permissions need attention before sending.',
    buttonLabel: 'Open Settings',
    onPressed: widget.settingsController == null ? null : _openSettings,
  ),
  const SizedBox(height: 8),
],
```

```dart
Expanded(
  child: messages.isEmpty
      ? const _ChatEmptyState()
      : ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: messages.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            return MessageBubble(message: messages[index]);
          },
        ),
),
```

Replace `flutter_openclaw/lib/src/presentation/widgets/chat_composer.dart` with:

```dart
import 'package:flutter/material.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.enabled,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool isSending;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled && !isSending,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Message OpenClaw',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          FilledButton(
            onPressed: enabled && !isSending
                ? () {
                    onSend();
                  }
                : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              minimumSize: Size.zero,
            ),
            child: Text(isSending ? '...' : 'Send'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/src/presentation/screens/chat_screen.dart lib/src/presentation/widgets/chat_composer.dart test/widget_test.dart
git commit -m "feat: densify chat layout for higher message capacity"
```

## Task 4: Verify Scope And Behavior

**Files:**
- Modify: `flutter_openclaw/lib/src/presentation/screens/chat_screen.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/chat_composer.dart`
- Modify: `flutter_openclaw/lib/src/presentation/widgets/message_bubble.dart`
- Create: `flutter_openclaw/lib/src/presentation/widgets/message_content_parser.dart`
- Create: `flutter_openclaw/test/presentation/message_content_parser_test.dart`
- Modify: `flutter_openclaw/test/widget_test.dart`

- [ ] **Step 1: Run parser and widget tests**

Run: `flutter test test/presentation/message_content_parser_test.dart test/widget_test.dart`
Expected: All tests PASS

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: No regressions in existing tests

- [ ] **Step 3: Inspect the final diff**

Run: `git diff -- lib/src/presentation/screens/chat_screen.dart lib/src/presentation/widgets/chat_composer.dart lib/src/presentation/widgets/message_bubble.dart lib/src/presentation/widgets/message_content_parser.dart test/presentation/message_content_parser_test.dart test/widget_test.dart`
Expected: Diff is limited to presentation and tests

- [ ] **Step 4: Commit**

```bash
git add lib/src/presentation/screens/chat_screen.dart lib/src/presentation/widgets/chat_composer.dart lib/src/presentation/widgets/message_bubble.dart lib/src/presentation/widgets/message_content_parser.dart test/presentation/message_content_parser_test.dart test/widget_test.dart
git commit -m "feat: deliver dense chat layout and inline image rendering"
```

## Plan Self-Review

### Spec Coverage

- denser chat header, prompt, transcript, and composer: Task 3
- compact message bubble styling: Task 2
- Markdown image parsing: Task 1
- plain image URL parsing: Task 1
- ordered mixed text/image rendering: Tasks 1 and 2
- graceful image load fallback: Task 2
- presentation-only scope: all tasks stay in presentation files and tests

### Placeholder Scan

- No placeholders remain
- Each task lists exact files
- Each code-writing step includes concrete snippets
- Each verification step includes exact commands and expected results

### Type Consistency

- `MessageContentSegment`, `MessageTextSegment`, and `MessageImageSegment` are defined before they are consumed
- `MessageBubble` stays driven by `ChatMessage.text`
- `ChatComposer` keeps the existing `enabled`, `isSending`, and async `onSend` contract
