import 'package:flutter/material.dart';
import 'package:flutter_openclaw/l10n/app_localizations.dart';

import '../../application/controllers/chat_controller.dart';
import '../../application/controllers/connection_controller.dart';
import '../../application/controllers/settings_controller.dart';
import '../../domain/models/app_locale_preference.dart';
import '../../domain/models/gateway_config.dart';
import '../../infrastructure/util/openclaw_logger.dart';
import '../widgets/connection_summary_card.dart';
import '../widgets/settings_form.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settingsController,
    required this.connectionController,
    required this.chatController,
  });

  final SettingsController settingsController;
  final ConnectionController connectionController;
  final ChatController chatController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController gatewayUrlController;
  late final TextEditingController authTokenController;
  late final TextEditingController sessionIdController;
  late final TextEditingController localeController;
  late final TextEditingController timeoutController;
  late AppLocalePreference localePreference;

  @override
  void initState() {
    super.initState();
    final config = widget.settingsController.config;
    localePreference = widget.settingsController.localePreference;
    gatewayUrlController = TextEditingController(text: config.gatewayUrl);
    authTokenController = TextEditingController(text: config.authToken);
    sessionIdController = TextEditingController(text: config.sessionId);
    localeController = TextEditingController(text: config.locale);
    timeoutController = TextEditingController(text: '${config.timeoutMs}');
  }

  @override
  void dispose() {
    gatewayUrlController.dispose();
    authTokenController.dispose();
    sessionIdController.dispose();
    localeController.dispose();
    timeoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final connectionController = widget.connectionController;
    final deviceId = connectionController.status.deviceId ?? l10n.pendingDeviceLabel;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF3FF), Color(0xFFF6F9FD), Color(0xFFF3F7FC)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.settingsTitle, style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text(
                          l10n.settingsIntro,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).maybePop();
                    },
                    icon: const Icon(Icons.close_rounded),
                    tooltip: l10n.settingsCloseTooltip,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ConnectionSummaryCard(
                phase: connectionController.phase,
                deviceId: deviceId,
                scopes: connectionController.grantedScopes,
              ),
              if ((connectionController.errorMessage ?? '').isNotEmpty) ...[
                const SizedBox(height: 14),
                _InlineBanner(message: connectionController.errorMessage!),
              ],
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.gatewayConfigurationTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.gatewayConfigurationSubtitle,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 18),
                      SettingsForm(
                        localePreference: localePreference,
                        sessionIdController: sessionIdController,
                        localeController: localeController,
                        timeoutController: timeoutController,
                        onLocalePreferenceChanged: (next) async {
                          setState(() {
                            localePreference = next;
                          });
                          await widget.settingsController.saveLocalePreference(
                            next,
                          );
                        },
                        onSave: _saveSettings,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    final current = widget.settingsController.config;
    final timeoutMs =
        int.tryParse(timeoutController.text.trim()) ?? current.timeoutMs;
    final next = GatewayConfig(
      gatewayUrl: gatewayUrlController.text.trim(),
      authToken: authTokenController.text.trim(),
      sessionId: sessionIdController.text.trim(),
      timeoutMs: timeoutMs,
      locale: localeController.text.trim(),
    );

    openClawLog(
      'SettingsScreen',
      'save tapped',
      fields: <String, Object?>{
        'gatewayUrl': next.gatewayUrl,
        'sessionId': next.sessionId,
        'timeoutMs': next.timeoutMs,
        'locale': next.locale,
        'authToken': redactValue(next.authToken),
      },
    );
    await widget.settingsController.save(next);
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}
