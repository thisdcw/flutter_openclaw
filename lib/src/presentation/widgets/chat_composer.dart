import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_openclaw/l10n/app_localizations.dart';

import '../../domain/models/selected_image_attachment.dart';
import 'attachment_preview_strip.dart';
import 'chat_command_assist.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.hasContent,
    required this.isSending,
    required this.attachments,
    required this.onPickImages,
    required this.onRemoveAttachment,
    required this.onSend,
    required this.commandSuggestions,
    required this.commandHintKind,
    required this.onSelectCommandSuggestion,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool hasContent;
  final bool isSending;
  final List<SelectedImageAttachment> attachments;
  final Future<void> Function() onPickImages;
  final ValueChanged<SelectedImageAttachment> onRemoveAttachment;
  final Future<void> Function() onSend;
  final List<ChatCommandSuggestion> commandSuggestions;
  final ChatCommandHintKind commandHintKind;
  final ValueChanged<String> onSelectCommandSuggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final fieldEnabled = enabled && !isSending;
    final sendEnabled = fieldEnabled && hasContent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AttachmentPreviewStrip(
            attachments: attachments,
            enabled: fieldEnabled,
            onRemove: onRemoveAttachment,
          ),
          if (attachments.isNotEmpty) const SizedBox(height: 6),
          if (commandHintKind != ChatCommandHintKind.none) ...[
            _CommandHint(hintKind: commandHintKind),
            const SizedBox(height: 4),
          ],
          if (commandSuggestions.isNotEmpty) ...[
            _CommandSuggestionPanel(
              suggestions: commandSuggestions,
              onSelect: onSelectCommandSuggestion,
            ),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              IconButton(
                onPressed: fieldEnabled
                    ? () {
                        unawaited(onPickImages());
                      }
                    : null,
                icon: const Icon(Icons.photo_library_rounded),
                tooltip: l10n.addImagesTooltip,
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: fieldEnabled,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: l10n.composerModeHint,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: sendEnabled
                    ? () {
                        unawaited(onSend());
                      }
                    : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  minimumSize: Size.zero,
                ),
                child: Text(isSending ? l10n.sendingLabel : l10n.sendLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommandHint extends StatelessWidget {
  const _CommandHint({required this.hintKind});

  final ChatCommandHintKind hintKind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hintText = _hintLabel(l10n, hintKind);
    final primary = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bolt,
            size: 16,
            color: primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              hintText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandSuggestionPanel extends StatelessWidget {
  const _CommandSuggestionPanel({
    required this.suggestions,
    required this.onSelect,
  });

  final List<ChatCommandSuggestion> suggestions;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final grouped = <String, List<ChatCommandSuggestion>>{};
    for (final suggestion in suggestions) {
      grouped.putIfAbsent(suggestion.groupKey, () => []).add(suggestion);
    }
    final entries = grouped.entries.toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (_groupLabel(l10n, entries[i].key).isNotEmpty) ...[
              Text(
                _groupLabel(l10n, entries[i].key),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 6),
            ],
            ...entries[i].value.map(
              (suggestion) => _CommandSuggestionTile(
                suggestion: suggestion,
                onSelect: onSelect,
              ),
            ),
            if (i != entries.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _CommandSuggestionTile extends StatelessWidget {
  const _CommandSuggestionTile({
    required this.suggestion,
    required this.onSelect,
  });

  final ChatCommandSuggestion suggestion;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onSelect(suggestion.template),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.command,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _descriptionLabel(
                    AppLocalizations.of(context)!,
                    suggestion.descriptionKey,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _hintLabel(AppLocalizations l10n, ChatCommandHintKind kind) {
  switch (kind) {
    case ChatCommandHintKind.standaloneGateway:
      return l10n.semanticHintGatewayStandalone;
    case ChatCommandHintKind.inlineDirective:
      return l10n.semanticHintInlineDirective;
    case ChatCommandHintKind.standaloneRecommended:
      return l10n.semanticHintStandaloneRecommended;
    case ChatCommandHintKind.localCommand:
      return l10n.semanticHintLocalClear;
    default:
      return '';
  }
}

String _groupLabel(AppLocalizations l10n, String key) {
  switch (key) {
    case 'commandGroupSessionLabel':
      return l10n.commandGroupSessionLabel;
    case 'commandGroupStatusLabel':
      return l10n.commandGroupStatusLabel;
    case 'commandGroupSettingsLabel':
      return l10n.commandGroupSettingsLabel;
    default:
      return key;
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
