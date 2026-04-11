class OperatorAuthState {
  final String role;
  final String deviceToken;
  final List<String> scopes;

  const OperatorAuthState({
    required this.role,
    required this.deviceToken,
    required this.scopes,
  });

  bool get hasWriteScope =>
      scopes.any((scope) => scope.toLowerCase() == 'operator.write');

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'deviceToken': deviceToken,
      'scopes': List<String>.from(scopes),
    };
  }

  factory OperatorAuthState.fromJson(Map<String, dynamic> json) {
    return OperatorAuthState(
      role: _string(json, 'role'),
      deviceToken: _string(json, 'deviceToken'),
      scopes: _stringList(json, 'scopes'),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OperatorAuthState &&
        other.role == role &&
        other.deviceToken == deviceToken &&
        _listEquals(other.scopes, scopes);
  }

  @override
  int get hashCode => Object.hash(role, deviceToken, Object.hashAll(scopes));

  @override
  String toString() {
    return 'OperatorAuthState(role: $role, deviceToken: <redacted>, '
        'scopes: $scopes, hasWriteScope: $hasWriteScope)';
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw FormatException('OperatorAuthState: "$key" must be a string.');
  }

  static List<String> _stringList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is Iterable) {
      return value.map((entry) {
        if (entry is String) {
          return entry;
        }
        throw FormatException(
          'OperatorAuthState: "$key" must be a list of strings.',
        );
      }).toList(growable: false);
    }
    throw FormatException('OperatorAuthState: "$key" must be a list.');
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
