class ConnectChallenge {
  final String nonce;

  const ConnectChallenge({required this.nonce});

  Map<String, dynamic> toJson() {
    return {
      'nonce': nonce,
    };
  }

  factory ConnectChallenge.fromJson(Map<String, dynamic> json) {
    return ConnectChallenge(
      nonce: _string(json, 'nonce'),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectChallenge && other.nonce == nonce;
  }

  @override
  int get hashCode => nonce.hashCode;

  @override
  String toString() => 'ConnectChallenge(nonce: $nonce)';

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw FormatException('ConnectChallenge: "$key" must be a string.');
  }
}
