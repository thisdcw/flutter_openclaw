import 'package:flutter/material.dart';
import 'package:flutter_openclaw/l10n/app_localizations.dart';

import '../../application/models/app_error_notice.dart';

class LocalizedAppErrorText {
  const LocalizedAppErrorText({
    required this.message,
    required this.hint,
    required this.detailsLabel,
    required this.hideDetailsLabel,
    required this.copyErrorLabel,
    required this.copiedLabel,
  });

  final String message;
  final String hint;
  final String detailsLabel;
  final String hideDetailsLabel;
  final String copyErrorLabel;
  final String copiedLabel;
}

LocalizedAppErrorText localizeAppErrorText(
  BuildContext context,
  AppErrorNotice notice,
) {
  final l10n = AppLocalizations.of(context)!;
  final isChinese = Localizations.localeOf(context).languageCode
      .toLowerCase()
      .startsWith('zh');

  final detailsLabel = isChinese ? '查看详情' : 'Details';
  final hideDetailsLabel = isChinese ? '收起详情' : 'Hide details';
  final copyErrorLabel = isChinese ? '复制错误' : 'Copy error';
  final copiedLabel = isChinese ? '已复制错误详情' : 'Copied error details';

  switch (notice.kind) {
    case AppErrorKind.pairingRequired:
      return LocalizedAppErrorText(
        message: l10n.gatewayFailurePairingRequired,
        hint: isChinese
            ? '去设置页面复制设备 ID 给管理员进行授权。'
            : 'Open Settings, copy the device ID, and send it to an administrator for authorization.',
        detailsLabel: detailsLabel,
        hideDetailsLabel: hideDetailsLabel,
        copyErrorLabel: copyErrorLabel,
        copiedLabel: copiedLabel,
      );
    case AppErrorKind.missingWriteScope:
      return LocalizedAppErrorText(
        message: l10n.gatewayFailureMissingWriteScope,
        hint: '',
        detailsLabel: detailsLabel,
        hideDetailsLabel: hideDetailsLabel,
        copyErrorLabel: copyErrorLabel,
        copiedLabel: copiedLabel,
      );
    case AppErrorKind.timeout:
      return LocalizedAppErrorText(
        message: l10n.gatewayFailureTimeout,
        hint: isChinese
            ? '请检查 Gateway 状态后再重试。'
            : 'Check the gateway status and try again.',
        detailsLabel: detailsLabel,
        hideDetailsLabel: hideDetailsLabel,
        copyErrorLabel: copyErrorLabel,
        copiedLabel: copiedLabel,
      );
    case AppErrorKind.disconnect:
      return LocalizedAppErrorText(
        message: l10n.gatewayFailureDisconnect,
        hint: '',
        detailsLabel: detailsLabel,
        hideDetailsLabel: hideDetailsLabel,
        copyErrorLabel: copyErrorLabel,
        copiedLabel: copiedLabel,
      );
    case AppErrorKind.authFailed:
      return LocalizedAppErrorText(
        message: l10n.gatewayFailureAuthFailed,
        hint: '',
        detailsLabel: detailsLabel,
        hideDetailsLabel: hideDetailsLabel,
        copyErrorLabel: copyErrorLabel,
        copiedLabel: copiedLabel,
      );
    case AppErrorKind.pickerUnavailable:
      return LocalizedAppErrorText(
        message: l10n.pickerErrorUnavailable,
        hint: '',
        detailsLabel: detailsLabel,
        hideDetailsLabel: hideDetailsLabel,
        copyErrorLabel: copyErrorLabel,
        copiedLabel: copiedLabel,
      );
    case AppErrorKind.pickerChannel:
      return LocalizedAppErrorText(
        message: l10n.pickerErrorChannel,
        hint: '',
        detailsLabel: detailsLabel,
        hideDetailsLabel: hideDetailsLabel,
        copyErrorLabel: copyErrorLabel,
        copiedLabel: copiedLabel,
      );
    case AppErrorKind.pickerGeneric:
      return LocalizedAppErrorText(
        message: l10n.pickerErrorGeneric,
        hint: '',
        detailsLabel: detailsLabel,
        hideDetailsLabel: hideDetailsLabel,
        copyErrorLabel: copyErrorLabel,
        copiedLabel: copiedLabel,
      );
    case AppErrorKind.emptyResponse:
      return LocalizedAppErrorText(
        message: isChinese ? '服务端返回了空响应。' : 'The server returned an empty response.',
        hint: isChinese ? '请稍后重试。' : 'Please try again.',
        detailsLabel: detailsLabel,
        hideDetailsLabel: hideDetailsLabel,
        copyErrorLabel: copyErrorLabel,
        copiedLabel: copiedLabel,
      );
    case AppErrorKind.chatSendFailed:
      return LocalizedAppErrorText(
        message: isChinese ? '消息发送失败。' : 'Failed to send the message.',
        hint: isChinese ? '请稍后重试。' : 'Please try again.',
        detailsLabel: detailsLabel,
        hideDetailsLabel: hideDetailsLabel,
        copyErrorLabel: copyErrorLabel,
        copiedLabel: copiedLabel,
      );
    case AppErrorKind.aiGenerationFailed:
      return LocalizedAppErrorText(
        message: isChinese ? 'AI 回复失败。' : 'The assistant reply failed.',
        hint: isChinese ? '请稍后重试。' : 'Please try again.',
        detailsLabel: detailsLabel,
        hideDetailsLabel: hideDetailsLabel,
        copyErrorLabel: copyErrorLabel,
        copiedLabel: copiedLabel,
      );
    case AppErrorKind.gatewayNotConfigured:
      return LocalizedAppErrorText(
        message: l10n.gatewayFailureNotConfigured,
        hint: isChinese ? '请先完成设置。' : 'Complete setup first.',
        detailsLabel: detailsLabel,
        hideDetailsLabel: hideDetailsLabel,
        copyErrorLabel: copyErrorLabel,
        copiedLabel: copiedLabel,
      );
    case AppErrorKind.unexpected:
      return LocalizedAppErrorText(
        message: isChinese ? '操作失败，请稍后重试。' : 'Something went wrong. Please try again.',
        hint: isChinese
            ? '如果问题持续存在，可以复制错误详情发给管理员。'
            : 'If the problem persists, copy the error details and send them to an administrator.',
        detailsLabel: detailsLabel,
        hideDetailsLabel: hideDetailsLabel,
        copyErrorLabel: copyErrorLabel,
        copiedLabel: copiedLabel,
      );
  }
}
