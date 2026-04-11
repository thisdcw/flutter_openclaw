class GatewayConfig {
  final String gatewayUrl;
  final String authToken;
  final String sessionId;
  final int timeoutMs;
  final String locale;

  const GatewayConfig({
    required this.gatewayUrl,
    required this.authToken,
    required this.sessionId,
    required this.timeoutMs,
    required this.locale,
  });

  GatewayConfig copyWith({
    String? gatewayUrl,
    String? authToken,
    String? sessionId,
    int? timeoutMs,
    String? locale,
  }) {
    return GatewayConfig(
      gatewayUrl: gatewayUrl ?? this.gatewayUrl,
      authToken: authToken ?? this.authToken,
      sessionId: sessionId ?? this.sessionId,
      timeoutMs: timeoutMs ?? this.timeoutMs,
      locale: locale ?? this.locale,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gatewayUrl': gatewayUrl,
      'authToken': authToken,
      'sessionId': sessionId,
      'timeoutMs': timeoutMs,
      'locale': locale,
    };
  }

  factory GatewayConfig.fromJson(Map<String, dynamic> json) {
    return GatewayConfig(
      gatewayUrl: _string(json, 'gatewayUrl'),
      authToken: _string(json, 'authToken'),
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
        other.authToken == authToken &&
        other.sessionId == sessionId &&
        other.timeoutMs == timeoutMs &&
        other.locale == locale;
  }

  @override
  int get hashCode => Object.hash(
        gatewayUrl,
        authToken,
        sessionId,
        timeoutMs,
        locale,
      );

  @override
  String toString() {
    return 'GatewayConfig(gatewayUrl: $gatewayUrl, authToken: <redacted>, '
        'sessionId: $sessionId, timeoutMs: $timeoutMs, locale: $locale)';
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
