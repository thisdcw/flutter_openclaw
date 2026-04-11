import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_openclaw/src/infrastructure/gateway/request_tracker.dart';

void main() {
  group('RequestTracker', () {
    test('moves a request from requestId tracking to runId tracking', () {
      final tracker = RequestTracker();
      tracker.create(requestId: 'req-1');
      tracker.attachRunId(requestId: 'req-1', runId: 'run-1');

      expect(tracker.byRequestId('req-1')?.runId, 'run-1');
      expect(tracker.byRunId('run-1')?.requestId, 'req-1');
    });
  });
}
