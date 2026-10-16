import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where her language choice survives app restarts.
abstract interface class LanguageStore {
  String? readLanguage();
  Future<void> writeLanguage(String languageCode);
}

final languageStoreProvider = Provider<LanguageStore>(
  (ref) => throw UnimplementedError('Override languageStoreProvider in main'),
);
