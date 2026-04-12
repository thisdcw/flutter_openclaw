import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_openclaw/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import '../../application/controllers/chat_controller.dart';
import '../../application/controllers/connection_controller.dart';
import '../../application/controllers/settings_controller.dart';
import '../../domain/models/chat_draft.dart';
import '../../domain/models/connection_status.dart';
import '../../domain/models/gateway_failure.dart';
import '../../domain/models/selected_image_attachment.dart';
import '../../infrastructure/util/openclaw_logger.dart';
import '../localization/localized_gateway_text.dart';
import '../widgets/chat_command_assist.dart';
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
  late final FocusNode composerFocusNode;
  late final ImagePicker imagePicker;
  final List<SelectedImageAttachment> pendingAttachments = [];
  final Uuid uuid = Uuid();

  @override
  void initState() {
    super.initState();
    composerController = TextEditingController();
    composerController.addListener(_handleComposerChange);
    composerFocusNode = FocusNode();
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
        final localizedFailureMessage = _localizedChatError(l10n);
        final messages = widget.chatController.messages;
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

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.chatScreenTitle, style: theme.textTheme.titleMedium),
            actions: [
              StatusBadge(label: widget.connectionController.phase),
              const SizedBox(width: 6),
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
                        showButton: !isConnecting && !isPairingFailure,
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
                        message: localizedFailureMessage,
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
                            ? _ChatEmptyState(
                                l10n: l10n,
                                discoveryCommands: discoveryCommands,
                                onSelectCommand: _applyCommandTemplate,
                              )
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

  String _localizedChatError(AppLocalizations l10n) {
    final rawError = widget.chatController.errorMessage ?? '';
    if (rawError.isEmpty) {
      return '';
    }
    return localizedGatewayFailure(l10n, rawReason: rawError);
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
              child: Text(AppLocalizations.of(context)!.connectionButtonLabel),
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
