import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_openclaw/src/domain/models/chat_draft.dart';
import 'package:flutter_openclaw/src/domain/models/selected_image_attachment.dart';

void main() {
  test('serializes text separately from gateway attachments', () {
    final draft = ChatDraft(
      text: 'analyze these',
      attachments: <SelectedImageAttachment>[
        SelectedImageAttachment(
          id: 'image-1',
          fileName: 'sample.jpg',
          mimeType: 'image/jpeg',
          bytes: <int>[1, 2, 3],
        ),
      ],
    );

    final attachments = draft.toGatewayAttachments();

    expect(draft.toGatewayMessage(), 'analyze these');
    expect(attachments.length, 1);
    expect(
      attachments.first.toJson(),
      <String, Object?>{
        'type': 'image',
        'mimeType': 'image/jpeg',
        'content': base64.encode(<int>[1, 2, 3]),
      },
    );
  });

  test('image-only draft remains sendable with empty message', () {
    final draft = ChatDraft(
      text: '   ',
      attachments: <SelectedImageAttachment>[
        SelectedImageAttachment(
          id: 'image-2',
          fileName: 'only.png',
          mimeType: 'image/png',
          bytes: <int>[9, 8, 7],
        ),
      ],
    );

    expect(draft.normalizedText, '');
    expect(draft.hasSendableContent, isTrue);

    final attachments = draft.toGatewayAttachments();
    expect(draft.toGatewayMessage(), '');
    expect(attachments.length, 1);
    expect(
      attachments.first.toJson(),
      <String, Object?>{
        'type': 'image',
        'mimeType': 'image/png',
        'content': base64.encode(<int>[9, 8, 7]),
      },
    );
  });
}
