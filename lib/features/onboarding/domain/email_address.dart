/// Email rules for the onboarding email step.
///
/// Validation is intentionally pragmatic: it rejects what is clearly not an
/// address and catches the typos that cost us real signups, without trying to
/// implement RFC 5322. The server is the real authority.
abstract final class EmailAddress {
  static final _pattern = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+"
    '@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?'
    r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*'
    r'\.[A-Za-z]{2,}$',
  );

  static String normalize(String input) => input.trim();

  static bool isValid(String input) {
    final email = normalize(input);
    return email.length <= 254 &&
        !email.contains('..') &&
        !email.startsWith('.') &&
        !email.contains('.@') &&
        _pattern.hasMatch(email);
  }

  /// Domains we offer as corrections.
  static const _commonDomains = [
    'gmail.com',
    'hotmail.com',
    'outlook.com',
    'yahoo.com',
    'icloud.com',
    'live.com',
    'me.com',
  ];

  /// Real domains that are one typo away from a common one. Never "fix" these.
  static const _knownDomains = {
    ..._commonDomains,
    'mail.com',
    'ymail.com',
    'email.com',
    'gmx.com',
    'aol.com',
    'msn.com',
  };

  /// Suggests a fix for a likely domain typo (`gmial.com`, `gmail.con`),
  /// or returns null when the domain looks intentional.
  static String? suggestCorrection(String input) {
    final email = normalize(input);
    final at = email.lastIndexOf('@');
    if (at <= 0 || at == email.length - 1) return null;

    final domain = email.substring(at + 1).toLowerCase();
    if (domain.length < 4 || _knownDomains.contains(domain)) return null;

    for (final candidate in _commonDomains) {
      if (_distance(domain, candidate) <= 2) {
        return '${email.substring(0, at)}@$candidate';
      }
    }
    return null;
  }

  /// Levenshtein distance, plenty fast for strings this short.
  static int _distance(String a, String b) {
    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0)..[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        current[j] = [
          previous[j] + 1,
          current[j - 1] + 1,
          previous[j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
      previous = current;
    }
    return previous[b.length];
  }
}
