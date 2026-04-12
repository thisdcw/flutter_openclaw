import 'package:flutter/material.dart';
import 'package:flutter_openclaw/l10n/app_localizations.dart';

import '../../domain/models/app_locale_preference.dart';

class SettingsForm extends StatelessWidget {
  const SettingsForm({
    super.key,
    required this.localePreference,
    required this.sessionIdController,
    required this.localeController,
    required this.timeoutController,
    required this.onLocalePreferenceChanged,
    required this.onSave,
  });

  final AppLocalePreference localePreference;
  final TextEditingController sessionIdController;
  final TextEditingController localeController;
  final TextEditingController timeoutController;
  final ValueChanged<AppLocalePreference> onLocalePreferenceChanged;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsFormIntro,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<AppLocalePreference>(
          value: localePreference,
          decoration: InputDecoration(
            labelText: l10n.appLanguageLabel,
          ),
          items: [
            DropdownMenuItem<AppLocalePreference>(
              value: AppLocalePreference.system,
              child: Text(l10n.followSystemLabel),
            ),
            DropdownMenuItem<AppLocalePreference>(
              value: AppLocalePreference.english,
              child: Text(l10n.englishLabel),
            ),
            DropdownMenuItem<AppLocalePreference>(
              value: AppLocalePreference.simplifiedChinese,
              child: Text(l10n.simplifiedChineseLabel),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onLocalePreferenceChanged(value);
            }
          },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: sessionIdController,
          decoration: InputDecoration(
            labelText: l10n.sessionIdLabel,
            hintText: l10n.sessionIdHint,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: localeController,
                decoration: InputDecoration(
                  labelText: l10n.gatewayLocaleLabel,
                  hintText: l10n.gatewayLocaleHint,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: timeoutController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.timeoutLabel,
                  hintText: l10n.timeoutHint,
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
              label: Text(l10n.saveSettingsLabel),
            ),
          ],
        ),
      ],
    );
  }
}
