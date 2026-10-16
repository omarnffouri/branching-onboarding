import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:meta/meta.dart';
import 'package:traininpink_onboarding/features/onboarding/application/controllers/text_field_status.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

/// What the text page needs to show.
@immutable
final class TextStepState {
  const TextStepState({
    required this.kind,
    required this.input,
    this.submitted = false,
  });

  final TextInputKind kind;

  /// What is in the field right now, untrimmed.
  final String input;

  /// She tried to continue with an invalid value and hasn't fixed it yet.
  final bool submitted;

  TextFieldStatus get status =>
      TextFieldStatus.of(kind, input, submitted: submitted);

  TextStepState copyWith({String? input, bool? submitted}) => TextStepState(
    kind: kind,
    input: input ?? this.input,
    submitted: submitted ?? this.submitted,
  );
}

/// One per free-text step (her name, her email), keyed by step id.
final NotifierProviderFamily<TextStepController, TextStepState, String>
textStepControllerProvider = NotifierProvider.autoDispose
    .family<TextStepController, TextStepState, String>(
      TextStepController.new,
    );

/// The logic of a free-text page: keep what she typed, save it when valid,
/// and only move on with a valid answer.
class TextStepController extends Notifier<TextStepState> {
  TextStepController(this.stepId);

  final String stepId;

  OnboardingController get _flow =>
      ref.read(onboardingControllerProvider.notifier);

  @override
  TextStepState build() {
    final step = ref.read(flowConfigProvider).stepById(stepId);
    if (step is! TextInputStep) {
      throw ArgumentError.value(stepId, 'stepId', 'is not a text step');
    }
    return TextStepState(
      kind: step.kind,
      // Coming back shows what she typed before.
      input: ref.read(onboardingControllerProvider).textAnswerOf(stepId),
    );
  }

  /// She typed. What is in the field is the truth: an invalid value clears
  /// the saved answer instead of leaving a stale valid one behind.
  void changed(String input) {
    _flow.answer(stepId, TextAnswer(input.trim()));
    final next = state.copyWith(input: input);
    // Fixing the value clears the error straight away.
    state = next.status.isValid ? next.copyWith(submitted: false) : next;
  }

  /// She tapped Continue. Returns false when the value is rejected, so the
  /// page can explain why.
  bool submit() {
    if (_flow.submit(stepId, TextAnswer(state.status.value))) return true;
    state = state.copyWith(submitted: true);
    return false;
  }
}
