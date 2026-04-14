import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_openclaw/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../../application/models/app_error_notice.dart';
import '../../application/controllers/chat_controller.dart';
import '../../application/controllers/connection_controller.dart';
import '../../application/controllers/settings_controller.dart';
import '../../application/use_cases/send_canvas_user_action_use_case.dart';
import '../../domain/models/chat_draft.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/connection_status.dart';
import '../../domain/models/gateway_failure.dart';
import '../../domain/models/selected_image_attachment.dart';
import '../../infrastructure/util/openclaw_logger.dart';
import '../localization/localized_gateway_text.dart';
import '../widgets/chat_command_assist.dart';
import '../widgets/chat_composer.dart';
import '../widgets/conversation_list_sheet.dart';
import '../widgets/error_notice_banner.dart';
import '../widgets/message_bubble.dart';
import '../widgets/status_badge.dart';
import 'canvas_screen.dart';
import 'settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatController,
    required this.connectionController,
    this.sendCanvasUserActionUseCase,
    this.settingsController,
  });

  final ChatController chatController;
  final ConnectionController connectionController;
  final SendCanvasUserActionUseCase? sendCanvasUserActionUseCase;
  final SettingsController? settingsController;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final TextEditingController composerController;
  late final FocusNode composerFocusNode;
  late final ScrollController messageScrollController;
  late final ImagePicker imagePicker;
  final List<SelectedImageAttachment> pendingAttachments = [];
  final Uuid uuid = Uuid();
  String? lastObservedConversationId;
  String lastObservedMessageSignature = '';
  bool autoScrollScheduled = false;
  bool pendingForceScroll = false;

  @override
  void initState() {
    super.initState();
    composerController = TextEditingController();
    composerController.addListener(_handleComposerChange);
    composerFocusNode = FocusNode();
    messageScrollController = ScrollController();
    imagePicker = ImagePicker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(widget.connectionController.connectIfNeeded());
    });
  }

  @override
  void dispose() {
    composerController.removeListener(_handleComposerChange);
    composerController.dispose();
    composerFocusNode.dispose();
    messageScrollController.dispose();
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
        final l10n = AppLocalizations.of(context)!;
        final connectionStatus = widget.connectionController.status;
        final isConnecting = _isConnectingPhase(connectionStatus.phase);
        final showConnectionStrip = !connectionStatus.isReady;
        final isPairingFailure =
            connectionStatus.failure?.type == GatewayFailureType.pairingRequired;
        final blockedReason = localizedBlockedReason(
          l10n,
          widget.connectionController.sendBlockedReason,
        );
        final messages = widget.chatController.messages;
        final activeConversation = widget.chatController.activeConversationSummary;
        final trimmedDraft = composerController.text.trimLeft();
        final commandHint = analyzeChatDraft(composerController.text).hintKind;
        final commandSuggestions = trimmedDraft.startsWith('/')
            ? filterSlashSuggestions(composerController.text)
            : const <ChatCommandSuggestion>[];
        final hasDraftContent = composerController.text.trim().isNotEmpty ||
            pendingAttachments.isNotEmpty;
        final connectionTitle = _connectionTitle(
          l10n,
          connectionStatus,
          isConnecting,
        );
        final connectionSubtitle = _connectionSubtitle(
          l10n,
          connectionStatus,
          isConnecting,
        );
        final hasCanvasHost =
            (connectionStatus.canvasCapability.canvasHostUrl ?? '').trim().isNotEmpty;
        final canOpenCanvas = connectionStatus.isReady &&
            hasCanvasHost &&
            widget.sendCanvasUserActionUseCase != null &&
            widget.settingsController != null;
        _syncMessageViewport(
          conversationId: activeConversation?.id,
          messages: messages,
        );

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: _openConversationList,
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              tooltip: 'Chats',
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeConversation?.title ?? l10n.chatScreenTitle,
                  style: theme.textTheme.titleMedium,
                ),
                if ((activeConversation?.sessionId ?? '').isNotEmpty)
                  Text(
                    activeConversation!.sessionId,
                    style: theme.textTheme.labelSmall,
                  ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () async {
                  await widget.chatController.createConversation();
                  if (!mounted) {
                    return;
                  }
                  composerController.clear();
                  setState(pendingAttachments.clear);
                },
                icon: const Icon(Icons.add_comment_outlined),
                tooltip: 'New chat',
              ),
              StatusBadge(label: widget.connectionController.phase),
              const SizedBox(width: 6),
              IconButton(
                onPressed: canOpenCanvas
                    ? _openCanvas
                    : connectionStatus.isReady && hasCanvasHost
                        ? null
                        : _showCanvasUnavailableHint,
                icon: const Icon(Icons.dashboard_customize_rounded),
                tooltip: canOpenCanvas
                    ? 'Open canvas host'
                    : 'Canvas unavailable (missing structured canvasHostUrl)',
              ),
              IconButton(
                onPressed: widget.settingsController == null
                    ? null
                    : _openSettings,
                icon: const Icon(Icons.settings_rounded),
                tooltip: l10n.settingsOpenTooltip,
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
                        buttonLabel: connectionStatus.phase == ConnectionPhase.failed
                            ? '重连'
                            : isPairingFailure
                                ? '重试'
                            : l10n.connectionButtonLabel,
                        emphasized:
                            connectionStatus.phase == ConnectionPhase.failed,
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
                      _InfoBanner(
                        message: blockedReason,
                        color: const Color(0xFFFFF2D9),
                        textColor: const Color(0xFF8A5A00),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (connectionStatus.isReady && !hasCanvasHost) ...[
                      const _InfoBanner(
                        message:
                            'Canvas capability unavailable: missing structured canvasHostUrl, chat mode stays active.',
                        color: Color(0xFF2F6BFF),
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (widget.chatController.errorNotice != null) ...[
                      ErrorNoticeBanner(
                        notice: widget.chatController.errorNotice!,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Expanded(
                      child: messages.isEmpty
                          ? _ChatEmptyState(
                              l10n: l10n,
                              discoveryCommands: discoveryCommands,
                              onSelectCommand: _applyCommandTemplate,
                            )
                          : ListView.separated(
                              controller: messageScrollController,
                              padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
                              itemCount: messages.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                return MessageBubble(message: messages[index]);
                              },
                            ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
                      child: ChatComposer(
                        controller: composerController,
                        focusNode: composerFocusNode,
                        enabled: widget.connectionController.canSend,
                        hasContent: hasDraftContent,
                        isSending: widget.chatController.isSending,
                        attachments: pendingAttachments,
                        commandSuggestions: commandSuggestions,
                        commandHintKind: commandHint,
                        onSelectCommandSuggestion: _applyCommandTemplate,
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

  void _openCanvas() {
    final settingsController = widget.settingsController;
    final sendCanvasUserActionUseCase = widget.sendCanvasUserActionUseCase;
    final canvasHostUrl =
        widget.connectionController.status.canvasCapability.canvasHostUrl;
    if (settingsController == null ||
        sendCanvasUserActionUseCase == null ||
        canvasHostUrl == null ||
        canvasHostUrl.trim().isEmpty) {
      _showCanvasUnavailableHint();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CanvasScreen(
          initialCanvasHostUrl: canvasHostUrl,
          canvasCapability:
              widget.connectionController.status.canvasCapability.canvasCapability,
          configProvider: () => settingsController.config,
          sendCanvasUserActionUseCase: sendCanvasUserActionUseCase,
        ),
      ),
    );
  }

  void _showCanvasUnavailableHint() {
    final message = widget.connectionController.status.isReady
        ? '当前连接未提供结构化 canvasHostUrl，已降级为普通聊天模式。'
        : '请先连接 Gateway，连接成功后再尝试进入 canvas。';
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _openConversationList() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return ConversationListSheet(
          conversations: widget.chatController.conversationSummaries,
          activeConversationId: widget.chatController.activeConversationSummary?.id,
          onCreateConversation: () async {
            await widget.chatController.createConversation();
            if (!mounted) {
              return;
            }
            composerController.clear();
            setState(pendingAttachments.clear);
          },
          onSelectConversation: (conversationId) async {
            await widget.chatController.switchConversation(conversationId);
            if (!mounted) {
              return;
            }
            composerController.clear();
            setState(pendingAttachments.clear);
          },
        );
      },
    );
  }

  void _handleComposerChange() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _applyCommandTemplate(String template) {
    composerController.value = TextEditingValue(
      text: template,
      selection: TextSelection.collapsed(offset: template.length),
    );
    composerFocusNode.requestFocus();
    setState(() {});
  }

  Future<void> _pickImages() async {
    final l10n = AppLocalizations.of(context)!;
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
            ? l10n.pickerErrorChannel
            : l10n.pickerErrorGeneric,
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
      _presentPickerError(l10n.pickerErrorUnavailable);
    } catch (error, stackTrace) {
      openClawLog(
        'ChatScreen',
        'pick images failed',
        fields: <String, Object?>{
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
      _presentPickerError(l10n.pickerErrorGeneric);
    }
  }

  void _removeAttachment(SelectedImageAttachment attachment) {
    setState(() {
      pendingAttachments.remove(attachment);
    });
  }

  void _presentPickerError(String message) {
    final l10n = AppLocalizations.of(context)!;
    final kind = message == l10n.pickerErrorChannel
        ? AppErrorKind.pickerChannel
        : message == l10n.pickerErrorUnavailable
            ? AppErrorKind.pickerUnavailable
            : AppErrorKind.pickerGeneric;
    widget.chatController.showInlineError(
      kind: kind,
      rawMessage: message,
      code: 'PICKER_ERROR',
    );
  }

  void _syncMessageViewport({
    required String? conversationId,
    required List<ChatMessage> messages,
  }) {
    final signature = _messageSignature(messages);
    final conversationChanged = conversationId != lastObservedConversationId;
    final messageChanged = signature != lastObservedMessageSignature;
    if (!conversationChanged && !messageChanged) {
      return;
    }

    lastObservedConversationId = conversationId;
    lastObservedMessageSignature = signature;

    final shouldForceScroll = conversationChanged;
    final shouldAutoScroll =
        shouldForceScroll || (messageChanged && _isNearLatestMessage());
    if (!shouldAutoScroll) {
      return;
    }

    _scheduleScrollToLatest(force: shouldForceScroll);
  }

  void _scheduleScrollToLatest({required bool force}) {
    pendingForceScroll = pendingForceScroll || force;
    if (autoScrollScheduled) {
      return;
    }
    autoScrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      autoScrollScheduled = false;
      final shouldForceScroll = pendingForceScroll;
      pendingForceScroll = false;
      _scrollToLatest(force: shouldForceScroll);
    });
  }

  void _scrollToLatest({required bool force}) {
    if (!messageScrollController.hasClients) {
      return;
    }
    final targetOffset = messageScrollController.position.maxScrollExtent;
    if (force) {
      messageScrollController.jumpTo(targetOffset);
      return;
    }
    messageScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  bool _isNearLatestMessage() {
    if (!messageScrollController.hasClients) {
      return true;
    }
    final position = messageScrollController.position;
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    return distanceToBottom <= 120;
  }

  String _messageSignature(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return 'empty';
    }
    final lastMessage = messages.last;
    return [
      messages.length,
      lastMessage.id,
      lastMessage.text.length,
      lastMessage.isStreaming,
    ].join('|');
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
    AppLocalizations l10n,
    ConnectionStatus status,
    bool isConnecting,
  ) {
    if (isConnecting) {
      return l10n.connectionConnectingTitle;
    }
    if (status.failure != null) {
      return localizedGatewayFailure(l10n, failure: status.failure);
    }
    return l10n.connectionStartTitle;
  }

  static String _connectionSubtitle(
    AppLocalizations l10n,
    ConnectionStatus status,
    bool isConnecting,
  ) {
    if (isConnecting) {
      return '';
    }
    if (status.failure != null) {
      if (status.failure!.type == GatewayFailureType.pairingRequired) {
        return l10n.connectionPairingRequiredSubtitle;
      }
      return l10n.connectionRetrySubtitle;
    }
    if (!status.isReady) {
      return l10n.connectionStatusSubtitle(
        localizedPhaseLabel(l10n, status.phase.value),
      );
    }
    return '';
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
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
  const _ChatEmptyState({
    required this.l10n,
    required this.discoveryCommands,
    required this.onSelectCommand,
  });

  final AppLocalizations l10n;
  final List<ChatCommandSuggestion> discoveryCommands;
  final ValueChanged<String> onSelectCommand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDiscovery = discoveryCommands.isNotEmpty;
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
              l10n.chatEmptyTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.chatEmptySubtitle,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (hasDiscovery) ...[
              const SizedBox(height: 16),
              Text(
                l10n.chatCommandDiscoveryPrompt,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final command in discoveryCommands)
                    _DiscoveryCommandChip(
                      command: command.command,
                      description: _descriptionLabel(
                        l10n,
                        command.descriptionKey,
                      ),
                      onPressed: () => onSelectCommand(command.template),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DiscoveryCommandChip extends StatelessWidget {
  const _DiscoveryCommandChip({
    required this.command,
    required this.description,
    required this.onPressed,
  });

  final String command;
  final String description;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 138,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.86),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.65),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              command,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall,
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
    required this.buttonLabel,
    this.emphasized = false,
    this.onPressed,
  });

  final String title;
  final String subtitle;
  final bool showButton;
  final String buttonLabel;
  final bool emphasized;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF2F6BFF),
            Color(0xFF1F57DF),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5E8BFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
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
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: foregroundColor.withOpacity(0.88),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showButton) ...[
            const SizedBox(width: 10),
            if (emphasized)
              FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2F6BFF),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(buttonLabel),
              )
            else
              OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.62)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(buttonLabel),
              ),
          ],
        ],
      ),
    );
  }
}

String _descriptionLabel(AppLocalizations l10n, String key) {
  switch (key) {
    case 'commandDescriptionNew':
      return l10n.commandDescriptionNew;
    case 'commandDescriptionStatus':
      return l10n.commandDescriptionStatus;
    case 'commandDescriptionModel':
      return l10n.commandDescriptionModel;
    case 'commandDescriptionThink':
      return l10n.commandDescriptionThink;
    case 'commandDescriptionHelp':
      return l10n.commandDescriptionHelp;
    case 'commandDescriptionReset':
      return l10n.commandDescriptionReset;
    case 'commandDescriptionCompact':
      return l10n.commandDescriptionCompact;
    case 'commandDescriptionStop':
      return l10n.commandDescriptionStop;
    case 'commandDescriptionFast':
      return l10n.commandDescriptionFast;
    default:
      return key;
  }
}
