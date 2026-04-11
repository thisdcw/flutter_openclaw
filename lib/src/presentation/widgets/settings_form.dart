import 'package:flutter/material.dart';

class SettingsForm extends StatelessWidget {
  const SettingsForm({
    super.key,
    required this.gatewayUrlController,
    required this.authTokenController,
    required this.sessionIdController,
    required this.localeController,
    required this.timeoutController,
    required this.onSave,
    required this.onTestConnection,
    required this.onClearDeviceToken,
    required this.onResetDeviceIdentity,
  });

  final TextEditingController gatewayUrlController;
  final TextEditingController authTokenController;
  final TextEditingController sessionIdController;
  final TextEditingController localeController;
  final TextEditingController timeoutController;
  final Future<void> Function() onSave;
  final Future<void> Function() onTestConnection;
  final Future<void> Function() onClearDeviceToken;
  final Future<void> Function() onResetDeviceIdentity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: gatewayUrlController,
          decoration: const InputDecoration(labelText: 'Gateway URL'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: authTokenController,
          decoration: const InputDecoration(labelText: 'Auth Token'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: sessionIdController,
          decoration: const InputDecoration(labelText: 'Session ID'),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: localeController,
                decoration: const InputDecoration(labelText: 'Locale'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: timeoutController,
                decoration: const InputDecoration(labelText: 'Timeout'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () {
                onSave();
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Settings'),
            ),
            FilledButton.tonalIcon(
              onPressed: () {
                onTestConnection();
              },
              icon: const Icon(Icons.wifi_tethering_rounded),
              label: const Text('Test Connection'),
            ),
            OutlinedButton(
              onPressed: () {
                onClearDeviceToken();
              },
              child: const Text('Clear Device Token'),
            ),
            OutlinedButton(
              onPressed: () {
                onResetDeviceIdentity();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.onErrorContainer,
              ),
              child: const Text('Reset Device Identity'),
            ),
          ],
        ),
      ],
    );
  }
}
