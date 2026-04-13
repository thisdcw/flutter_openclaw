class GatewayConfig {
  final String gatewayUrl;
  final String sessionId;
  final int timeoutMs;
  final String locale;

  const GatewayConfig({
    required this.gatewayUrl,
    required this.sessionId,
    required this.timeoutMs,
    required this.locale,
  });

  GatewayConfig copyWith({
    String? gatewayUrl,
    String? sessionId,
    int? timeoutMs,
    String? locale,
  }) {
    return GatewayConfig(
      gatewayUrl: gatewayUrl ?? this.gatewayUrl,
      sessionId: sessionId ?? this.sessionId,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      locale: locale ?? this.locale,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gatewayUrl': gatewayUrl,
      'sessionId': sessionId,
      'timeoutMs': timeoutMs,
      'locale': locale,
    };
  }

  factory GatewayConfig.fromJson(Map<String, dynamic> json) {
    return GatewayConfig(
      gatewayUrl: _string(json, 'gatewayUrl'),
      sessionId: _string(json, 'sessionId'),
      timeoutMs: _int(json, 'timeoutMs'),
      locale: _string(json, 'locale'),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GatewayConfig &&
        other.gatewayUrl == gatewayUrl &&
        other.sessionId == sessionId &&
        other.timeoutMs == timeoutMs &&
        other.locale == locale;
  }

  @override
  int get hashCode => Object.hash(
        gatewayUrl,
        sessionId,
        timeoutMs,
        locale,
      );

  @override
  String toString() {
    return 'GatewayConfig(gatewayUrl: $gatewayUrl, sessionId: $sessionId, '
        'timeoutMs: $timeoutMs, locale: $locale)';
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw FormatException('GatewayConfig: "$key" must be a string.');
  }

  static int _int(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw FormatException('GatewayConfig: "$key" must be an integer.');
  }
}
