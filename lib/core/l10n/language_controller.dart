import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/analytics/analytics.dart';
import 'package:traininpink_onboarding/core/l10n/language_store.dart';

const supportedLanguages = ['en', 'ar'];

final languageProvider = NotifierProvider<LanguageController, String>(
  LanguageController.new,
);

/// The app language: her explicit choice if she made one, else the device
/// language if we support it, else English.
class LanguageController extends Notifier<String> {
  @override
  String build() {
    final saved = ref.watch(languageStoreProvider).readLanguage();
    if (saved != null && supportedLanguages.contains(saved)) return saved;
    final device = PlatformDispatcher.instance.locale.languageCode;
    return supportedLanguages.contains(device) ? device : 'en';
  }

  void select(String languageCode) {
    if (languageCode == state || !supportedLanguages.contains(languageCode)) {
      return;
    }
    state = languageCode;
    ref.read(languageStoreProvider).writeLanguage(languageCode).ignore();
    ref.read(analyticsProvider)('language_changed', {
      'language': languageCode,
    });
  }
}
