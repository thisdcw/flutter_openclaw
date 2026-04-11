import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_openclaw/src/infrastructure/util/failure_mapper.dart';

void main() {
  group('mapGatewayFailure', () {
    test('maps missing write scope to a user-friendly message', () {
      final message = mapGatewayFailure(
        code: 'MISSING_SCOPE',
        reason: 'missing scope: operator.write',
      );

      expect(message, contains('operator.write'));
      expect(message, contains('授权'));
    });
  });
}
