import '../../domain/models/bootstrap_token_state.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/config_repository.dart';
import '../../infrastructure/util/bootstrap_payload_parser.dart';

class ImportBootstrapTokenUseCase {
  ImportBootstrapTokenUseCase(
    this._authRepository,
    this._configRepository,
    this._parser,
  );

  final AuthRepository _authRepository;
  final ConfigRepository _configRepository;
  final BootstrapPayloadParser _parser;

  Future<BootstrapTokenState> call(String input, {int ttlMinutes = 10}) async {
    final payload = _parser.parse(input);
    final now = DateTime.now().millisecondsSinceEpoch;
    final state = BootstrapTokenState(
      token: payload.bootstrapToken,
      gatewayUrl: payload.gatewayUrl,
      importedAt: now,
      expiresAt: now + ttlMinutes * 60 * 1000,
    );
    await _authRepository.saveBootstrapToken(state);
    if (payload.gatewayUrl.isNotEmpty) {
      final config = await _configRepository.load();
      final next = config.copyWith(gatewayUrl: payload.gatewayUrl);
      await _configRepository.save(next);
    }
    return state;
  }
}
