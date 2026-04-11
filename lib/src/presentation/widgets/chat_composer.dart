import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/models/selected_image_attachment.dart';
import 'attachment_preview_strip.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.enabled,
    required this.hasContent,
    required this.isSending,
    required this.attachments,
    required this.onPickImages,
    required this.onRemoveAttachment,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool hasContent;
  final bool isSending;
  final List<SelectedImageAttachment> attachments;
  final Future<void> Function() onPickImages;
  final ValueChanged<SelectedImageAttachment> onRemoveAttachment;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          Row(
            children: [
              IconButton(
                onPressed: fieldEnabled
                    ? () {
                        unawaited(onPickImages());
                      }
                    : null,
                icon: const Icon(Icons.photo_library_rounded),
                tooltip: 'Add images',
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: fieldEnabled,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Message OpenClaw',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
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
                child: Text(isSending ? '...' : 'Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
