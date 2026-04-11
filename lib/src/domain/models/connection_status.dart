import 'gateway_failure.dart';

enum ConnectionPhase {
  idle,
  connecting,
  waitingChallenge,
  authenticating,
  ready,
  reconnecting,
  failed;

  String get value => name;

  static ConnectionPhase fromValue(String value) {
    for (final phase in ConnectionPhase.values) {
      if (phase.value == value) {
        return phase;
      }
    }
    throw FormatException('ConnectionPhase: unsupported value "$value".');
  }
}

class ConnectionStatus {
  final ConnectionPhase phase;
  final List<String> grantedScopes;
  final String? deviceId;
  final GatewayFailure? failure;

  const ConnectionStatus({
    required this.phase,
    this.grantedScopes = const <String>[],
    this.deviceId,
    this.failure,
  });

  bool get isReady => phase == ConnectionPhase.ready;

  bool get canSend =>
      isReady &&
      grantedScopes.any(
        (scope) => scope.toLowerCase() == 'operator.write',
      );

  String get sendBlockedReason {
    if (!isReady) {
      return 'connection not ready';
    }
    if (!canSend) {
      return 'missing scope: operator.write';
    }
    return '';
  }

  ConnectionStatus copyWith({
    ConnectionPhase? phase,
    List<String>? grantedScopes,
    String? deviceId,
    GatewayFailure? failure,
    bool clearFailure = false,
  }) {
    return ConnectionStatus(
      phase: phase ?? this.phase,
      grantedScopes: grantedScopes ?? this.grantedScopes,
      deviceId: deviceId ?? this.deviceId,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phase': phase.value,
      'grantedScopes': List<String>.from(grantedScopes),
      'deviceId': deviceId,
      'failure': failure?.toJson(),
    };
  }

  factory ConnectionStatus.fromJson(Map<String, dynamic> json) {
    final rawFailure = json['failure'];
    return ConnectionStatus(
      phase: ConnectionPhase.fromValue(_string(json, 'phase')),
      grantedScopes: _stringList(json, 'grantedScopes'),
      deviceId: _nullableString(json['deviceId'], 'deviceId'),
      failure: rawFailure == null
          ? null
          : GatewayFailure.fromJson(_objectValue(rawFailure, 'failure')),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectionStatus &&
        other.phase == phase &&
        _listEquals(other.grantedScopes, grantedScopes) &&
        other.deviceId == deviceId &&
        other.failure == failure;
  }

  @override
  int get hashCode => Object.hash(
        phase,
        Object.hashAll(grantedScopes),
        deviceId,
        failure,
      );

  @override
  String toString() {
    return 'ConnectionStatus(phase: ${phase.value}, grantedScopes: '
        '$grantedScopes, deviceId: $deviceId, failure: $failure, canSend: '
        '$canSend)';
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw FormatException('ConnectionStatus: "$key" must be a string.');
  }

  static String? _nullableString(Object? value, String key) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    throw FormatException('ConnectionStatus: "$key" must be a string.');
  }

  static Map<String, dynamic> _objectValue(Object? value, String key) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw FormatException('ConnectionStatus: "$key" must be an object.');
  }

  static List<String> _stringList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is Iterable) {
      return value.map((entry) {
        if (entry is String) {
          return entry;
        }
        throw FormatException(
          'ConnectionStatus: "$key" must be a list of strings.',
        );
      }).toList(growable: false);
    }
    throw FormatException('ConnectionStatus: "$key" must be a list.');
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}
