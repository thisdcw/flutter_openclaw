import 'package:flutter/material.dart';

import '../../application/controllers/chat_controller.dart';
import '../../application/controllers/connection_controller.dart';
import '../../infrastructure/util/openclaw_logger.dart';
import '../widgets/chat_composer.dart';
import '../widgets/message_bubble.dart';
import '../widgets/status_badge.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatController,
    required this.connectionController,
  });

  final ChatController chatController;
  final ConnectionController connectionController;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final TextEditingController composerController;

  @override
  void initState() {
    super.initState();
    composerController = TextEditingController();
  }

  @override
  void dispose() {
    composerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.connectionController,
        widget.chatController,
      ]),
      builder: (context, _) {
        final blockedReason = widget.connectionController.sendBlockedReason;
        final messages = widget.chatController.messages;

        return Scaffold(
          appBar: AppBar(
            title: const Text('OpenClaw Chat'),
            actions: [
              StatusBadge(label: widget.connectionController.phase),
              const SizedBox(width: 12),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (blockedReason.isNotEmpty) ...[
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(blockedReason),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if ((widget.chatController.errorMessage ?? '').isNotEmpty) ...[
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(widget.chatController.errorMessage!),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: messages.isEmpty
                      ? const Center(
                          child: Text('No messages yet.'),
                        )
                      : ListView.separated(
                          itemCount: messages.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return MessageBubble(message: messages[index]);
                          },
                        ),
                ),
                const SizedBox(height: 12),
                ChatComposer(
                  controller: composerController,
                  enabled: widget.connectionController.canSend,
                  isSending: widget.chatController.isSending,
                  onSend: () async {
                    final text = composerController.text;
                    openClawLog(
                      'ChatScreen',
                      'composer send tapped',
                      fields: <String, Object?>{
                        'enabled': widget.connectionController.canSend,
                        'phase': widget.connectionController.phase,
                        'textLength': text.length,
                        'preview': truncateForLog(text, maxLength: 80),
                      },
                    );
                    await widget.chatController.send(text);
                    composerController.clear();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
