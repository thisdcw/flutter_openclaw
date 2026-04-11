import 'package:flutter/foundation.dart';

void openClawLog(
  String scope,
  String message, {
  Map<String, Object?> fields = const <String, Object?>{},
}) {
  final timestamp = DateTime.now().toIso8601String();
  final details = fields.isEmpty
      ? ''
      : fields.entries
          .map((entry) => '${entry.key}=${_stringify(entry.value)}')
          .join(' | ');
  final suffix = details.isEmpty ? '' : ' | $details';
  debugPrint('[$timestamp][OpenClaw][$scope] $message$suffix');
}

String redactValue(
  String value, {
  int prefix = 4,
  int suffix = 4,
}) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return '(empty)';
  }
  if (normalized.length <= prefix + suffix) {
    return '*' * normalized.length;
  }
  return '${normalized.substring(0, prefix)}***${normalized.substring(normalized.length - suffix)}';
}

String truncateForLog(String value, {int maxLength = 120}) {
  if (value.length <= maxLength) {
    return value;
  }
  return '${value.substring(0, maxLength)}...';
}

String _stringify(Object? value) {
  if (value == null) {
    return 'null';
  }
  return value.toString();
}
