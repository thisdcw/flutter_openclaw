class CanvasCapabilitySnapshot {
  const CanvasCapabilitySnapshot({
    this.canvasHostUrl,
    this.canvasCapability,
    this.canvasCapabilityExpiresAtMs,
    this.source = 'none',
    this.reason,
  });

  const CanvasCapabilitySnapshot.unavailable({
    this.source = 'none',
    this.reason,
  })  : canvasHostUrl = null,
        canvasCapability = null,
        canvasCapabilityExpiresAtMs = null;

  final String? canvasHostUrl;
  final String? canvasCapability;
  final int? canvasCapabilityExpiresAtMs;
  final String source;
  final String? reason;

  bool get isAvailable {
    final value = canvasHostUrl?.trim() ?? '';
    return value.isNotEmpty;
  }

  CanvasCapabilitySnapshot copyWith({
    String? canvasHostUrl,
    String? canvasCapability,
    int? canvasCapabilityExpiresAtMs,
    String? source,
    String? reason,
    bool clearReason = false,
  }) {
    return CanvasCapabilitySnapshot(
      canvasHostUrl: canvasHostUrl ?? this.canvasHostUrl,
      canvasCapability: canvasCapability ?? this.canvasCapability,
      canvasCapabilityExpiresAtMs:
          canvasCapabilityExpiresAtMs ?? this.canvasCapabilityExpiresAtMs,
      source: source ?? this.source,
      reason: clearReason ? null : reason ?? this.reason,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'canvasHostUrl': canvasHostUrl,
      'canvasCapability': canvasCapability,
      'canvasCapabilityExpiresAtMs': canvasCapabilityExpiresAtMs,
      'source': source,
      'reason': reason,
    };
  }

  factory CanvasCapabilitySnapshot.fromJson(Map<String, dynamic> json) {
    return CanvasCapabilitySnapshot(
      canvasHostUrl: _nullableString(json['canvasHostUrl'], 'canvasHostUrl'),
      canvasCapability:
          _nullableString(json['canvasCapability'], 'canvasCapability'),
      canvasCapabilityExpiresAtMs: _nullableInt(
        json['canvasCapabilityExpiresAtMs'],
        'canvasCapabilityExpiresAtMs',
      ),
      source: _nullableString(json['source'], 'source') ?? 'none',
      reason: _nullableString(json['reason'], 'reason'),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CanvasCapabilitySnapshot &&
        other.canvasHostUrl == canvasHostUrl &&
        other.canvasCapability == canvasCapability &&
        other.canvasCapabilityExpiresAtMs == canvasCapabilityExpiresAtMs &&
        other.source == source &&
        other.reason == reason;
  }

  @override
  int get hashCode => Object.hash(
        canvasHostUrl,
        canvasCapability,
        canvasCapabilityExpiresAtMs,
        source,
        reason,
      );

  @override
  String toString() {
    return 'CanvasCapabilitySnapshot(canvasHostUrl: $canvasHostUrl, '
        'canvasCapability: $canvasCapability, '
        'canvasCapabilityExpiresAtMs: $canvasCapabilityExpiresAtMs, '
        'source: $source, reason: $reason)';
  }

  static String? _nullableString(Object? value, String key) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    throw FormatException(
      'CanvasCapabilitySnapshot: "$key" must be a string.',
    );
  }

  static int? _nullableInt(Object? value, String key) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    throw FormatException(
      'CanvasCapabilitySnapshot: "$key" must be an int.',
    );
  }
}
