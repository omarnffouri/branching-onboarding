import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:traininpink_onboarding/core/l10n/language_store.dart';

/// Where onboarding progress and the chosen language survive app restarts.
///
/// Deliberately dumb: it stores JSON, it does not know what an answer is.
/// Turning state into JSON and back (and deciding what is still valid) is the
/// controller's job, against the current config.
abstract interface class OnboardingStore implements LanguageStore {
  Map<String, Object?>? readProgress();
  Future<void> writeProgress(Map<String, Object?> progress);
  Future<void> clearProgress();
}

final class SharedPreferencesOnboardingStore implements OnboardingStore {
  SharedPreferencesOnboardingStore(this._prefs);

  static const _progressKey = 'onboarding.progress';
  static const _languageKey = 'app.language';

  static Future<SharedPreferencesOnboardingStore> create() async =>
      SharedPreferencesOnboardingStore(
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: {_progressKey, _languageKey},
          ),
        ),
      );

  final SharedPreferencesWithCache _prefs;

  @override
  Map<String, Object?>? readProgress() {
    final raw = _prefs.getString(_progressKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      return json is Map<String, Object?> ? json : null;
    } on FormatException {
      // A corrupt save should cost her a restart, not a crash.
      return null;
    }
  }

  @override
  Future<void> writeProgress(Map<String, Object?> progress) =>
      _prefs.setString(_progressKey, jsonEncode(progress));

  @override
  Future<void> clearProgress() => _prefs.remove(_progressKey);

  @override
  String? readLanguage() => _prefs.getString(_languageKey);

  @override
  Future<void> writeLanguage(String languageCode) =>
      _prefs.setString(_languageKey, languageCode);
}
