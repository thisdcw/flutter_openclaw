import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_openclaw/src/application/controllers/connection_controller.dart';
import 'package:flutter_openclaw/src/domain/models/connection_status.dart';

void main() {
  group('ConnectionController', () {
    test('marks missing operator.write before send', () {
      final controller = ConnectionController.fake()
        ..grantedScopes = ['operator.read']
        ..phase = 'ready';

      expect(controller.canSend, isFalse);
      expect(controller.sendBlockedReason, contains('operator.write'));
    });

    test('connectIfNeeded skips when stubbed', () async {
      final controller = ConnectionController.fake();

      await controller.connectIfNeeded();

      expect(controller.status.phase, ConnectionPhase.idle);
      expect(controller.status.failure, isNull);
    });

    test('connectIfNeeded marks failure when not configured', () async {
      final controller = ConnectionController();

      await controller.connectIfNeeded();

      expect(controller.status.phase, ConnectionPhase.failed);
      expect(controller.status.failure, isNotNull);
    });
  });
}
