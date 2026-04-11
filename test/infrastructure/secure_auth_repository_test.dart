import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_openclaw/src/domain/models/operator_auth_state.dart';
import 'package:flutter_openclaw/src/infrastructure/storage/secure_auth_repository.dart';

void main() {
  group('SecureAuthRepository', () {
    test('operator auth state round-trips through the in-memory repository',
        () async {
      final repository = SecureAuthRepository.inMemory();
      const authState = OperatorAuthState(
        role: 'operator',
        deviceToken: 'device-token-1',
        scopes: ['operator.read', 'operator.write'],
      );

      await repository.saveOperatorAuth(authState);
      final loaded = await repository.loadOperatorAuth();

      expect(loaded, authState);
      expect(loaded?.hasWriteScope, isTrue);
    });
  });
}
