import '../../domain/models/gateway_config.dart';

const List<String> defaultOperatorScopes = <String>[
  'operator.read',
  'operator.write',
];

const GatewayConfig defaultGatewayConfig = GatewayConfig(
  gatewayUrl: 'wss://thisdcw.cn',
  sessionId: '',
  timeoutMs: 60000,
  locale: 'zh-CN',
  canvasEntryEnabled: true,
);
