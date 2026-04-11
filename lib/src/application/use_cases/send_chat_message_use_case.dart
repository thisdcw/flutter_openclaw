import '../../domain/models/chat_draft.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/gateway_config.dart';
import '../../infrastructure/gateway/gateway_protocol_parser.dart';
import '../../infrastructure/gateway/live_chat_repository.dart';
import '../../infrastructure/gateway/request_tracker.dart';
import '../../infrastructure/util/openclaw_logger.dart';
import 'test_connection_use_case.dart';

class SendChatMessageUseCase {
  SendChatMessageUseCase(
    this._testConnectionUseCase, {
    GatewayProtocolParser? parser,
  }) : _parser = parser ?? const GatewayProtocolParser();

  final TestConnectionUseCase _testConnectionUseCase;
  final GatewayProtocolParser _parser;

  Stream<ChatMessage> call(
    ChatDraft draft, {
    required GatewayConfig config,
  }) async* {
    final normalizedText = draft.normalizedText;
    openClawLog(
      'SendChatMessage',
      'send flow start',
      fields: <String, Object?>{
        'gatewayUrl': config.gatewayUrl,
        'sessionId': config.sessionId,
        'textLength': normalizedText.length,
        'attachmentCount': draft.attachments.length,
        'preview': truncateForLog(normalizedText, maxLength: 80),
      },
    );
    final session = await _testConnectionUseCase.connect(config: config);
    try {
      openClawLog(
        'SendChatMessage',
        'authenticated session ready',
        fields: <String, Object?>{
          'deviceId': session.deviceIdentity.id,
          'scopes': session.operatorAuth?.scopes.join(',') ?? '(none)',
        },
      );
      final repository = LiveChatRepository(
        session.client,
        RequestTracker(),
        parser: _parser,
        timeout: Duration(milliseconds: config.timeoutMs),
      );
      yield* repository.sendMessage(draft, sessionId: config.sessionId);
    } finally {
      openClawLog('SendChatMessage', 'dispose authenticated session');
      await session.dispose();
    }
  }
}
