import 'dart:convert';

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
}
