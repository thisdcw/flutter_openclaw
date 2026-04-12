// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Cici';

  @override
  String get chatScreenTitle => 'Cici';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsCloseTooltip => '关闭设置';

  @override
  String get settingsOpenTooltip => '打开设置';

  @override
  String get settingsIntro => '查看实时连接状态、应用偏好，以及当前网关会话详情。';

  @override
  String get basicSettingsTitle => '基础设置';

  @override
  String get basicSettingsSubtitle => '管理当前设备上的应用级偏好设置。';

  @override
  String get gatewayConfigurationTitle => '网关配置';

  @override
  String get gatewayConfigurationSubtitle =>
      'Gateway 会话详情由客户端管理，这里仅作展示。需要时可以直接在聊天页重试连接。';

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
  String get copyValueTooltip => '复制';

  @override
  String get copiedDeviceIdMessage => '已复制设备 ID';

  @override
  String get copiedGrantedScopesMessage => '已复制权限信息';

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
  String get chatCommandDiscoveryPrompt =>
      '试试 `/new`、`/status`、`/model`、`/think` 或 `/help` 来了解命令。';

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
  String get messageHint => '向 Cici 发送消息';

  @override
  String get composerModeHint => '输入消息或以 / 开头使用命令。';

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

  @override
  String get commandGroupSessionLabel => '会话命令';

  @override
  String get commandGroupStatusLabel => '状态与帮助';

  @override
  String get commandGroupSettingsLabel => '模型与设置';

  @override
  String get commandDescriptionNew => '开启一个新会话';

  @override
  String get commandDescriptionStatus => '查看当前会话状态';

  @override
  String get commandDescriptionModel => '查看或切换模型';

  @override
  String get commandDescriptionThink => '调整模型的思考深度';

  @override
  String get commandDescriptionHelp => '查看可用帮助';

  @override
  String get commandDescriptionReset => '等同于 /new';

  @override
  String get commandDescriptionCompact => '压缩当前上下文';

  @override
  String get commandDescriptionStop => '停止当前回复';

  @override
  String get commandDescriptionFast => '切换快速响应模式';

  @override
  String get semanticHintGatewayStandalone => '这会作为 Gateway 命令发送。';

  @override
  String get semanticHintInlineDirective => '检测到的内联指令仅影响当前消息。';

  @override
  String get semanticHintStandaloneRecommended => '该命令通常单独发送。';

  @override
  String get semanticHintLocalClear => '`/clear` 是本地客户端命令。';
}
