import 'package:traininpink_onboarding/features/onboarding/domain/config_json.dart';

/// Copy that lives in the config, in every language the app ships.
///
/// Question copy sits next to the question it belongs to (rather than in the
/// ARB files) so that adding a question is a one-file change.
final class LocalizedText {
  const LocalizedText(this.values);

  factory LocalizedText.fromJson(Object? json, String path) {
    final map = readMap(json, path);
    if (map.isEmpty) {
      throw ConfigFormatException(path, 'expected at least one language');
    }
    return LocalizedText({
      for (final language in map.keys) language: map.string(language, path),
    });
  }

  static const fallbackLanguage = 'en';

  final Map<String, String> values;

  Iterable<String> get languages => values.keys;

  String resolve(String languageCode) =>
      values[languageCode] ?? values[fallbackLanguage] ?? values.values.first;
}

/// Placeholders like `{name}` are replaced with her answer to that step.
final placeholderPattern = RegExp(r'\{([a-z0-9_]+)\}');

Iterable<String> placeholdersIn(LocalizedText text) => {
  for (final value in text.values.values)
    for (final match in placeholderPattern.allMatches(value)) match.group(1)!,
};
