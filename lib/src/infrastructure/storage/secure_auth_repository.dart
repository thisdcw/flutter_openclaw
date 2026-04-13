import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/models/device_identity.dart';
import '../../domain/models/operator_auth_state.dart';
import '../../domain/repositories/auth_repository.dart';
import '../util/openclaw_logger.dart';

class SecureAuthRepository implements AuthRepository {
  SecureAuthRepository([FlutterSecureStorage? storage])
      : _storage =
            _FlutterSecureStorageAdapter(storage ?? FlutterSecureStorage());

  SecureAuthRepository._(this._storage);

  static SecureAuthRepository inMemory() {
    return SecureAuthRepository._(_InMemorySecureStorage());
  }

  static const String _deviceIdentityKey = 'openclaw.device_identity';
  static const String _operatorAuthStateKey = 'openclaw.operator_auth_state';

  final _SecureStorage _storage;

  @override
  Future<void> clearDeviceIdentity() {
    openClawLog('SecureAuthRepository', 'clear device identity');
    return _storage.delete(key: _deviceIdentityKey);
  }

  @override
  Future<void> clearOperatorAuth() {
    openClawLog('SecureAuthRepository', 'clear operator auth');
    return _storage.delete(key: _operatorAuthStateKey);
  }

  @override
  Future<DeviceIdentity?> loadDeviceIdentity() async {
    final payload = await _storage.read(key: _deviceIdentityKey);
    if (payload == null || payload.trim().isEmpty) {
      openClawLog('SecureAuthRepository', 'load device identity: empty');
      return null;
    }

    final decoded = _decodeStoredJsonObject(
      payload,
      valueName: 'device identity',
    );
    final identity = DeviceIdentity.fromJson(decoded);
    openClawLog(
      'SecureAuthRepository',
      'load device identity',
      fields: <String, Object?>{
        'deviceId': identity.id,
      },
    );
    return identity;
  }

  @override
  Future<OperatorAuthState?> loadOperatorAuth() async {
    final payload = await _storage.read(key: _operatorAuthStateKey);
    if (payload == null || payload.trim().isEmpty) {
      openClawLog('SecureAuthRepository', 'load operator auth: empty');
      return null;
    }

    final decoded = _decodeStoredJsonObject(
      payload,
      valueName: 'operator auth state',
    );
    final auth = OperatorAuthState.fromJson(decoded);
    openClawLog(
      'SecureAuthRepository',
      'load operator auth',
      fields: <String, Object?>{
        'deviceToken': redactValue(auth.deviceToken),
        'scopes': auth.scopes.join(','),
      },
    );
    return auth;
  }

  static Map<String, dynamic> _decodeStoredJsonObject(
    String payload, {
    required String valueName,
  }) {
    final decoded = jsonDecode(payload);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    throw FormatException(
      'SecureAuthRepository: stored $valueName must be a JSON object.',
    );
  }

  @override
  Future<void> saveDeviceIdentity(DeviceIdentity identity) {
    openClawLog(
      'SecureAuthRepository',
      'save device identity',
      fields: <String, Object?>{
        'deviceId': identity.id,
      },
    );
    return _storage.write(
      key: _deviceIdentityKey,
      value: jsonEncode(identity.toJson()),
    );
  }

  @override
  Future<void> saveOperatorAuth(OperatorAuthState state) {
    openClawLog(
      'SecureAuthRepository',
      'save operator auth',
      fields: <String, Object?>{
        'deviceToken': redactValue(state.deviceToken),
        'scopes': state.scopes.join(','),
      },
    );
    return _storage.write(
      key: _operatorAuthStateKey,
      value: jsonEncode(state.toJson()),
    );
  }
}

abstract class _SecureStorage {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
}

class _FlutterSecureStorageAdapter implements _SecureStorage {
  _FlutterSecureStorageAdapter(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete({required String key}) {
    return _storage.delete(key: key);
  }

  @override
  Future<String?> read({required String key}) {
    return _storage.read(key: key);
  }

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }
}

class _InMemorySecureStorage implements _SecureStorage {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> delete({required String key}) async {
    _values.remove(key);
  }

  @override
  Future<String?> read({required String key}) async {
    return _values[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }
}
