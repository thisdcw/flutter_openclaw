import '../../domain/repositories/auth_repository.dart';
import '../../infrastructure/crypto/keystore_signer.dart';

class ResetDeviceIdentityUseCase {
  ResetDeviceIdentityUseCase(
    this._authRepository, {
    KeystoreSigner? keystore,
  }) : _keystore = keystore ?? KeystoreSigner();

  final AuthRepository _authRepository;
  final KeystoreSigner _keystore;

  Future<void> call() async {
    await _keystore.clearKeypair();
    await _authRepository.clearDeviceIdentity();
  }
}
