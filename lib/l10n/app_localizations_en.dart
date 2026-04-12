// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OpenClaw';

  @override
  String get chatScreenTitle => 'OpenClaw Chat';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsCloseTooltip => 'Close Settings';

  @override
  String get settingsOpenTooltip => 'Open Settings';

  @override
  String get settingsIntro =>
      'Review live connection state and tune your chat session configuration.';

  @override
  String get gatewayConfigurationTitle => 'Gateway Configuration';

  @override
  String get gatewayConfigurationSubtitle =>
      'Keep the chat session details up to date. Connection can be retried directly from the chat page when needed.';

  @override
  String get connectionOverviewTitle => 'Connection Overview';

  @override
  String get connectionOverviewSubtitle =>
      'Live connection state for this device and session.';

  @override
  String get phaseLabel => 'Phase';

  @override
  String get deviceIdLabel => 'Device ID';

  @override
  String get grantedScopesLabel => 'Granted Scopes';

  @override
  String get noneLabel => '(none)';

  @override
  String get pendingDeviceLabel => 'pending-device';

  @override
  String get appLanguageLabel => 'App Language';

  @override
  String get followSystemLabel => 'Follow system';

  @override
  String get englishLabel => 'English';

  @override
  String get simplifiedChineseLabel => 'Simplified Chinese';

  @override
  String get settingsFormIntro =>
      'Gateway URL and auth token stay hidden here for a cleaner everyday view. You can still adjust the session and response behavior below.';

  @override
  String get sessionIdLabel => 'Session ID';

  @override
  String get sessionIdHint => 'openclaw-session';

  @override
  String get gatewayLocaleLabel => 'Gateway Locale';

  @override
  String get gatewayLocaleHint => 'zh-CN';

  @override
  String get timeoutLabel => 'Timeout (ms)';

  @override
  String get timeoutHint => '30000';

  @override
  String get saveSettingsLabel => 'Save Settings';

  @override
  String get chatEmptyTitle => 'Ask anything once your gateway is ready.';

  @override
  String get chatEmptySubtitle =>
      'Your assistant replies will stream here as soon as the connection is ready and operator.write is available.';

  @override
  String get connectionButtonLabel => 'Connection';

  @override
  String get connectionConnectingTitle => 'Connecting to gateway…';

  @override
  String get connectionStartTitle => 'Connect to gateway to start chatting.';

  @override
  String get connectionRetrySubtitle =>
      'Check your gateway settings and tap Connection to retry.';

  @override
  String connectionStatusSubtitle(Object phase) {
    return 'Status: $phase.';
  }

  @override
  String get addImagesTooltip => 'Add images';

  @override
  String get messageHint => 'Message OpenClaw';

  @override
  String get sendLabel => 'Send';

  @override
  String get sendingLabel => 'Sending...';

  @override
  String get streamingResponseLabel => 'Streaming response';

  @override
  String get pickerErrorChannel =>
      'Image picker is not fully registered yet. Fully restart the app and try again.';

  @override
  String get pickerErrorUnavailable =>
      'The image picker plugin is unavailable. Fully restart the app and try again.';

  @override
  String get pickerErrorGeneric => 'Picking images failed. Please try again.';

  @override
  String get blockedReasonNotReady => 'connection not ready';

  @override
  String get blockedReasonMissingWriteScope => 'missing scope: operator.write';

  @override
  String get gatewayFailureNotConfigured => 'Gateway is not configured yet.';

  @override
  String get gatewayFailureMissingWriteScope =>
      'This device is missing operator.write authorization. Complete pairing or refresh authorization first.';

  @override
  String get gatewayFailurePairingRequired =>
      'This device has not completed pairing authorization yet.';

  @override
  String get gatewayFailureTimeout =>
      'The request timed out. Check the gateway and try again.';

  @override
  String get gatewayFailureDisconnect =>
      'The gateway connection was lost. Reconnect and try again.';

  @override
  String get gatewayFailureAuthFailed =>
      'Authentication failed for this device. Refresh authorization and try again.';

  @override
  String get gatewayFailureProtocolError =>
      'The gateway protocol response was invalid.';

  @override
  String gatewayFailureUnknown(Object code, Object reason) {
    return 'Gateway error: $code | $reason';
  }

  @override
  String get phaseIdle => 'Idle';

  @override
  String get phaseConnecting => 'Connecting';

  @override
  String get phaseWaitingChallenge => 'Waiting for challenge';

  @override
  String get phaseAuthenticating => 'Authenticating';

  @override
  String get phaseReady => 'Ready';

  @override
  String get phaseReconnecting => 'Reconnecting';

  @override
  String get phaseFailed => 'Failed';
}
