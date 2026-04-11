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
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final theme = Theme.of(context);
    final backgroundColor = isError
        ? theme.colorScheme.errorContainer
        : isUser
            ? theme.colorScheme.primary
            : Colors.white;
    final textColor = isError
        ? theme.colorScheme.onErrorContainer
        : isUser
            ? Colors.white
            : theme.colorScheme.onSurface;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(24),
              topRight: const Radius.circular(24),
              bottomLeft: Radius.circular(isUser ? 24 : 8),
              bottomRight: Radius.circular(isUser ? 8 : 24),
            ),
            border: isUser || isError
                ? null
                : Border.all(color: const Color(0xFFDCE7F6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x110E1A2B),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
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
                  'Streaming response',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: textColor.withOpacity(0.75),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
