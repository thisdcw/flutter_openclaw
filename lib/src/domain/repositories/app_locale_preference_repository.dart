import '../models/app_locale_preference.dart';

abstract class AppLocalePreferenceRepository {
  Future<AppLocalePreference> load();
  Future<void> save(AppLocalePreference preference);
}
