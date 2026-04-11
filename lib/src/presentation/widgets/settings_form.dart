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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: gatewayUrlController,
          decoration: const InputDecoration(labelText: 'Gateway URL'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: authTokenController,
          decoration: const InputDecoration(labelText: 'Auth Token'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: sessionIdController,
          decoration: const InputDecoration(labelText: 'Session ID'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: localeController,
          decoration: const InputDecoration(labelText: 'Locale'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: timeoutController,
          decoration: const InputDecoration(labelText: 'Timeout'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              onPressed: () {
                onSave();
              },
              child: const Text('Save Settings'),
            ),
            FilledButton(
              onPressed: () {
                onTestConnection();
              },
              child: const Text('Test Connection'),
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
              child: const Text('Reset Device Identity'),
            ),
          ],
        ),
      ],
    );
  }
}
