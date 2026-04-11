enum GatewayFailureType {
  pairingRequired,
  missingWriteScope,
  timeout,
  disconnect,
  authFailed,
  protocolError,
  unknown;

  String get value => switch (this) {
        GatewayFailureType.pairingRequired => 'pairingRequired',
        GatewayFailureType.missingWriteScope => 'missingWriteScope',
        GatewayFailureType.timeout => 'timeout',
        GatewayFailureType.disconnect => 'disconnect',
        GatewayFailureType.authFailed => 'authFailed',
        GatewayFailureType.protocolError => 'protocolError',
        GatewayFailureType.unknown => 'unknown',
      };

  static GatewayFailureType fromValue(String value) {
    for (final candidate in GatewayFailureType.values) {
      if (candidate.value == value) {
        return candidate;
      }
    }
    throw FormatException(
      'GatewayFailureType: unsupported value "$value".',
    );
  }
}

class GatewayFailure {
  final GatewayFailureType type;
  final String code;
  final String reason;
  final String message;
  final Map<String, Object?> details;

  const GatewayFailure({
    required this.type,
    required this.code,
    required this.reason,
    required this.message,
    this.details = const <String, Object?>{},
  });

  factory GatewayFailure.fromCode({
    required String code,
    required String reason,
    String? message,
    Map<String, Object?> details = const <String, Object?>{},
  }) {
    return GatewayFailure(
      type: _inferType(code: code, reason: reason),
      code: code,
      reason: reason,
      message: message ?? reason,
      details: details,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'code': code,
      'reason': reason,
      'message': message,
      'details': Map<String, Object?>.from(details),
    };
  }

  factory GatewayFailure.fromJson(Map<String, dynamic> json) {
    return GatewayFailure(
      type: GatewayFailureType.fromValue(_string(json, 'type')),
      code: _string(json, 'code'),
      reason: _string(json, 'reason'),
      message: _string(json, 'message'),
      details: _details(json, 'details'),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GatewayFailure &&
        other.type == type &&
        other.code == code &&
        other.reason == reason &&
        other.message == message &&
        _mapEquals(other.details, details);
  }

  @override
  int get hashCode => Object.hash(
        type,
        code,
        reason,
        message,
        Object.hashAll(
          details.entries.map((entry) => Object.hash(entry.key, entry.value)),
        ),
      );

  @override
  String toString() {
    return 'GatewayFailure(type: ${type.value}, code: $code, reason: '
        '$reason, message: $message, details: $details)';
  }

  static GatewayFailureType _inferType({
    required String code,
    required String reason,
  }) {
    final normalizedCode = code.toLowerCase();
    final normalizedReason = reason.toLowerCase();

    if (normalizedReason.contains('operator.write') ||
        normalizedCode.contains('missing_scope')) {
      return GatewayFailureType.missingWriteScope;
    }

    if (normalizedReason.contains('pairing') ||
        normalizedCode.contains('pairing')) {
      return GatewayFailureType.pairingRequired;
    }

    if (normalizedReason.contains('timeout') ||
        normalizedCode.contains('timeout')) {
      return GatewayFailureType.timeout;
    }

    if (normalizedReason.contains('disconnect') ||
        normalizedCode.contains('disconnect')) {
      return GatewayFailureType.disconnect;
    }

    if (normalizedCode.contains('auth') ||
        normalizedReason.contains('device token') ||
        normalizedReason.contains('authentication')) {
      return GatewayFailureType.authFailed;
    }

    if (normalizedCode.contains('protocol') ||
        normalizedReason.contains('handshake') ||
        normalizedReason.contains('invalid frame')) {
      return GatewayFailureType.protocolError;
    }

    return GatewayFailureType.unknown;
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw FormatException('GatewayFailure: "$key" must be a string.');
  }

  static Map<String, Object?> _details(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is Map) {
      return Map<String, Object?>.from(value);
    }
    throw FormatException('GatewayFailure: "$key" must be an object.');
  }

  static bool _mapEquals(Map<String, Object?> a, Map<String, Object?> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}
