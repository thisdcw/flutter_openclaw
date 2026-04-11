import 'package:flutter/material.dart';

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connection Overview', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Live connection state for this device and session.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryTile(label: 'Phase', value: phase),
                _SummaryTile(label: 'Device ID', value: deviceId),
                _SummaryTile(
                  label: 'Granted Scopes',
                  value: scopes.isEmpty ? '(none)' : scopes.join(', '),
                  isWide: true,
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
  });

  final String label;
  final String value;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: isWide ? 280 : 150,
        maxWidth: isWide ? 420 : 220,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8FF),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
