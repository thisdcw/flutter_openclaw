// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'OpenClaw';

  @override
  String get chatScreenTitle => 'OpenClaw 对话';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsCloseTooltip => '关闭设置';

  @override
  String get settingsOpenTooltip => '打开设置';

  @override
  String get settingsIntro => '查看当前连接状态，并调整你的聊天会话配置。';

  @override
  String get gatewayConfigurationTitle => '网关配置';

  @override
  String get gatewayConfigurationSubtitle => '保持聊天会话配置为最新。需要时可以直接在聊天页重试连接。';

  @override
  String get connectionOverviewTitle => '连接概览';

  @override
  String get connectionOverviewSubtitle => '查看当前设备和会话的实时连接状态。';

  @override
  String get phaseLabel => '阶段';

  @override
  String get deviceIdLabel => '设备 ID';

  @override
  String get grantedScopesLabel => '已授予权限';

  @override
  String get noneLabel => '（无）';

  @override
  String get pendingDeviceLabel => '设备准备中';

  @override
  String get appLanguageLabel => '应用语言';

  @override
  String get followSystemLabel => '跟随系统';

  @override
  String get englishLabel => 'English';

  @override
  String get simplifiedChineseLabel => '简体中文';

  @override
  String get settingsFormIntro =>
      '这里默认隐藏 Gateway URL 和授权令牌，让日常视图更简洁。你仍然可以在下方调整会话和响应行为。';

  @override
  String get sessionIdLabel => '会话 ID';

  @override
  String get sessionIdHint => 'openclaw-session';

  @override
  String get gatewayLocaleLabel => '网关 Locale';

  @override
  String get gatewayLocaleHint => 'zh-CN';

  @override
  String get timeoutLabel => '超时时间（毫秒）';

  @override
  String get timeoutHint => '30000';

  @override
  String get saveSettingsLabel => '保存设置';

  @override
  String get chatEmptyTitle => 'Gateway 就绪后就可以开始提问。';

  @override
  String get chatEmptySubtitle => '连接就绪并且具备 operator.write 权限后，助手回复会显示在这里。';

  @override
  String get connectionButtonLabel => '连接';

  @override
  String get connectionConnectingTitle => '正在连接 Gateway…';

  @override
  String get connectionStartTitle => '连接 Gateway 后即可开始聊天。';

  @override
  String get connectionRetrySubtitle => '检查网关设置后，点击“连接”重试。';

  @override
  String connectionStatusSubtitle(Object phase) {
    return '当前状态：$phase。';
  }

  @override
  String get addImagesTooltip => '添加图片';

  @override
  String get messageHint => '向 OpenClaw 发送消息';

  @override
  String get sendLabel => '发送';

  @override
  String get sendingLabel => '发送中…';

  @override
  String get streamingResponseLabel => '正在流式返回';

  @override
  String get pickerErrorChannel => '图片选择器尚未完成原生注册，请完整重启应用后再试。';

  @override
  String get pickerErrorUnavailable => '图片选择器插件不可用，请完整重启应用后再试。';

  @override
  String get pickerErrorGeneric => '选择图片失败，请稍后重试。';

  @override
  String get blockedReasonNotReady => '连接尚未就绪。';

  @override
  String get blockedReasonMissingWriteScope => '缺少权限：operator.write。';

  @override
  String get gatewayFailureNotConfigured => 'Gateway 尚未配置完成。';

  @override
  String get gatewayFailureMissingWriteScope =>
      '当前设备缺少 operator.write 授权，请先完成配对或刷新授权。';

  @override
  String get gatewayFailurePairingRequired => '当前设备尚未完成配对授权。';

  @override
  String get gatewayFailureTimeout => '请求超时，请检查 Gateway 状态后重试。';

  @override
  String get gatewayFailureDisconnect => 'Gateway 连接已断开，请重新连接后再试。';

  @override
  String get gatewayFailureAuthFailed => '当前设备认证失败，请刷新授权后重试。';

  @override
  String get gatewayFailureProtocolError => 'Gateway 协议响应无效。';

  @override
  String gatewayFailureUnknown(Object code, Object reason) {
    return 'Gateway 错误：$code | $reason';
  }

  @override
  String get phaseIdle => '空闲';

  @override
  String get phaseConnecting => '连接中';

  @override
  String get phaseWaitingChallenge => '等待挑战';

  @override
  String get phaseAuthenticating => '认证中';

  @override
  String get phaseReady => '已就绪';

  @override
  String get phaseReconnecting => '重新连接中';

  @override
  String get phaseFailed => '失败';
}
