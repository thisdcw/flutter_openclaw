import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_openclaw/src/application/controllers/chat_controller.dart';
import 'package:flutter_openclaw/src/domain/models/chat_draft.dart';
import 'package:flutter_openclaw/src/domain/models/selected_image_attachment.dart';

void main() {
  group('ChatController', () {
    test('adds user message before awaiting assistant stream', () async {
      final controller = ChatController.fake();
      await controller.send(
        ChatDraft(text: 'hello', attachments: const []),
      );

      expect(controller.messages.first.text, 'hello');
    });

    test('allows image-only drafts and preserves attachments', () async {
      final controller = ChatController.fake();
      final attachment = SelectedImageAttachment(
        id: 'img-1',
        fileName: 'cat.png',
        mimeType: 'image/png',
        bytes: <int>[1, 2, 3],
      );

      await controller.send(
        ChatDraft(text: '   ', attachments: <SelectedImageAttachment>[attachment]),
      );

      expect(controller.messages, hasLength(1));
      expect(controller.messages.first.text, '');
      expect(controller.messages.first.attachments, <SelectedImageAttachment>[
        attachment,
      ]);
    });
  });
}
