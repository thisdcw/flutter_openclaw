enum AppLocalePreference {
  system('system'),
  english('en'),
  simplifiedChinese('zh-Hans');

  const AppLocalePreference(this.storageValue);

  final String storageValue;

  static AppLocalePreference fromStorageValue(String? value) {
    for (final candidate in AppLocalePreference.values) {
      if (candidate.storageValue == value) {
        return candidate;
      }
    }
    return AppLocalePreference.system;
  }
}
