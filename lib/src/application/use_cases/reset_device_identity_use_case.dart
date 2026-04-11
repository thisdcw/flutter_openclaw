import '../../domain/repositories/auth_repository.dart';

class ResetDeviceIdentityUseCase {
  ResetDeviceIdentityUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> call() => _authRepository.clearDeviceIdentity();
}
