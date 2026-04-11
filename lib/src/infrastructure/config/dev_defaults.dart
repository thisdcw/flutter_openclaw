import '../../domain/models/gateway_config.dart';

const List<String> defaultOperatorScopes = <String>[
  'operator.read',
  'operator.write',
  'operator.admin',
  'operator.approvals',
  'operator.pairing',
];

const GatewayConfig defaultGatewayConfig = GatewayConfig(
  gatewayUrl: 'ws://192.168.10.131:18789',
  authToken: '08c06aff8510f6a14567ae8640c5aea3b02aee3d863a5ecd',
  sessionId: 'cli-session-default',
  timeoutMs: 60000,
  locale: 'zh-CN',
);
