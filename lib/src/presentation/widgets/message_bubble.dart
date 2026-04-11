import 'package:flutter/material.dart';

import '../../domain/models/chat_message.dart';

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
    final alignment =
        isUser ? Alignment.centerRight : Alignment.centerLeft;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgroundColor = isError
        ? colorScheme.errorContainer
        : isUser
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest;
    final textColor = isError
        ? colorScheme.onErrorContainer
        : isUser
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurface;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          color: backgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text.isEmpty && message.isStreaming
                      ? '...'
                      : message.text,
                  style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                ),
                if (message.isStreaming) ...[
                  const SizedBox(height: 8),
                  Text(
                    'streaming',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
