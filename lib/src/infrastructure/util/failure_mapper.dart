String mapGatewayFailure({
  required String code,
  required String reason,
}) {
  final normalizedReason = reason.toLowerCase();
  final normalizedCode = code.toLowerCase();

  if (reason.contains('operator.write')) {
    return '当前设备缺少 operator.write 授权，请先完成配对或刷新授权。';
  }
  if (normalizedReason.contains('pairing') ||
      normalizedReason.contains('no pair') ||
      normalizedReason.contains('not-paired') ||
      normalizedReason.contains('not paired') ||
      normalizedCode.contains('pairing')) {
    return '当前设备尚未完成配对授权。';
  }
  if (normalizedReason.contains('timeout') ||
      normalizedCode.contains('timeout')) {
    return '请求超时，请检查 Gateway 状态后重试。';
  }
  if (normalizedReason.contains('disconnect') ||
      normalizedCode.contains('disconnect')) {
    return 'Gateway 连接已断开，请重新连接后再试。';
  }
  return 'Gateway 错误: $code | $reason';
}
