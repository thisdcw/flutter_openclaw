import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_locale_preference.dart';
import '../../domain/repositories/app_locale_preference_repository.dart';

class SharedPrefsAppLocalePreferenceRepository
    implements AppLocalePreferenceRepository {
  SharedPrefsAppLocalePreferenceRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _storageKey = 'app_locale_preference';

  static Future<SharedPrefsAppLocalePreferenceRepository> inMemory() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return SharedPrefsAppLocalePreferenceRepository(prefs);
  }

  @override
  Future<AppLocalePreference> load() async {
    final rawValue = _prefs.getString(_storageKey);
    return AppLocalePreference.fromStorageValue(rawValue);
  }

  @override
  Future<void> save(AppLocalePreference preference) async {
    await _prefs.setString(_storageKey, preference.storageValue);
  }
}
