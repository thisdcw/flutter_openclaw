import 'package:flutter/material.dart';

import '../../domain/models/chat_conversation_summary.dart';

class ConversationListSheet extends StatelessWidget {
  const ConversationListSheet({
    super.key,
    required this.conversations,
    required this.activeConversationId,
    required this.onSelectConversation,
    required this.onRenameConversation,
  });

  final List<ChatConversationSummary> conversations;
  final String? activeConversationId;
  final Future<void> Function(String conversationId) onSelectConversation;
  final Future<void> Function(String conversationId, String title)
  onRenameConversation;

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
            Text('Chats', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('点击切换会话，右侧按钮可重命名。', style: theme.textTheme.bodySmall),
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
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onPrimary,
                                          ),
                                    ),
                                  ),
                                IconButton(
                                  onPressed: () async {
                                    final renamed = await _promptRenameDialog(
                                      context,
                                      initialTitle: conversation.title,
                                    );
                                    if (renamed == null) {
                                      return;
                                    }
                                    await onRenameConversation(
                                      conversation.id,
                                      renamed,
                                    );
                                    if (!context.mounted) {
                                      return;
                                    }
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(Icons.edit_rounded),
                                  tooltip: 'Rename',
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

  Future<String?> _promptRenameDialog(
    BuildContext context, {
    required String initialTitle,
  }) async {
    final controller = TextEditingController(text: initialTitle);
    final nextTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('重命名会话'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 32,
            decoration: const InputDecoration(hintText: '输入会话标题'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (!context.mounted) {
      return null;
    }
    if (nextTitle == null) {
      return null;
    }
    final normalized = nextTitle.trim();
    if (normalized.isEmpty) {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(const SnackBar(content: Text('会话标题不能为空。')));
      return null;
    }
    return normalized;
  }
}
