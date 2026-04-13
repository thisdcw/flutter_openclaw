class DeviceIdentity {
  final String id;
  final String publicKey;

  const DeviceIdentity({
    required this.id,
    required this.publicKey,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'publicKey': publicKey,
      };

  factory DeviceIdentity.fromJson(Map<String, dynamic> json) {
    return DeviceIdentity(
      id: _string(json, 'id'),
      publicKey: _string(json, 'publicKey'),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceIdentity &&
        other.id == id &&
        other.publicKey == publicKey;
  }

  @override
  int get hashCode => Object.hash(id, publicKey);

  @override
  String toString() => 'DeviceIdentity(id: $id, publicKey: $publicKey)';

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('DeviceIdentity: "$key" must be a string.');
  }
}
