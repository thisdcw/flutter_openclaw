import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_openclaw/src/infrastructure/util/bootstrap_payload_parser.dart';

void main() {
  test('parses bootstrap token from payload with gatewayUrl', () {
    const token = 'boot-token-123';
    const payload = <String, Object?>{
      'gatewayUrl': 'wss://example.invalid/gateway',
      'bootstrapToken': token,
    };
    final encoded = base64Url.encode(utf8.encode(jsonEncode(payload)));

    final parser = BootstrapPayloadParser();
    final result = parser.parse(encoded);

    expect(result.bootstrapToken, token);
  });
}
