import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_openclaw/src/application/controllers/connection_controller.dart';

void main() {
  group('ConnectionController', () {
    test('marks missing operator.write before send', () {
      final controller = ConnectionController.fake()
        ..grantedScopes = ['operator.read']
        ..phase = 'ready';

      expect(controller.canSend, isFalse);
      expect(controller.sendBlockedReason, contains('operator.write'));
    });
  });
}
