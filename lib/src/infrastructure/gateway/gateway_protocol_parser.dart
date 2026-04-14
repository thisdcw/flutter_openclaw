import 'dart:convert';

import '../../domain/models/canvas_capability_snapshot.dart';
import '../../domain/models/connect_challenge.dart';
import '../../domain/models/gateway_failure.dart';
import '../../domain/models/operator_auth_state.dart';
import 'gateway_frame.dart';

class GatewayProtocolParser {
  const GatewayProtocolParser();

  GatewayFrame parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw FormatException('GatewayProtocolParser: frame must be an object.');
    }

    final json = Map<String, dynamic>.from(decoded);
    final payload =
        _optionalObject(json['payload'], 'payload') ?? const <String, dynamic>{};
    final error = _optionalObject(json['error'], 'error');

    return GatewayFrame(
      type: _requiredString(json, 'type'),
      id: _optionalString(json['id'], 'id'),
      ok: _optionalBool(json['ok'], 'ok'),
      event: _optionalString(json['event'], 'event'),
      payload: payload,
      error: error,
      raw: json,
    );
  }

  ConnectChallenge extractChallenge(GatewayFrame frame) {
    if (!frame.isConnectChallenge) {
      throw FormatException(
        'GatewayProtocolParser: frame is not a connect.challenge event.',
      );
    }

    return ConnectChallenge.fromJson(frame.payload);
  }

  OperatorAuthState? extractHelloOkAuth(GatewayFrame frame) {
    if (!frame.isHelloOk) {
      return null;
    }

    final rawAuth = frame.payload['auth'];
    if (rawAuth == null) {
      return const OperatorAuthState(
        role: 'operator',
        deviceToken: '',
        scopes: <String>[],
      );
    }

    final auth = _objectValue(rawAuth, 'payload.auth');
    return OperatorAuthState(
      role: _optionalString(auth['role'], 'payload.auth.role') ?? 'operator',
      deviceToken:
          _optionalString(auth['deviceToken'], 'payload.auth.deviceToken') ?? '',
      scopes: _optionalStringList(auth['scopes'], 'payload.auth.scopes') ??
          const <String>[],
    );
  }

  GatewayFailure? extractFailure(GatewayFrame frame) {
    final error = frame.error;
    if (error == null) {
      return null;
    }

    final details = _optionalObject(error['details'], 'error.details');
    final code =
        _optionalString(details?['code'], 'error.details.code') ??
        _optionalString(error['code'], 'error.code') ??
        'UNKNOWN';
    final reason =
        _optionalString(details?['reason'], 'error.details.reason') ??
        _optionalString(error['message'], 'error.message') ??
        'unknown';

    return GatewayFailure.fromCode(
      code: code,
      reason: reason,
      details: details == null
          ? const <String, Object?>{}
          : Map<String, Object?>.from(details),
    );
  }

  CanvasCapabilitySnapshot extractCanvasCapability(
    GatewayFrame frame, {
    required String source,
  }) {
    final candidates = _canvasCapabilityCandidates(frame.payload);
    String? hostUrl;
    String? capability;
    int? expiresAtMs;
    for (final candidate in candidates) {
      hostUrl ??= _extractCanvasHostUrl(candidate);
      capability ??= _extractCanvasCapability(candidate);
      expiresAtMs ??= _extractCanvasExpiresAtMs(candidate);
    }
    if (hostUrl == null) {
      return CanvasCapabilitySnapshot.unavailable(
        source: source,
        reason: 'canvasHostUrl missing',
      );
    }
    return CanvasCapabilitySnapshot(
      canvasHostUrl: hostUrl,
      canvasCapability: capability,
      canvasCapabilityExpiresAtMs: expiresAtMs,
      source: source,
    );
  }

  bool looksLikePseudoCanvasDirective(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final hasDirectiveKeywords = normalized.contains('"action"') &&
        (normalized.contains('"canvas"') ||
            normalized.contains('"eval"') ||
            normalized.contains('"javaScript"'));
    if (!hasDirectiveKeywords) {
      return false;
    }

    final decoded = _tryDecodeObject(normalized);
    if (decoded == null) {
      return false;
    }
    final action = _safeString(decoded['action'])?.toLowerCase();
    final javaScript = _safeString(decoded['javaScript']);
    final params = _safeObject(decoded['params']);
    final nestedAction = _safeString(params?['action'])?.toLowerCase();
    final nestedJavaScript = _safeString(params?['javaScript']);

    final actionLooksCanvas = action == 'canvas' || nestedAction == 'canvas';
    final actionLooksEval = action == 'eval' || nestedAction == 'eval';
    final hasJavaScript = (javaScript?.isNotEmpty ?? false) ||
        (nestedJavaScript?.isNotEmpty ?? false);
    return actionLooksCanvas || actionLooksEval || hasJavaScript;
  }

  String extractAssistantDelta(GatewayFrame frame) {
    final payload = frame.payload;
    final data = _optionalObject(payload['data'], 'payload.data');
    if (data == null) {
      return '';
    }

    final delta = _optionalString(data['delta'], 'payload.data.delta');
    if (delta != null) {
      return delta;
    }

    final text = _optionalString(data['text'], 'payload.data.text');
    if (text != null) {
      return text;
    }

    final content = data['content'];
    if (content == null) {
      return '';
    }

    return extractTextFromContent(content);
  }

  String extractTextFromContent(Object? content) {
    if (content is! Iterable) {
      return '';
    }

    final buffer = StringBuffer();
    for (final part in content) {
      if (part is! Map) {
        continue;
      }
      final item = Map<String, dynamic>.from(part);
      final text = item['text'];
      if (text is String) {
        buffer.write(text);
        continue;
      }
      final delta = item['delta'];
      if (delta is String) {
        buffer.write(delta);
      }
    }
    return buffer.toString();
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw FormatException(
      'GatewayProtocolParser: "$key" must be a string.',
    );
  }

  static String? _optionalString(Object? value, String label) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    throw FormatException(
      'GatewayProtocolParser: "$label" must be a string.',
    );
  }

  static bool? _optionalBool(Object? value, String label) {
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }
    throw FormatException(
      'GatewayProtocolParser: "$label" must be a bool.',
    );
  }

  static Map<String, dynamic>? _optionalObject(Object? value, String label) {
    if (value == null) {
      return null;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw FormatException(
      'GatewayProtocolParser: "$label" must be an object.',
    );
  }

  static Map<String, dynamic> _objectValue(Object? value, String label) {
    final object = _optionalObject(value, label);
    if (object == null) {
      throw FormatException(
        'GatewayProtocolParser: "$label" must be an object.',
      );
    }
    return object;
  }

  static List<String>? _optionalStringList(Object? value, String label) {
    if (value == null) {
      return null;
    }
    if (value is Iterable) {
      return value.map((entry) {
        if (entry is String) {
          return entry;
        }
        throw FormatException(
          'GatewayProtocolParser: "$label" must be a list of strings.',
        );
      }).toList(growable: false);
    }
    throw FormatException(
      'GatewayProtocolParser: "$label" must be a list.',
    );
  }

  static List<Map<String, dynamic>> _canvasCapabilityCandidates(
    Map<String, dynamic> payload,
  ) {
    final candidates = <Map<String, dynamic>>[payload];
    final data = _safeObject(payload['data']);
    if (data != null) {
      candidates.add(data);
    }
    final result = _safeObject(payload['result']);
    if (result != null) {
      candidates.add(result);
    }
    return candidates;
  }

  static String? _extractCanvasHostUrl(Map<String, dynamic> value) {
    final rootHost = _normalizeCanvasHostUrl(_safeString(value['canvasHostUrl']));
    if (rootHost != null) {
      return rootHost;
    }
    final canvas = _safeObject(value['canvas']);
    if (canvas == null) {
      return null;
    }
    return _normalizeCanvasHostUrl(
      _safeString(canvas['canvasHostUrl']) ??
          _safeString(canvas['hostUrl']) ??
          _safeString(canvas['url']),
    );
  }

  static String? _extractCanvasCapability(Map<String, dynamic> value) {
    final rootCapability = _safeString(value['canvasCapability']);
    if (rootCapability != null && rootCapability.trim().isNotEmpty) {
      return rootCapability.trim();
    }
    final canvas = _safeObject(value['canvas']);
    final nested = _safeString(canvas?['capability']);
    if (nested == null || nested.trim().isEmpty) {
      return null;
    }
    return nested.trim();
  }

  static int? _extractCanvasExpiresAtMs(Map<String, dynamic> value) {
    final rootValue = _safeInt(value['canvasCapabilityExpiresAtMs']);
    if (rootValue != null) {
      return rootValue;
    }
    final canvas = _safeObject(value['canvas']);
    return _safeInt(canvas?['expiresAtMs']);
  }

  static String? _normalizeCanvasHostUrl(String? rawValue) {
    if (rawValue == null) {
      return null;
    }
    final normalized = rawValue.trim();
    if (normalized.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      return null;
    }
    return normalized;
  }

  static Map<String, dynamic>? _tryDecodeObject(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _safeObject(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static String? _safeString(Object? value) {
    if (value is String) {
      return value;
    }
    return null;
  }

  static int? _safeInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }
}
