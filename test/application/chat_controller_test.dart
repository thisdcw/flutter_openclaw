import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_openclaw/src/application/controllers/chat_controller.dart';

void main() {
  group('ChatController', () {
    test('adds user message before awaiting assistant stream', () async {
      final controller = ChatController.fake();
      await controller.send('hello');

      expect(controller.messages.first.text, 'hello');
    });
  });
}
