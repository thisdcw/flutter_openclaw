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
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    final valueStyle = Theme.of(context).textTheme.bodyMedium;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connection Summary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('Phase', style: labelStyle),
            Text(phase, style: valueStyle),
            const SizedBox(height: 8),
            Text('Device ID', style: labelStyle),
            Text(deviceId, style: valueStyle),
            const SizedBox(height: 8),
            Text('Granted Scopes', style: labelStyle),
            Text(
              scopes.isEmpty ? '(none)' : scopes.join(', '),
              style: valueStyle,
            ),
          ],
        ),
      ),
    );
  }
}
