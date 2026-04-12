import 'package:flutter/material.dart';
import 'package:flutter_openclaw/l10n/app_localizations.dart';

import '../localization/localized_gateway_text.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final lower = label.toLowerCase();
    final background = lower == 'ready'
        ? const Color(0xFFE4F7EC)
        : lower.contains('fail')
            ? theme.colorScheme.errorContainer
            : const Color(0xFFEAF2FF);
    final foreground = lower == 'ready'
        ? const Color(0xFF1F7A46)
        : lower.contains('fail')
            ? theme.colorScheme.onErrorContainer
            : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        localizedPhaseLabel(l10n, label),
        style: theme.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
