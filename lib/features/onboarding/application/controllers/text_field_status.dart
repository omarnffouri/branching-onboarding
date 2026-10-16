import 'dart:ui' show TextDirection;

import 'package:intl/intl.dart' show Bidi;
import 'package:meta/meta.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/email_address.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

/// What a free-text step should show, given what she has typed.
///
/// The rules live here, as a pure function of the input, so the screen only
/// lays out the result and every rule is unit-tested without widgets.
/// Screen-only state (the text controller, focus, the shake) stays in the
/// widget; the onboarding state stays in `OnboardingController`.
@immutable
final class TextFieldStatus {
  const TextFieldStatus._({
    required this.value,
    required this.isValid,
    required this.showError,
    required this.suggestion,
    required this.direction,
  });

  /// [submitted] is whether she has tried to continue with an invalid value
  /// that she hasn't fixed since.
  factory TextFieldStatus.of(
    TextInputKind kind,
    String input, {
    bool submitted = false,
  }) {
    final value = input.trim();
    final isValid = kind.accepts(value);
    final isEmail = kind == TextInputKind.email;
    return TextFieldStatus._(
      value: value,
      isValid: isValid,
      // Never while she is still typing: only after a failed Continue.
      showError: submitted && !isValid,
      suggestion: isEmail ? EmailAddress.suggestCorrection(value) : null,
      // Emails are always left to right; a name follows the script she
      // types, and otherwise follows the app's direction.
      direction: isEmail
          ? TextDirection.ltr
          : value.isNotEmpty && Bidi.detectRtlDirectionality(value)
          ? TextDirection.rtl
          : null,
    );
  }

  /// What she typed, trimmed: what gets saved.
  final String value;

  final bool isValid;
  final bool showError;

  /// A likely fix for a typo in the email domain (`gmial.com`).
  final String? suggestion;

  /// Null means "follow the surrounding direction".
  final TextDirection? direction;

  /// Continue is offered as soon as there is something to check; an invalid
  /// value is then explained rather than silently blocked.
  bool get canContinue => value.isNotEmpty;
}
