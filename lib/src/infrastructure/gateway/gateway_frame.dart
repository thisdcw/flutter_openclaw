class GatewayFrame {
  final String type;
  final String? id;
  final bool? ok;
  final String? event;
  final Map<String, dynamic> payload;
  final Map<String, dynamic>? error;
  final Map<String, dynamic> raw;

  const GatewayFrame({
    required this.type,
    required this.id,
    required this.ok,
    required this.event,
    required this.payload,
    required this.error,
    required this.raw,
  });

  String? get payloadType {
    final value = payload['type'];
    return value is String ? value : null;
  }

  bool get isConnectChallenge => type == 'event' && event == 'connect.challenge';

  bool get isHelloOk => type == 'res' && payloadType == 'hello-ok';

  bool get isErrorResponse => type == 'res' && ok == false;

  Map<String, dynamic> toJson() {
    return Map<String, dynamic>.from(raw);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GatewayFrame &&
        other.type == type &&
        other.id == id &&
        other.ok == ok &&
        other.event == event &&
        _mapEquals(other.payload, payload) &&
        _nullableMapEquals(other.error, error) &&
        _mapEquals(other.raw, raw);
  }

  @override
  int get hashCode => Object.hash(
        type,
        id,
        ok,
        event,
        _mapHash(payload),
        error == null ? null : _mapHash(error!),
        _mapHash(raw),
      );

  @override
  String toString() {
    return 'GatewayFrame(type: $type, id: $id, ok: $ok, event: $event, '
        'payloadType: $payloadType, error: $error)';
  }

  static bool _nullableMapEquals(
    Map<String, dynamic>? a,
    Map<String, dynamic>? b,
  ) {
    if (a == null || b == null) {
      return a == null && b == null;
    }
    return _mapEquals(a, b);
  }

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  static int _mapHash(Map<String, dynamic> value) {
    return Object.hashAll(
      value.entries.map((entry) => Object.hash(entry.key, entry.value)),
    );
  }
}
