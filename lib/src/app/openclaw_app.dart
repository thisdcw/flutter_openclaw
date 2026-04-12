import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_openclaw/l10n/app_localizations.dart';

import '../application/controllers/app_error_controller.dart';
import '../domain/models/app_locale_preference.dart';
import '../presentation/localization/localized_app_error_text.dart';
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
          builder: (context, child) {
            return _GlobalErrorHost(
              controller: dependencies.appErrorController,
              child: child ?? const SizedBox.shrink(),
            );
          },
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

class _GlobalErrorHost extends StatefulWidget {
  const _GlobalErrorHost({
    required this.controller,
    required this.child,
  });

  final AppErrorController controller;
  final Widget child;

  @override
  State<_GlobalErrorHost> createState() => _GlobalErrorHostState();
}

class _GlobalErrorHostState extends State<_GlobalErrorHost> {
  String? _lastShownNoticeId;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleGlobalError);
  }

  @override
  void didUpdateWidget(covariant _GlobalErrorHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_handleGlobalError);
    widget.controller.addListener(_handleGlobalError);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleGlobalError);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _handleGlobalError() {
    final notice = widget.controller.activeGlobalNotice;
    if (!mounted || notice == null || notice.id == _lastShownNoticeId) {
      return;
    }
    _lastShownNoticeId = notice.id;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) {
        return;
      }
      final localized = localizeAppErrorText(context, notice);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(localized.message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: notice.hasTechnicalDetails
              ? SnackBarAction(
                  label: localized.copyErrorLabel,
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: notice.technicalDetails),
                    );
                    if (!mounted) {
                      return;
                    }
                    messenger.hideCurrentSnackBar();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(localized.copiedLabel),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                )
              : null,
        ),
      );
      widget.controller.clear(notice.id);
    });
  }
}
