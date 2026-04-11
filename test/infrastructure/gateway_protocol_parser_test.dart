import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_openclaw/src/domain/models/connect_challenge.dart';
import 'package:flutter_openclaw/src/domain/models/gateway_failure.dart';
import 'package:flutter_openclaw/src/domain/models/operator_auth_state.dart';
import 'package:flutter_openclaw/src/infrastructure/gateway/gateway_protocol_parser.dart';

void main() {
  group('GatewayProtocolParser', () {
    test('extracts challenge and hello-ok frames', () {
      const parser = GatewayProtocolParser();
      final challenge = parser.parse(
        '{"type":"event","event":"connect.challenge","payload":{"nonce":"n1"}}',
      );
      final hello = parser.parse(
        '{"type":"res","payload":{"type":"hello-ok","auth":{"role":"operator","deviceToken":"device-token-1","scopes":["operator.write"]}}}',
      );

      expect(challenge.event, 'connect.challenge');
      expect(
        parser.extractChallenge(challenge),
        const ConnectChallenge(nonce: 'n1'),
      );
      expect(hello.payloadType, 'hello-ok');
      expect(
        parser.extractHelloOkAuth(hello),
        const OperatorAuthState(
          role: 'operator',
          deviceToken: 'device-token-1',
          scopes: ['operator.write'],
        ),
      );
    });

    test('extracts assistant delta from delta text and content arrays', () {
      const parser = GatewayProtocolParser();
      final deltaFrame = parser.parse(
        '{"type":"event","event":"chat","payload":{"stream":"assistant","data":{"delta":"你好"}}}',
      );
      final textFrame = parser.parse(
        '{"type":"event","event":"chat","payload":{"stream":"assistant","data":{"text":"世界"}}}',
      );
      final contentFrame = parser.parse(
        '{"type":"event","event":"chat","payload":{"stream":"assistant","data":{"content":[{"text":"A"},{"delta":"B"}]}}}',
      );

      expect(parser.extractAssistantDelta(deltaFrame), '你好');
      expect(parser.extractAssistantDelta(textFrame), '世界');
      expect(parser.extractAssistantDelta(contentFrame), 'AB');
    });

    test('maps error response into gateway failure details', () {
      const parser = GatewayProtocolParser();
      final errorFrame = parser.parse(
        '{"type":"res","ok":false,"id":"auth-1","error":{"message":"missing scope: operator.write","details":{"code":"MISSING_SCOPE","reason":"missing scope: operator.write"}}}',
      );

      final failure = parser.extractFailure(errorFrame);

      expect(failure, isNotNull);
      expect(failure?.type, GatewayFailureType.missingWriteScope);
      expect(failure?.code, 'MISSING_SCOPE');
      expect(failure?.reason, 'missing scope: operator.write');
    });
  });
}
