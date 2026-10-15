import 'package:flutter_test/flutter_test.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/email_address.dart';

void main() {
  group('isValid', () {
    const valid = [
      'layla@example.com',
      '  layla@example.com ',
      'layla.ahmed+fit@mail.example.ae',
      'l@x.io',
    ];
    const invalid = [
      '',
      'layla',
      'layla@',
      '@example.com',
      'layla@example',
      'layla@example.c',
      'layla@@example.com',
      'lay la@example.com',
      'layla..ahmed@example.com',
      '.layla@example.com',
      'layla.@example.com',
      'layla@-example.com',
    ];

    for (final email in valid) {
      test('accepts "$email"', () => expect(EmailAddress.isValid(email), true));
    }
    for (final email in invalid) {
      test('rejects "$email"', () {
        expect(EmailAddress.isValid(email), false);
      });
    }
  });

  group('suggestCorrection', () {
    test('catches common domain typos', () {
      expect(
        EmailAddress.suggestCorrection('layla@gmial.com'),
        'layla@gmail.com',
      );
      expect(
        EmailAddress.suggestCorrection('layla@gmail.con'),
        'layla@gmail.com',
      );
      expect(
        EmailAddress.suggestCorrection('layla@hotmial.com'),
        'layla@hotmail.com',
      );
    });

    test('leaves real domains alone', () {
      expect(EmailAddress.suggestCorrection('layla@gmail.com'), isNull);
      expect(EmailAddress.suggestCorrection('layla@company.ae'), isNull);
      expect(EmailAddress.suggestCorrection('layla@mail.com'), isNull);
      expect(EmailAddress.suggestCorrection('layla@ymail.com'), isNull);
      expect(EmailAddress.suggestCorrection('layla'), isNull);
    });
  });
}
