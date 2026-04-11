import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_openclaw/src/domain/models/chat_draft.dart';
import 'package:flutter_openclaw/src/domain/models/chat_input_part.dart';
import 'package:flutter_openclaw/src/domain/models/selected_image_attachment.dart';

void main() {
  test('serializes text and image parts in order', () {
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

    final parts = draft.toGatewayContent();
    expect(parts.length, 2);
    expect(parts.first, const ChatInputTextPart('analyze these'));
    expect(parts.last, isA<ChatInputImagePart>());

    final imagePart = parts.last as ChatInputImagePart;
    expect(
      parts.first.toJson(),
      const <String, Object?>{'type': 'text', 'text': 'analyze these'},
    );
    expect(
      imagePart.toJson(),
      <String, Object?>{
        'type': 'image',
        'source': <String, Object?>{
          'type': 'base64',
          'mimeType': 'image/jpeg',
          'data': base64.encode(<int>[1, 2, 3]),
        },
      },
    );
  });

  test('image-only draft remains sendable and serializes image part', () {
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

    final parts = draft.toGatewayContent();
    expect(parts.length, 1);
    expect(parts.first, isA<ChatInputImagePart>());

    final imagePart = parts.first as ChatInputImagePart;
    expect(
      imagePart.toJson(),
      <String, Object?>{
        'type': 'image',
        'source': <String, Object?>{
          'type': 'base64',
          'mimeType': 'image/png',
          'data': base64.encode(<int>[9, 8, 7]),
        },
      },
    );
  });
}
