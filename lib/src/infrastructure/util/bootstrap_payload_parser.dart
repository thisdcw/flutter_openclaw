import 'dart:convert';

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
      final decoded = utf8.decode(base64.decode(trimmed));
      final json = jsonDecode(decoded);
      if (json is! Map) {
        throw const FormatException('payload must be an object');
      }
      final map = Map<String, dynamic>.from(json);
      final url = map['url'];
      final token = map['bootstrapToken'];
      if (url is! String || token is! String) {
        throw const FormatException('missing url or bootstrapToken');
      }
      return BootstrapPayload(gatewayUrl: url, bootstrapToken: token);
    } catch (_) {
      return BootstrapPayload(gatewayUrl: '', bootstrapToken: trimmed);
    }
  }
}
