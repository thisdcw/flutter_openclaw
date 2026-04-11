import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../application/controllers/chat_controller.dart';
import '../../application/controllers/connection_controller.dart';
import '../../application/controllers/settings_controller.dart';
import '../../domain/models/chat_draft.dart';
import '../../domain/models/connection_status.dart';
import '../../domain/models/selected_image_attachment.dart';
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
  late final ImagePicker imagePicker;
  final List<SelectedImageAttachment> pendingAttachments = [];
  final Uuid uuid = Uuid();

  @override
  void initState() {
    super.initState();
    composerController = TextEditingController();
    composerController.addListener(_handleComposerChange);
    imagePicker = ImagePicker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(widget.connectionController.connectIfNeeded());
    });
  }

  @override
  void dispose() {
    composerController.removeListener(_handleComposerChange);
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
        final connectionStatus = widget.connectionController.status;
        final isConnecting = _isConnectingPhase(connectionStatus.phase);
        final showConnectionStrip = !connectionStatus.isReady;
        final blockedReason = widget.connectionController.sendBlockedReason;
        final messages = widget.chatController.messages;
        final hasDraftContent = composerController.text.trim().isNotEmpty ||
            pendingAttachments.isNotEmpty;
        final connectionTitle = _connectionTitle(
          connectionStatus,
          isConnecting,
        );
        final connectionSubtitle = _connectionSubtitle(
          connectionStatus,
          isConnecting,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text('OpenClaw Chat', style: theme.textTheme.titleMedium),
            actions: [
              StatusBadge(label: widget.connectionController.phase),
              const SizedBox(width: 6),
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
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showConnectionStrip) ...[
                      _ConnectionStrip(
                        title: connectionTitle,
                        subtitle: connectionSubtitle,
                        showButton: !isConnecting,
                        onPressed: () {
                          unawaited(
                            widget.connectionController.testConnection(),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (connectionStatus.isReady &&
                        blockedReason.isNotEmpty) ...[
                      _ChatBanner(
                        message: blockedReason,
                        color: const Color(0xFFFFF2D9),
                        textColor: const Color(0xFF8A5A00),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if ((widget.chatController.errorMessage ?? '').isNotEmpty) ...[
                      _ChatBanner(
                        message: widget.chatController.errorMessage!,
                        color: theme.colorScheme.errorContainer,
                        textColor: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.52),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.45),
                          ),
                        ),
                        child: messages.isEmpty
                            ? const _ChatEmptyState()
                            : ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: messages.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 4),
                                itemBuilder: (context, index) {
                                  return MessageBubble(message: messages[index]);
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ChatComposer(
                      controller: composerController,
                      enabled: widget.connectionController.canSend,
                      hasContent: hasDraftContent,
                      isSending: widget.chatController.isSending,
                      attachments: pendingAttachments,
                      onPickImages: _pickImages,
                      onRemoveAttachment: _removeAttachment,
                      onSend: () async {
                        final text = composerController.text;
                        if (!hasDraftContent) {
                          return;
                        }
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
                        await widget.chatController.send(
                          ChatDraft(
                            text: text,
                            attachments: pendingAttachments,
                          ),
                        );
                        if (!mounted) {
                          return;
                        }
                        composerController.clear();
                        setState(pendingAttachments.clear);
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

  void _handleComposerChange() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _pickImages() async {
    try {
      final files = await imagePicker.pickMultiImage();
      if (files.isEmpty) {
        return;
      }
      final newAttachments = <SelectedImageAttachment>[];
      for (final file in files) {
        final bytes = await file.readAsBytes();
        newAttachments.add(
          SelectedImageAttachment(
            id: uuid.v4(),
            fileName: file.name,
            mimeType: _inferMimeType(file.name),
            bytes: bytes,
          ),
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        pendingAttachments.addAll(newAttachments);
      });
    } on PlatformException catch (error, stackTrace) {
      openClawLog(
        'ChatScreen',
        'pick images failed: platform exception',
        fields: <String, Object?>{
          'code': error.code,
          'message': error.message,
          'details': error.details?.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
      _presentPickerError(
        error.code == 'channel-error'
            ? '图片选择器未完成原生注册，请完整重新启动应用后再试。'
            : '选择图片失败，请稍后重试。',
      );
    } on MissingPluginException catch (error, stackTrace) {
      openClawLog(
        'ChatScreen',
        'pick images failed: missing plugin',
        fields: <String, Object?>{
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
      _presentPickerError('图片选择器插件不可用，请完整重新启动应用后再试。');
    } catch (error, stackTrace) {
      openClawLog(
        'ChatScreen',
        'pick images failed',
        fields: <String, Object?>{
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
      _presentPickerError('选择图片失败，请稍后重试。');
    }
  }

  void _removeAttachment(SelectedImageAttachment attachment) {
    setState(() {
      pendingAttachments.remove(attachment);
    });
  }

  void _presentPickerError(String message) {
    widget.chatController.errorMessage = message;
    widget.chatController.notifyListeners();
  }

  static String _inferMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }

  static bool _isConnectingPhase(ConnectionPhase phase) {
    switch (phase) {
      case ConnectionPhase.connecting:
      case ConnectionPhase.waitingChallenge:
      case ConnectionPhase.authenticating:
      case ConnectionPhase.reconnecting:
        return true;
      case ConnectionPhase.idle:
      case ConnectionPhase.ready:
      case ConnectionPhase.failed:
        return false;
    }
  }

  static String _connectionTitle(
    ConnectionStatus status,
    bool isConnecting,
  ) {
    if (isConnecting) {
      return 'Connecting to gateway…';
    }
    if (status.failure != null) {
      return status.failure!.message;
    }
    return 'Connect to gateway to start chatting.';
  }

  static String _connectionSubtitle(
    ConnectionStatus status,
    bool isConnecting,
  ) {
    if (isConnecting) {
      return '';
    }
    if (status.failure != null) {
      return 'Check your gateway settings and tap Connection to retry.';
    }
    if (!status.isReady) {
      return 'Status: ${status.phase.value}.';
    }
    return '';
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF2F6BFF),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Ask anything once your gateway is ready.',
              style: theme.textTheme.titleMedium,
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

class _ConnectionStrip extends StatelessWidget {
  const _ConnectionStrip({
    required this.title,
    required this.subtitle,
    required this.showButton,
    this.onPressed,
  });

  final String title;
  final String subtitle;
  final bool showButton;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF2F6BFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_tethering_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (showButton) ...[
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Connection'),
            ),
          ],
        ],
      ),
    );
  }
}
