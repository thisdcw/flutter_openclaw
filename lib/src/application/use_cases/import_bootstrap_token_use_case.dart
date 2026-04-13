import '../../domain/models/bootstrap_token_state.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/config_repository.dart';
import '../../infrastructure/config/dev_defaults.dart';
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
    _guardAgainstLocalhostPairingUrl(payload.gatewayUrl);
    final fixedGatewayUrl = defaultGatewayConfig.gatewayUrl;
    final now = DateTime.now().millisecondsSinceEpoch;
    final state = BootstrapTokenState(
      token: payload.bootstrapToken,
      gatewayUrl: fixedGatewayUrl,
      importedAt: now,
      expiresAt: now + ttlMinutes * 60 * 1000,
    );
    await _authRepository.saveBootstrapToken(state);
    final config = await _configRepository.load();
    final next = config.copyWith(gatewayUrl: fixedGatewayUrl);
    await _configRepository.save(next);
    return state;
  }

  void _guardAgainstLocalhostPairingUrl(String gatewayUrl) {
    if (gatewayUrl.trim().isEmpty) {
      return;
    }

    final uri = Uri.tryParse(gatewayUrl.trim());
    final host = uri?.host.toLowerCase() ?? '';
    if (host == '127.0.0.1' || host == 'localhost' || host == '::1') {
      throw StateError(
        '当前导入的配对码指向本地地址 $gatewayUrl。'
        '这通常是开发环境生成的配对码，不能用于连接公网网关。'
        '请重新生成指向正式网关的配对码，例如 wss://thisdcw.cn/claw。',
      );
    }
  }

}
