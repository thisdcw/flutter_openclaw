class ConnectParams {
  final int minProtocol;
  final int maxProtocol;
  final String role;
  final List<String> scopes;
  final ConnectClientInfo client;
  final String locale;
  final String userAgent;
  final List<String> caps;
  final List<String> commands;
  final Map<String, Object?> permissions;
  final ConnectDeviceProof device;
  final ConnectAuth auth;

  const ConnectParams({
    required this.minProtocol,
    required this.maxProtocol,
    required this.role,
    required this.scopes,
    required this.client,
    required this.locale,
    required this.userAgent,
    required this.caps,
    required this.commands,
    required this.permissions,
    required this.device,
    required this.auth,
  });

  Map<String, dynamic> get payload => toJson();

  Map<String, dynamic> toJson() {
    return {
      'minProtocol': minProtocol,
      'maxProtocol': maxProtocol,
      'role': role,
      'scopes': List<String>.from(scopes),
      'client': client.toJson(),
      'locale': locale,
      'userAgent': userAgent,
      'caps': List<String>.from(caps),
      'commands': List<String>.from(commands),
      'permissions': Map<String, Object?>.from(permissions),
      'device': device.toJson(),
      'auth': auth.toJson(),
    };
  }

  factory ConnectParams.fromJson(Map<String, dynamic> json) {
    return ConnectParams(
      minProtocol: _int(json, 'minProtocol'),
      maxProtocol: _int(json, 'maxProtocol'),
      role: _string(json, 'role'),
      scopes: _stringList(json, 'scopes'),
      client: ConnectClientInfo.fromJson(_object(json, 'client')),
      locale: _string(json, 'locale'),
      userAgent: _string(json, 'userAgent'),
      caps: _stringList(json, 'caps'),
      commands: _stringList(json, 'commands'),
      permissions: _permissions(json, 'permissions'),
      device: ConnectDeviceProof.fromJson(_object(json, 'device')),
      auth: ConnectAuth.fromJson(_object(json, 'auth')),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectParams &&
        other.minProtocol == minProtocol &&
        other.maxProtocol == maxProtocol &&
        other.role == role &&
        _listEquals(other.scopes, scopes) &&
        other.client == client &&
        other.locale == locale &&
        other.userAgent == userAgent &&
        _listEquals(other.caps, caps) &&
        _listEquals(other.commands, commands) &&
        _mapEquals(other.permissions, permissions) &&
        other.device == device &&
        other.auth == auth;
  }

  @override
  int get hashCode => Object.hash(
        minProtocol,
        maxProtocol,
        role,
        Object.hashAll(scopes),
        client,
        locale,
        userAgent,
        Object.hashAll(caps),
        Object.hashAll(commands),
        _mapHash(permissions),
        device,
        auth,
      );

  @override
  String toString() {
    return 'ConnectParams(minProtocol: $minProtocol, maxProtocol: '
        '$maxProtocol, role: $role, scopes: $scopes, client: $client, '
        'locale: $locale, userAgent: $userAgent, caps: $caps, commands: '
        '$commands, permissions: $permissions, device: $device, auth: $auth)';
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw FormatException('ConnectParams: "$key" must be a string.');
  }

  static int _int(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw FormatException('ConnectParams: "$key" must be an integer.');
  }

  static Map<String, dynamic> _object(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw FormatException('ConnectParams: "$key" must be an object.');
  }

  static List<String> _stringList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is Iterable) {
      return value.map((entry) {
        if (entry is String) {
          return entry;
        }
        throw FormatException(
          'ConnectParams: "$key" must be a list of strings.',
        );
      }).toList(growable: false);
    }
    throw FormatException('ConnectParams: "$key" must be a list.');
  }

  static Map<String, Object?> _permissions(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is Map) {
      return Map<String, Object?>.from(value);
    }
    throw FormatException('ConnectParams: "$key" must be an object.');
  }

  static bool _listEquals(List<Object?> a, List<Object?> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
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

  static int _mapHash(Map<String, Object?> value) {
    return Object.hashAll(
      value.entries.map((entry) => Object.hash(entry.key, entry.value)),
    );
  }
}

class ConnectClientInfo {
  final String id;
  final String version;
  final String platform;
  final String deviceFamily;
  final String mode;
  final String instanceId;

  const ConnectClientInfo({
    required this.id,
    required this.version,
    required this.platform,
    required this.deviceFamily,
    required this.mode,
    required this.instanceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'platform': platform,
      'deviceFamily': deviceFamily,
      'mode': mode,
      'instanceId': instanceId,
    };
  }

  factory ConnectClientInfo.fromJson(Map<String, dynamic> json) {
    return ConnectClientInfo(
      id: ConnectParams._string(json, 'id'),
      version: ConnectParams._string(json, 'version'),
      platform: ConnectParams._string(json, 'platform'),
      deviceFamily: ConnectParams._string(json, 'deviceFamily'),
      mode: ConnectParams._string(json, 'mode'),
      instanceId: ConnectParams._string(json, 'instanceId'),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectClientInfo &&
        other.id == id &&
        other.version == version &&
        other.platform == platform &&
        other.deviceFamily == deviceFamily &&
        other.mode == mode &&
        other.instanceId == instanceId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        version,
        platform,
        deviceFamily,
        mode,
        instanceId,
      );

  @override
  String toString() {
    return 'ConnectClientInfo(id: $id, version: $version, platform: '
        '$platform, deviceFamily: $deviceFamily, mode: $mode, instanceId: '
        '$instanceId)';
  }
}

class ConnectDeviceProof {
  final String id;
  final String publicKey;
  final String signature;
  final int signedAt;
  final String nonce;

  const ConnectDeviceProof({
    required this.id,
    required this.publicKey,
    required this.signature,
    required this.signedAt,
    required this.nonce,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'publicKey': publicKey,
      'signature': signature,
      'signedAt': signedAt,
      'nonce': nonce,
    };
  }

  factory ConnectDeviceProof.fromJson(Map<String, dynamic> json) {
    return ConnectDeviceProof(
      id: ConnectParams._string(json, 'id'),
      publicKey: ConnectParams._string(json, 'publicKey'),
      signature: ConnectParams._string(json, 'signature'),
      signedAt: ConnectParams._int(json, 'signedAt'),
      nonce: ConnectParams._string(json, 'nonce'),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectDeviceProof &&
        other.id == id &&
        other.publicKey == publicKey &&
        other.signature == signature &&
        other.signedAt == signedAt &&
        other.nonce == nonce;
  }

  @override
  int get hashCode => Object.hash(id, publicKey, signature, signedAt, nonce);

  @override
  String toString() {
    return 'ConnectDeviceProof(id: $id, publicKey: $publicKey, signature: '
        '<redacted>, signedAt: $signedAt, nonce: $nonce)';
  }
}

class ConnectAuth {
  final String? token;
  final String? deviceToken;

  const ConnectAuth({
    this.token,
    this.deviceToken,
  });

  bool get usesDeviceToken =>
      deviceToken != null && deviceToken!.trim().isNotEmpty;

  Object? operator [](String key) => toJson()[key];

  Map<String, dynamic> toJson() {
    if (usesDeviceToken) {
      return {'deviceToken': deviceToken};
    }
    if (token != null && token!.trim().isNotEmpty) {
      return {'token': token};
    }
    return <String, dynamic>{};
  }

  factory ConnectAuth.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    final deviceToken = json['deviceToken'];

    if (token != null && token is! String) {
      throw FormatException('ConnectAuth: "token" must be a string.');
    }
    if (deviceToken != null && deviceToken is! String) {
      throw FormatException('ConnectAuth: "deviceToken" must be a string.');
    }

    return ConnectAuth(
      token: token as String?,
      deviceToken: deviceToken as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectAuth &&
        other.token == token &&
        other.deviceToken == deviceToken;
  }

  @override
  int get hashCode => Object.hash(token, deviceToken);

  @override
  String toString() {
    return 'ConnectAuth(token: ${token == null ? null : '<redacted>'}, '
        'deviceToken: ${deviceToken == null ? null : '<redacted>'})';
  }
}
