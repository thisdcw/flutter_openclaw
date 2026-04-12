import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_openclaw/l10n/app_localizations.dart';

import '../localization/localized_gateway_text.dart';

class ConnectionSummaryCard extends StatelessWidget {
  const ConnectionSummaryCard({
    super.key,
    required this.phase,
    required this.deviceId,
    required this.scopes,
  });

  final String phase;
  final String deviceId;
  final List<String> scopes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final scopesValue = scopes.isEmpty ? l10n.noneLabel : scopes.join(', ');
    final hasScopes = scopes.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.connectionOverviewTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              l10n.connectionOverviewSubtitle,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryTile(
                  label: l10n.phaseLabel,
                  value: localizedPhaseLabel(l10n, phase),
                ),
                _SummaryTile(
                  label: l10n.deviceIdLabel,
                  value: deviceId,
                  copyValue: deviceId,
                  copiedMessage: l10n.copiedDeviceIdMessage,
                  copyTooltip: l10n.copyValueTooltip,
                ),
                _SummaryTile(
                  label: l10n.grantedScopesLabel,
                  value: scopesValue,
                  isWide: true,
                  copyValue: hasScopes ? scopesValue : null,
                  copiedMessage:
                      hasScopes ? l10n.copiedGrantedScopesMessage : null,
                  copyTooltip: hasScopes ? l10n.copyValueTooltip : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    this.isWide = false,
    this.copyValue,
    this.copiedMessage,
    this.copyTooltip,
  });

  final String label;
  final String value;
  final bool isWide;
  final String? copyValue;
  final String? copiedMessage;
  final String? copyTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color?.withOpacity(0.6) ??
        theme.colorScheme.onSurface.withOpacity(0.6);
    final canCopy =
        copyValue != null && copiedMessage != null && copyTooltip != null;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isWide ? 420 : 220,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(value, style: theme.textTheme.bodyMedium),
                ),
                if (canCopy) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: copyTooltip,
                    onPressed: () async {
                      try {
                        await Clipboard.setData(
                          ClipboardData(text: copyValue!),
                        );
                      } catch (_) {
                        return;
                      }
                      if (!context.mounted) {
                        return;
                      }
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      if (messenger == null) {
                        return;
                      }
                      messenger.hideCurrentSnackBar();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(copiedMessage!),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    color: iconColor,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    splashRadius: 20,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
