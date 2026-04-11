import '../models/device_identity.dart';
import '../models/operator_auth_state.dart';

abstract class AuthRepository {
  Future<DeviceIdentity?> loadDeviceIdentity();
  Future<void> saveDeviceIdentity(DeviceIdentity identity);
  Future<void> clearDeviceIdentity();

  Future<OperatorAuthState?> loadOperatorAuth();
  Future<void> saveOperatorAuth(OperatorAuthState state);
  Future<void> clearOperatorAuth();

  Future<String?> loadAuthToken();
  Future<void> saveAuthToken(String token);
  Future<void> clearAuthToken();
}
