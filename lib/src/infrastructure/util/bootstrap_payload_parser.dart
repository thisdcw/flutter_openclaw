import 'dart:convert';

import 'openclaw_logger.dart';

class BootstrapPayload {
  final String gatewayUrl;
  final String bootstrapToken;

  const BootstrapPayload({
    required this.gatewayUrl,
    required this.bootstrapToken,
  });
}

class BootstrapPayloadParser {
  BootstrapPayload parse(String input) {
    final trimmed = input.trim();
    try {
      final decoded = utf8.decode(base64.decode(_normalizeBase64(trimmed)));
      final json = jsonDecode(decoded);
      if (json is! Map) {
        throw const FormatException('payload must be an object');
      }
      final map = Map<String, dynamic>.from(json);
      final url = map['url'] ?? map['gatewayUrl'];
      final token = map['bootstrapToken'];
      if (url is! String || token is! String) {
        throw const FormatException('missing url or bootstrapToken');
      }
      return BootstrapPayload(
        gatewayUrl: url.trim(),
        bootstrapToken: token.trim(),
      );
    } catch (error) {
      openClawLog(
        'BootstrapPayloadParser',
        'fallback to raw bootstrap token after parse failure',
        fields: <String, Object?>{
          'error': error.toString(),
          'preview': '<redacted>',
        },
      );
      return BootstrapPayload(gatewayUrl: '', bootstrapToken: trimmed);
    }
  }

  String _normalizeBase64(String input) {
    final normalizedAlphabet =
        input.replaceAll('-', '+').replaceAll('_', '/');
    return base64.normalize(normalizedAlphabet);
  }
}
