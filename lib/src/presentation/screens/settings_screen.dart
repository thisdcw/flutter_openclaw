import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_openclaw/l10n/app_localizations.dart';

import '../../application/controllers/chat_controller.dart';
import '../../application/controllers/connection_controller.dart';
import '../../application/controllers/settings_controller.dart';
import '../../app/app_metadata.dart';
import '../../domain/models/app_locale_preference.dart';
import '../screens/bootstrap_scan_screen.dart';
import '../widgets/bootstrap_import_sheet.dart';
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
    unawaited(widget.settingsController.refreshSecuritySnapshot());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.settingsController,
        widget.connectionController,
        widget.chatController,
      ]),
      builder: (context, _) {
        final theme = Theme.of(context);
        final l10n = AppLocalizations.of(context)!;
        final connectionController = widget.connectionController;
        final config = widget.settingsController.config;
        final activeSessionId =
            widget.chatController.activeConversationSummary?.sessionId ??
                config.sessionId;
        final deviceId = connectionController.status.deviceId ?? '';

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
                            Text(
                              l10n.settingsTitle,
                              style: theme.textTheme.headlineMedium,
                            ),
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
                            '身份与令牌',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '仅展示脱敏后的设备身份与凭证摘要，不支持复制。',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 18),
                          _ReadonlySettingRow(
                            label: l10n.deviceIdLabel,
                            value: _maskSensitiveValue(
                              deviceId,
                              fallback: l10n.pendingDeviceLabel,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _ReadonlySettingRow(
                            label: 'Device Token',
                            value: _maskSensitiveValue(
                              widget.settingsController.deviceToken,
                              fallback: '未授权',
                            ),
                          ),
                          const SizedBox(height: 14),
                          _ReadonlySettingRow(
                            label: 'Bootstrap Token',
                            value: _maskSensitiveValue(
                              widget.settingsController.bootstrapToken,
                              fallback: '未导入',
                            ),
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
                            l10n.pairingTitle,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) => BootstrapImportSheet(
                                        onSubmit: (value) async {
                                          Navigator.of(context).pop();
                                          await _handleBootstrapImport(value);
                                        },
                                      ),
                                    );
                                  },
                                  child: Text(l10n.pairingImportManual),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => BootstrapScanScreen(
                                          onScanned: (value) async {
                                            await _handleBootstrapImport(value);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(l10n.pairingImportScan),
                                ),
                              ),
                            ],
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
                            value: activeSessionId,
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
                  const SizedBox(height: 18),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          appCopyrightText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appVersionText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleBootstrapImport(String value) async {
    try {
      await widget.settingsController.importBootstrapToken(value);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('配对码已导入。'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  String _maskSensitiveValue(String rawValue, {required String fallback}) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }
    if (trimmed.length <= 8) {
      return '*' * trimmed.length;
    }
    final prefix = trimmed.substring(0, 4);
    final suffix = trimmed.substring(trimmed.length - 4);
    return '$prefix****$suffix';
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
