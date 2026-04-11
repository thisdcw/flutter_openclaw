import 'package:flutter/material.dart';

import '../../application/controllers/chat_controller.dart';
import '../../application/controllers/connection_controller.dart';
import '../../application/controllers/settings_controller.dart';
import '../../infrastructure/util/openclaw_logger.dart';
import '../widgets/chat_composer.dart';
import '../widgets/message_bubble.dart';
import '../widgets/status_badge.dart';
import 'settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatController,
    required this.connectionController,
    this.settingsController,
  });

  final ChatController chatController;
  final ConnectionController connectionController;
  final SettingsController? settingsController;

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
        final theme = Theme.of(context);
        final blockedReason = widget.connectionController.sendBlockedReason;
        final messages = widget.chatController.messages;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OpenClaw Chat', style: theme.textTheme.titleLarge),
                Text(
                  'Your connected AI assistant workspace',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              StatusBadge(label: widget.connectionController.phase),
              const SizedBox(width: 10),
              IconButton(
                onPressed: widget.settingsController == null
                    ? null
                    : _openSettings,
                icon: const Icon(Icons.settings_rounded),
                tooltip: 'Open Settings',
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF0F6FF), Color(0xFFF7FAFE)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (blockedReason.isNotEmpty) ...[
                      _SetupPromptCard(
                        title: 'OpenClaw is not ready yet',
                        description:
                            'Your assistant needs connection or permission setup before it can send messages.',
                        buttonLabel: 'Open Settings',
                        onPressed: widget.settingsController == null
                            ? null
                            : _openSettings,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (blockedReason.isNotEmpty) ...[
                      _ChatBanner(
                        message: blockedReason,
                        color: const Color(0xFFFFF2D9),
                        textColor: const Color(0xFF8A5A00),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if ((widget.chatController.errorMessage ?? '').isNotEmpty) ...[
                      _ChatBanner(
                        message: widget.chatController.errorMessage!,
                        color: theme.colorScheme.errorContainer,
                        textColor: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.72),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        child: messages.isEmpty
                            ? const _ChatEmptyState()
                            : ListView.separated(
                                itemCount: messages.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  return MessageBubble(message: messages[index]);
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
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
            ),
          ),
        );
      },
    );
  }

  void _openSettings() {
    final settingsController = widget.settingsController;
    if (settingsController == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsScreen(
          settingsController: settingsController,
          connectionController: widget.connectionController,
          chatController: widget.chatController,
        ),
      ),
    );
  }
}

class _ChatBanner extends StatelessWidget {
  const _ChatBanner({
    required this.message,
    required this.color,
    required this.textColor,
  });

  final String message;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        style:
            Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor),
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF2F6BFF),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Ask anything once your gateway is ready.',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your assistant replies will stream here as soon as the connection is ready and operator.write is available.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupPromptCard extends StatelessWidget {
  const _SetupPromptCard({
    required this.title,
    required this.description,
    required this.buttonLabel,
    this.onPressed,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF2F6BFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.tips_and_updates_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.settings_rounded),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
