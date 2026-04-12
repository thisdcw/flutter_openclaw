import 'package:flutter/material.dart';
import 'package:flutter_openclaw/l10n/app_localizations.dart';

import '../../application/controllers/chat_controller.dart';
import '../../application/controllers/connection_controller.dart';
import '../../application/controllers/settings_controller.dart';
import '../../domain/models/app_locale_preference.dart';
import '../widgets/connection_summary_card.dart';
import '../widgets/error_notice_banner.dart';
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
  late AppLocalePreference localePreference;

  @override
  void initState() {
    super.initState();
    localePreference = widget.settingsController.localePreference;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final connectionController = widget.connectionController;
    final config = widget.settingsController.config;
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
              if (connectionController.errorNotice != null) ...[
                const SizedBox(height: 14),
                ErrorNoticeBanner(
                  notice: connectionController.errorNotice!,
                ),
              ],
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.basicSettingsTitle,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.basicSettingsSubtitle,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 18),
                      SettingsForm(
                        localePreference: localePreference,
                        onLocalePreferenceChanged: (next) async {
                          setState(() {
                            localePreference = next;
                          });
                          await widget.settingsController.saveLocalePreference(
                            next,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
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
                      _ReadonlySettingRow(
                        label: l10n.sessionIdLabel,
                        value: config.sessionId,
                      ),
                      const SizedBox(height: 14),
                      _ReadonlySettingRow(
                        label: l10n.gatewayLocaleLabel,
                        value: config.locale,
                      ),
                      const SizedBox(height: 14),
                      _ReadonlySettingRow(
                        label: l10n.timeoutLabel,
                        value: '${config.timeoutMs}',
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
}

class _ReadonlySettingRow extends StatelessWidget {
  const _ReadonlySettingRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
