import '../../domain/models/gateway_config.dart';

const List<String> defaultOperatorScopes = <String>[
  'operator.read',
  'operator.write',
  'operator.pairing',
];

const GatewayConfig defaultGatewayConfig = GatewayConfig(
  gatewayUrl: 'wss://thisdcw.cn/claw',
  authToken: 'ff158cd1f6c32f4ac8d56d7315802af2e3e94c50bd9f9939',
  sessionId: 'cli-session-default',
  timeoutMs: 60000,
  locale: 'zh-CN',
);
