import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../domain/models/selected_image_attachment.dart';

class AttachmentPreviewStrip extends StatelessWidget {
  const AttachmentPreviewStrip({
    super.key,
    required this.attachments,
    required this.enabled,
    required this.onRemove,
  });

  final List<SelectedImageAttachment> attachments;
  final bool enabled;
  final ValueChanged<SelectedImageAttachment> onRemove;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          return _AttachmentPreviewTile(
            attachment: attachment,
            enabled: enabled,
            onRemove: onRemove,
          );
        },
      ),
    );
  }
}

class _AttachmentPreviewTile extends StatelessWidget {
  const _AttachmentPreviewTile({
    required this.attachment,
    required this.enabled,
    required this.onRemove,
  });

  final SelectedImageAttachment attachment;
  final bool enabled;
  final ValueChanged<SelectedImageAttachment> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 58,
            height: 58,
            color: const Color(0xFFEAF2FF),
            child: Image.memory(
              Uint8List.fromList(attachment.bytes),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Text(
                    attachment.fileName,
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: enabled ? () => onRemove(attachment) : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(enabled ? 0.55 : 0.24),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
