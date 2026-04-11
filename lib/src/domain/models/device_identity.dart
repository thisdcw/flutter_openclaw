class DeviceIdentity {
  final String id;
  final String publicKey;
  final String privateKeyPem;

  const DeviceIdentity({
    required this.id,
    required this.publicKey,
    required this.privateKeyPem,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'publicKey': publicKey,
      'privateKeyPem': privateKeyPem,
    };
  }

  factory DeviceIdentity.fromJson(Map<String, dynamic> json) {
    return DeviceIdentity(
      id: _string(json, 'id'),
      publicKey: _string(json, 'publicKey'),
      privateKeyPem: _string(json, 'privateKeyPem'),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceIdentity &&
        other.id == id &&
        other.publicKey == publicKey &&
        other.privateKeyPem == privateKeyPem;
  }

  @override
  int get hashCode => Object.hash(id, publicKey, privateKeyPem);

  @override
  String toString() {
    return 'DeviceIdentity(id: $id, publicKey: $publicKey, '
        'privateKeyPem: <redacted>)';
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw FormatException('DeviceIdentity: "$key" must be a string.');
  }
}
