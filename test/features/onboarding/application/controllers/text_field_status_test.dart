import 'dart:ui' show TextDirection;

import 'package:flutter_test/flutter_test.dart';
import 'package:traininpink_onboarding/features/onboarding/application/controllers/text_field_status.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

void main() {
  const email = TextInputKind.email;
  const name = TextInputKind.name;

  group('Continue and errors', () {
    test('Continue is offered once anything is typed', () {
      expect(TextFieldStatus.of(email, '   ').canContinue, isFalse);
      expect(TextFieldStatus.of(email, 'l').canContinue, isTrue);
    });

    test('an invalid email never shows an error while she is typing', () {
      final status = TextFieldStatus.of(email, 'layla@');

      expect(status.isValid, isFalse);
      expect(status.showError, isFalse);
    });

    test('the error shows after a failed Continue, and not once fixed', () {
      expect(
        TextFieldStatus.of(email, 'layla@', submitted: true).showError,
        isTrue,
      );
      expect(
        TextFieldStatus.of(email, 'layla@x.com', submitted: true).showError,
        isFalse,
      );
    });

    test('the saved value is trimmed', () {
      expect(TextFieldStatus.of(name, '  Layla ').value, 'Layla');
    });
  });

  test('a domain typo gets a suggestion, names never do', () {
    expect(
      TextFieldStatus.of(email, 'layla@gmial.com').suggestion,
      'layla@gmail.com',
    );
    expect(TextFieldStatus.of(name, 'gmial.com').suggestion, isNull);
  });

  group('text direction', () {
    test('emails are always left to right', () {
      expect(TextFieldStatus.of(email, '').direction, TextDirection.ltr);
    });

    test('a name follows the script she types', () {
      expect(TextFieldStatus.of(name, 'ليلى').direction, TextDirection.rtl);
      expect(TextFieldStatus.of(name, 'Layla').direction, isNull);
      expect(TextFieldStatus.of(name, '').direction, isNull);
    });
  });
}
