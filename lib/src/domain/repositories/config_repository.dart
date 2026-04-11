import '../models/gateway_config.dart';

abstract class ConfigRepository {
  Future<GatewayConfig> load();
  Future<void> save(GatewayConfig config);
}
