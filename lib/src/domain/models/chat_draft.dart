import 'dart:convert';

import 'package:collection/collection.dart';

import 'selected_image_attachment.dart';

class GatewayChatAttachment {
  const GatewayChatAttachment({
    required this.type,
    required this.mimeType,
    required this.content,
  });

  final String type;
  final String mimeType;
  final String content;

  factory GatewayChatAttachment.fromSelectedImage(
    SelectedImageAttachment attachment,
  ) {
    return GatewayChatAttachment(
      type: 'image',
      mimeType: attachment.mimeType,
      content: base64.encode(attachment.bytes),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'mimeType': mimeType,
      'content': content,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GatewayChatAttachment &&
        other.type == type &&
        other.mimeType == mimeType &&
        other.content == content;
  }

  @override
  int get hashCode => Object.hash(type, mimeType, content);
}

class ChatDraft {
  ChatDraft({
    required this.text,
    required List<SelectedImageAttachment> attachments,
    this.preferredModelId,
  }) : attachments = List<SelectedImageAttachment>.unmodifiable(attachments);

  final String text;
  final List<SelectedImageAttachment> attachments;
  final String? preferredModelId;

  String get normalizedText => text.trim();

  bool get hasSendableContent =>
      normalizedText.isNotEmpty || attachments.isNotEmpty;

  String toGatewayMessage() {
    final normalized = normalizedText;
    final model = preferredModelId?.trim() ?? '';
    if (model.isEmpty) {
      return normalized;
    }
    if (normalized.startsWith('/')) {
      return normalized;
    }
    if (normalized.isEmpty) {
      return '/model $model';
    }
    return '/model $model\n$normalized';
  }

  List<GatewayChatAttachment> toGatewayAttachments() => attachments
      .map(GatewayChatAttachment.fromSelectedImage)
      .toList(growable: false);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatDraft &&
        other.text == text &&
        other.preferredModelId == preferredModelId &&
        _listEquality.equals(other.attachments, attachments);
  }

  @override
  int get hashCode =>
      Object.hash(text, preferredModelId, _listEquality.hash(attachments));

  @override
  String toString() {
    return 'ChatDraft(text: $text, model: $preferredModelId, attachments: '
        '${attachments.length})';
  }

  static const ListEquality<SelectedImageAttachment> _listEquality =
      ListEquality<SelectedImageAttachment>();
}
