import 'package:flutter/material.dart';
import 'package:flutter_openclaw/l10n/app_localizations.dart';

import '../../domain/models/app_locale_preference.dart';

class SettingsForm extends StatelessWidget {
  const SettingsForm({
    super.key,
    required this.localePreference,
    required this.onLocalePreferenceChanged,
  });

  final AppLocalePreference localePreference;
  final ValueChanged<AppLocalePreference> onLocalePreferenceChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DropdownButtonFormField<AppLocalePreference>(
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
    );
  }
}
