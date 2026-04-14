import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_openclaw/src/infrastructure/util/bootstrap_payload_parser.dart';

void main() {
  test('parses url and bootstrap token from setup code payload', () {
    const token = 'boot-token-123';
    const payload = <String, Object?>{
      'url': 'wss://thisdcw.cn',
      'bootstrapToken': token,
    };
    final encoded = base64Url.encode(utf8.encode(jsonEncode(payload)));

    final parser = BootstrapPayloadParser();
    final result = parser.parse(encoded);

    expect(result.gatewayUrl, 'wss://thisdcw.cn');
    expect(result.bootstrapToken, token);
  });
}
