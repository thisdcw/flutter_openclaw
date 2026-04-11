import '../../domain/repositories/auth_repository.dart';

class ClearOperatorAuthUseCase {
  ClearOperatorAuthUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> call() => _authRepository.clearOperatorAuth();
}
