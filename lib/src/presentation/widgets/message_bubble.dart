import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_openclaw/l10n/app_localizations.dart';

import '../../domain/models/chat_message.dart';
import '../../domain/models/selected_image_attachment.dart';
import '../localization/localized_gateway_text.dart';
import '../screens/image_preview_screen.dart';
import 'chat_markdown_text.dart';
import 'message_content_parser.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isError = message.role == MessageRole.error;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final backgroundColor = isError
        ? theme.colorScheme.errorContainer
        : isUser
            ? theme.colorScheme.primary
            : Colors.white;
    final textColor = isError
        ? theme.colorScheme.onErrorContainer
        : isUser
            ? Colors.white
            : theme.colorScheme.onSurface;
    final content = message.text.isEmpty && message.isStreaming
        ? '...'
        : message.text;
    final segments = parseMessageContent(content);
    final hasLocalAttachments = isUser && message.attachments.isNotEmpty;
    final hasTextSegments = segments.isNotEmpty;

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onLongPress: () async {
          await Clipboard.setData(
            ClipboardData(text: _buildCopyText(segments)),
          );
          if (!context.mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Copied message')),
          );
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 6),
                bottomRight: Radius.circular(isUser ? 6 : 18),
              ),
              border: isUser || isError
                  ? null
                  : Border.all(color: const Color(0xFFDCE7F6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasLocalAttachments) ...[
                  _UserAttachmentGrid(
                    attachments: message.attachments,
                    onOpenAttachment: (attachment) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ImagePreviewScreen.memory(
                            bytes: Uint8List.fromList(attachment.bytes),
                            fileName: attachment.fileName,
                            mimeType: attachment.mimeType,
                          ),
                        ),
                      );
                    },
                  ),
                  if (hasTextSegments || message.isStreaming)
                    const SizedBox(height: 8),
                ],
                for (var index = 0; index < segments.length; index++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: index == segments.length - 1 ? 0 : 6,
                    ),
                    child: _MessageSegmentView(
                      segment: segments[index],
                      isError: isError,
                      textColor: textColor,
                      isUser: isUser,
                      l10n: l10n,
                    ),
                  ),
                if (message.isStreaming) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.streamingResponseLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: textColor.withOpacity(0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildCopyText(List<MessageContentSegment> segments) {
    final normalized = message.text.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
    if (message.attachments.isNotEmpty) {
      return message.attachments.map((item) => item.fileName).join('\n');
    }
    return segments
        .whereType<MessageImageSegment>()
        .map((segment) => segment.url)
        .join('\n');
  }
}

class _UserAttachmentGrid extends StatelessWidget {
  const _UserAttachmentGrid({
    required this.attachments,
    required this.onOpenAttachment,
  });

  final List<SelectedImageAttachment> attachments;
  final ValueChanged<SelectedImageAttachment> onOpenAttachment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final attachment in attachments)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onTap: () => onOpenAttachment(attachment),
              child: Container(
                width: 78,
                height: 78,
                color: Colors.white.withOpacity(0.16),
                child: Image.memory(
                  Uint8List.fromList(attachment.bytes),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        attachment.fileName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MessageSegmentView extends StatelessWidget {
  const _MessageSegmentView({
    required this.segment,
    required this.isError,
    required this.textColor,
    required this.isUser,
    required this.l10n,
  });

  final MessageContentSegment segment;
  final bool isError;
  final Color textColor;
  final bool isUser;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (segment is MessageTextSegment) {
      final textSegment = segment as MessageTextSegment;
      final localizedText = isError
          ? localizedGatewayFailure(
              l10n,
              rawReason: textSegment.text,
            )
          : textSegment.text;
      return ChatMarkdownText(
        text: localizedText,
        textColor: textColor,
      );
    }

    final imageSegment = segment as MessageImageSegment;
    final uri = Uri.tryParse(imageSegment.url);
    final fileName = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : 'openclaw-image';
    final mimeType = _guessMimeType(fileName);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ImagePreviewScreen.network(
              imageUrl: imageSegment.url,
              fileName: fileName,
              mimeType: mimeType,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: Image.network(
            imageSegment.url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                color: isUser
                    ? Colors.white.withOpacity(0.18)
                    : const Color(0xFFF2F6FB),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: isUser
                    ? Colors.white.withOpacity(0.14)
                    : const Color(0xFFF2F6FB),
                child: Text(
                  imageSegment.altText ?? imageSegment.url,
                  style: theme.textTheme.bodySmall?.copyWith(color: textColor),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

String _guessMimeType(String fileName) {
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
