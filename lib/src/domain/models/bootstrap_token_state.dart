class BootstrapTokenState {
  final String token;
  final String gatewayUrl;
  final int importedAt;
  final int expiresAt;

  const BootstrapTokenState({
    required this.token,
    required this.gatewayUrl,
    required this.importedAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;

  Map<String, dynamic> toJson() => {
        'token': token,
        'gatewayUrl': gatewayUrl,
        'importedAt': importedAt,
        'expiresAt': expiresAt,
      };

  factory BootstrapTokenState.fromJson(Map<String, dynamic> json) {
    return BootstrapTokenState(
      token: _string(json, 'token'),
      gatewayUrl: _string(json, 'gatewayUrl'),
      importedAt: _int(json, 'importedAt'),
      expiresAt: _int(json, 'expiresAt'),
    );
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('BootstrapTokenState: "$key" must be a string.');
  }

  static int _int(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw FormatException('BootstrapTokenState: "$key" must be an int.');
  }
}
