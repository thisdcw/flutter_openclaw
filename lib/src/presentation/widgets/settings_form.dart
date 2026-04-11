import 'package:flutter/material.dart';

class SettingsForm extends StatelessWidget {
  const SettingsForm({
    super.key,
    required this.sessionIdController,
    required this.localeController,
    required this.timeoutController,
    required this.onSave,
  });

  final TextEditingController sessionIdController;
  final TextEditingController localeController;
  final TextEditingController timeoutController;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gateway URL and auth token stay hidden here for a cleaner everyday view. You can still adjust the session and response behavior below.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        TextField(
          controller: sessionIdController,
          decoration: const InputDecoration(
            labelText: 'Session ID',
            hintText: 'openclaw-session',
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: localeController,
                decoration: const InputDecoration(
                  labelText: 'Locale',
                  hintText: 'zh-CN',
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: timeoutController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Timeout (ms)',
                  hintText: '30000',
                ),
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
          ],
        ),
      ],
    );
  }
}
