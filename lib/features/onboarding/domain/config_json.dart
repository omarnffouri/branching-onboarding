/// Thrown when the onboarding config cannot be parsed.
///
/// [path] points at the offending value (e.g. `steps[3].options[1].label`) so
/// whoever edits the JSON can find the mistake without reading Dart.
final class ConfigFormatException implements Exception {
  const ConfigFormatException(this.path, this.message);

  final String path;
  final String message;

  @override
  String toString() => 'Invalid onboarding config at $path: $message';
}

typedef JsonMap = Map<String, Object?>;

JsonMap readMap(Object? json, String path) {
  if (json is Map<String, Object?>) return json;
  throw ConfigFormatException(path, 'expected an object');
}

extension JsonFields on JsonMap {
  String string(String key, String path) {
    final value = this[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw ConfigFormatException('$path.$key', 'expected a non-empty string');
  }

  String? optionalString(String key, String path) =>
      containsKey(key) ? string(key, path) : null;

  int integer(String key, String path, {int? fallback}) {
    final value = this[key];
    if (value == null && fallback != null) return fallback;
    if (value is int) return value;
    throw ConfigFormatException('$path.$key', 'expected an integer');
  }

  num number(String key, String path) {
    final value = this[key];
    if (value is num) return value;
    throw ConfigFormatException('$path.$key', 'expected a number');
  }

  List<Object?> list(String key, String path) {
    final value = this[key];
    if (value is List<Object?>) return value;
    throw ConfigFormatException('$path.$key', 'expected a list');
  }

  List<Object?> optionalList(String key, String path) =>
      containsKey(key) ? list(key, path) : const [];
}
