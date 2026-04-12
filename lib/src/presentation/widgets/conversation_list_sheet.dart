import 'package:flutter/material.dart';

import '../../domain/models/chat_conversation_summary.dart';

class ConversationListSheet extends StatelessWidget {
  const ConversationListSheet({
    super.key,
    required this.conversations,
    required this.activeConversationId,
    required this.onCreateConversation,
    required this.onSelectConversation,
  });

  final List<ChatConversationSummary> conversations;
  final String? activeConversationId;
  final Future<void> Function() onCreateConversation;
  final Future<void> Function(String conversationId) onSelectConversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Chats',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    await onCreateConversation();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.62,
              child: ListView.separated(
                itemCount: conversations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  final isActive = conversation.id == activeConversationId;
                  return Material(
                    color: isActive
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async {
                        await onSelectConversation(conversation.id);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    conversation.title,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                if (isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Active',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              conversation.previewText.isEmpty
                                  ? 'No messages yet'
                                  : conversation.previewText,
                              style: theme.textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
