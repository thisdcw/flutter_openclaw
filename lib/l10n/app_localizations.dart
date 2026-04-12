import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Cici'**
  String get appTitle;

  /// No description provided for @chatScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Cici'**
  String get chatScreenTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close Settings'**
  String get settingsCloseTooltip;

  /// No description provided for @settingsOpenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get settingsOpenTooltip;

  /// No description provided for @settingsIntro.
  ///
  /// In en, this message translates to:
  /// **'Review live connection state and tune your chat session configuration.'**
  String get settingsIntro;

  /// No description provided for @gatewayConfigurationTitle.
  ///
  /// In en, this message translates to:
  /// **'Gateway Configuration'**
  String get gatewayConfigurationTitle;

  /// No description provided for @gatewayConfigurationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the chat session details up to date. Connection can be retried directly from the chat page when needed.'**
  String get gatewayConfigurationSubtitle;

  /// No description provided for @connectionOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection Overview'**
  String get connectionOverviewTitle;

  /// No description provided for @connectionOverviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live connection state for this device and session.'**
  String get connectionOverviewSubtitle;

  /// No description provided for @phaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Phase'**
  String get phaseLabel;

  /// No description provided for @deviceIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get deviceIdLabel;

  /// No description provided for @grantedScopesLabel.
  ///
  /// In en, this message translates to:
  /// **'Granted Scopes'**
  String get grantedScopesLabel;

  /// No description provided for @noneLabel.
  ///
  /// In en, this message translates to:
  /// **'(none)'**
  String get noneLabel;

  /// No description provided for @pendingDeviceLabel.
  ///
  /// In en, this message translates to:
  /// **'pending-device'**
  String get pendingDeviceLabel;

  /// No description provided for @appLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguageLabel;

  /// No description provided for @followSystemLabel.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get followSystemLabel;

  /// No description provided for @englishLabel.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLabel;

  /// No description provided for @simplifiedChineseLabel.
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get simplifiedChineseLabel;

  /// No description provided for @settingsFormIntro.
  ///
  /// In en, this message translates to:
  /// **'Gateway URL and auth token stay hidden here for a cleaner everyday view. You can still adjust the session and response behavior below.'**
  String get settingsFormIntro;

  /// No description provided for @sessionIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Session ID'**
  String get sessionIdLabel;

  /// No description provided for @sessionIdHint.
  ///
  /// In en, this message translates to:
  /// **'openclaw-session'**
  String get sessionIdHint;

  /// No description provided for @gatewayLocaleLabel.
  ///
  /// In en, this message translates to:
  /// **'Gateway Locale'**
  String get gatewayLocaleLabel;

  /// No description provided for @gatewayLocaleHint.
  ///
  /// In en, this message translates to:
  /// **'zh-CN'**
  String get gatewayLocaleHint;

  /// No description provided for @timeoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Timeout (ms)'**
  String get timeoutLabel;

  /// No description provided for @timeoutHint.
  ///
  /// In en, this message translates to:
  /// **'30000'**
  String get timeoutHint;

  /// No description provided for @saveSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettingsLabel;

  /// No description provided for @chatEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask anything once your gateway is ready.'**
  String get chatEmptyTitle;

  /// No description provided for @chatEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your assistant replies will stream here as soon as the connection is ready and operator.write is available.'**
  String get chatEmptySubtitle;

  /// No description provided for @chatCommandDiscoveryPrompt.
  ///
  /// In en, this message translates to:
  /// **'Try `/new`, `/status`, `/model`, `/think`, or `/help` to see how commands behave.'**
  String get chatCommandDiscoveryPrompt;

  /// No description provided for @connectionButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connectionButtonLabel;

  /// No description provided for @connectionConnectingTitle.
  ///
  /// In en, this message translates to:
  /// **'Connecting to gateway…'**
  String get connectionConnectingTitle;

  /// No description provided for @connectionStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to gateway to start chatting.'**
  String get connectionStartTitle;

  /// No description provided for @connectionRetrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check your gateway settings and tap Connection to retry.'**
  String get connectionRetrySubtitle;

  /// No description provided for @connectionStatusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Status: {phase}.'**
  String connectionStatusSubtitle(Object phase);

  /// No description provided for @addImagesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add images'**
  String get addImagesTooltip;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message Cici'**
  String get messageHint;

  /// No description provided for @composerModeHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message or start with / to run a command.'**
  String get composerModeHint;

  /// No description provided for @sendLabel.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendLabel;

  /// No description provided for @sendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sendingLabel;

  /// No description provided for @streamingResponseLabel.
  ///
  /// In en, this message translates to:
  /// **'Streaming response'**
  String get streamingResponseLabel;

  /// No description provided for @pickerErrorChannel.
  ///
  /// In en, this message translates to:
  /// **'Image picker is not fully registered yet. Fully restart the app and try again.'**
  String get pickerErrorChannel;

  /// No description provided for @pickerErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The image picker plugin is unavailable. Fully restart the app and try again.'**
  String get pickerErrorUnavailable;

  /// No description provided for @pickerErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Picking images failed. Please try again.'**
  String get pickerErrorGeneric;

  /// No description provided for @blockedReasonNotReady.
  ///
  /// In en, this message translates to:
  /// **'connection not ready'**
  String get blockedReasonNotReady;

  /// No description provided for @blockedReasonMissingWriteScope.
  ///
  /// In en, this message translates to:
  /// **'missing scope: operator.write'**
  String get blockedReasonMissingWriteScope;

  /// No description provided for @gatewayFailureNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Gateway is not configured yet.'**
  String get gatewayFailureNotConfigured;

  /// No description provided for @gatewayFailureMissingWriteScope.
  ///
  /// In en, this message translates to:
  /// **'This device is missing operator.write authorization. Complete pairing or refresh authorization first.'**
  String get gatewayFailureMissingWriteScope;

  /// No description provided for @gatewayFailurePairingRequired.
  ///
  /// In en, this message translates to:
  /// **'This device has not completed pairing authorization yet.'**
  String get gatewayFailurePairingRequired;

  /// No description provided for @gatewayFailureTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Check the gateway and try again.'**
  String get gatewayFailureTimeout;

  /// No description provided for @gatewayFailureDisconnect.
  ///
  /// In en, this message translates to:
  /// **'The gateway connection was lost. Reconnect and try again.'**
  String get gatewayFailureDisconnect;

  /// No description provided for @gatewayFailureAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed for this device. Refresh authorization and try again.'**
  String get gatewayFailureAuthFailed;

  /// No description provided for @gatewayFailureProtocolError.
  ///
  /// In en, this message translates to:
  /// **'The gateway protocol response was invalid.'**
  String get gatewayFailureProtocolError;

  /// No description provided for @gatewayFailureUnknown.
  ///
  /// In en, this message translates to:
  /// **'Gateway error: {code} | {reason}'**
  String gatewayFailureUnknown(Object code, Object reason);

  /// No description provided for @phaseIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get phaseIdle;

  /// No description provided for @phaseConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get phaseConnecting;

  /// No description provided for @phaseWaitingChallenge.
  ///
  /// In en, this message translates to:
  /// **'Waiting for challenge'**
  String get phaseWaitingChallenge;

  /// No description provided for @phaseAuthenticating.
  ///
  /// In en, this message translates to:
  /// **'Authenticating'**
  String get phaseAuthenticating;

  /// No description provided for @phaseReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get phaseReady;

  /// No description provided for @phaseReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting'**
  String get phaseReconnecting;

  /// No description provided for @phaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get phaseFailed;

  /// No description provided for @commandGroupSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Session commands'**
  String get commandGroupSessionLabel;

  /// No description provided for @commandGroupStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status & help'**
  String get commandGroupStatusLabel;

  /// No description provided for @commandGroupSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Model & settings'**
  String get commandGroupSettingsLabel;

  /// No description provided for @commandDescriptionNew.
  ///
  /// In en, this message translates to:
  /// **'Start a new session'**
  String get commandDescriptionNew;

  /// No description provided for @commandDescriptionStatus.
  ///
  /// In en, this message translates to:
  /// **'Check current session health'**
  String get commandDescriptionStatus;

  /// No description provided for @commandDescriptionModel.
  ///
  /// In en, this message translates to:
  /// **'Inspect or switch models'**
  String get commandDescriptionModel;

  /// No description provided for @commandDescriptionThink.
  ///
  /// In en, this message translates to:
  /// **'Adjust the model\'s thinking depth'**
  String get commandDescriptionThink;

  /// No description provided for @commandDescriptionHelp.
  ///
  /// In en, this message translates to:
  /// **'See available help topics'**
  String get commandDescriptionHelp;

  /// No description provided for @commandDescriptionReset.
  ///
  /// In en, this message translates to:
  /// **'Alias of /new'**
  String get commandDescriptionReset;

  /// No description provided for @commandDescriptionCompact.
  ///
  /// In en, this message translates to:
  /// **'Condense the current context'**
  String get commandDescriptionCompact;

  /// No description provided for @commandDescriptionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop the current response'**
  String get commandDescriptionStop;

  /// No description provided for @commandDescriptionFast.
  ///
  /// In en, this message translates to:
  /// **'Toggle faster response mode'**
  String get commandDescriptionFast;

  /// No description provided for @semanticHintGatewayStandalone.
  ///
  /// In en, this message translates to:
  /// **'This will be sent as a Gateway command.'**
  String get semanticHintGatewayStandalone;

  /// No description provided for @semanticHintInlineDirective.
  ///
  /// In en, this message translates to:
  /// **'This inline directive applies only to this message.'**
  String get semanticHintInlineDirective;

  /// No description provided for @semanticHintStandaloneRecommended.
  ///
  /// In en, this message translates to:
  /// **'This command is usually sent on its own.'**
  String get semanticHintStandaloneRecommended;

  /// No description provided for @semanticHintLocalClear.
  ///
  /// In en, this message translates to:
  /// **'`/clear` is a local app command.'**
  String get semanticHintLocalClear;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
