// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cici';

  @override
  String get chatScreenTitle => 'Cici';

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
  String get chatCommandDiscoveryPrompt =>
      'Try `/new`, `/status`, `/model`, `/think`, or `/help` to see how commands behave.';

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
  String get messageHint => 'Message Cici';

  @override
  String get composerModeHint =>
      'Type a message or start with / to run a command.';

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

  @override
  String get commandGroupSessionLabel => 'Session commands';

  @override
  String get commandGroupStatusLabel => 'Status & help';

  @override
  String get commandGroupSettingsLabel => 'Model & settings';

  @override
  String get commandDescriptionNew => 'Start a new session';

  @override
  String get commandDescriptionStatus => 'Check current session health';

  @override
  String get commandDescriptionModel => 'Inspect or switch models';

  @override
  String get commandDescriptionThink => 'Adjust the model\'s thinking depth';

  @override
  String get commandDescriptionHelp => 'See available help topics';

  @override
  String get commandDescriptionReset => 'Alias of /new';

  @override
  String get commandDescriptionCompact => 'Condense the current context';

  @override
  String get commandDescriptionStop => 'Stop the current response';

  @override
  String get commandDescriptionFast => 'Toggle faster response mode';

  @override
  String get semanticHintGatewayStandalone =>
      'This will be sent as a Gateway command.';

  @override
  String get semanticHintInlineDirective =>
      'This inline directive applies only to this message.';

  @override
  String get semanticHintStandaloneRecommended =>
      'This command is usually sent on its own.';

  @override
  String get semanticHintLocalClear => '`/clear` is a local app command.';
}
