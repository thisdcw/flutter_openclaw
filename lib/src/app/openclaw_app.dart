import 'package:flutter/material.dart';
import 'package:flutter_openclaw/l10n/app_localizations.dart';

import '../domain/models/app_locale_preference.dart';
import 'app_dependencies.dart';
import 'app_theme.dart';
import '../presentation/screens/chat_screen.dart';

class OpenClawApp extends StatelessWidget {
  const OpenClawApp({
    super.key,
    required this.dependencies,
  });

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: dependencies.settingsController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: _resolveLocale(
            dependencies.settingsController.localePreference,
          ),
          theme: buildAppTheme(),
          home: ChatScreen(
            settingsController: dependencies.settingsController,
            connectionController: dependencies.connectionController,
            chatController: dependencies.chatController,
          ),
        );
      },
    );
  }

  Locale? _resolveLocale(AppLocalePreference preference) {
    switch (preference) {
      case AppLocalePreference.system:
        return null;
      case AppLocalePreference.english:
        return const Locale('en');
      case AppLocalePreference.simplifiedChinese:
        return const Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
        );
    }
  }
}
