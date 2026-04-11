import 'package:collection/collection.dart';

import 'chat_input_part.dart';
import 'selected_image_attachment.dart';

class ChatDraft {
  ChatDraft({
    required this.text,
    required List<SelectedImageAttachment> attachments,
  }) : attachments = List<SelectedImageAttachment>.unmodifiable(attachments);

  final String text;
  final List<SelectedImageAttachment> attachments;

  String get normalizedText => text.trim();

  bool get hasSendableContent =>
      normalizedText.isNotEmpty || attachments.isNotEmpty;

  List<ChatInputPart> toGatewayContent() {
    final parts = <ChatInputPart>[];
    if (normalizedText.isNotEmpty) {
      parts.add(ChatInputTextPart(normalizedText));
    }
    for (final attachment in attachments) {
      parts.add(ChatInputImagePart.fromAttachment(attachment));
    }
    return parts;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatDraft &&
        other.text == text &&
        _listEquality.equals(other.attachments, attachments);
  }

  @override
  int get hashCode => Object.hash(text, _listEquality.hash(attachments));

  @override
  String toString() {
    return 'ChatDraft(text: $text, attachments: ${attachments.length})';
  }

  static const ListEquality<SelectedImageAttachment> _listEquality =
      ListEquality<SelectedImageAttachment>();
}
