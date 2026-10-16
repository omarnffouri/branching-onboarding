import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:meta/meta.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

/// What happened when she tried to change her weekly count.
enum FrequencyChange {
  /// Saved.
  changed,

  /// Above what her routine allows; the page explains why.
  overLimit,

  /// Below the minimum, or no change: nothing to do.
  ignored,
}

/// What the "find your pace" page needs to show.
@immutable
final class WeekStepState {
  const WeekStepState({
    required this.steps,
    required this.count,
    required this.min,
    required this.max,
    required this.canContinue,
  });

  /// The questions on this page, in path order.
  final List<FlowStep> steps;

  /// Sessions a week: her answer, or the suggestion for her routine until
  /// she picks one.
  final int count;
  final int min;

  /// The most her routine allows (beginners start lower).
  final int max;
  final bool canContinue;

  FrequencyStep? get frequency => steps.whereType<FrequencyStep>().firstOrNull;
}

/// One per grouped page, keyed by the page's first step id.
final NotifierProviderFamily<WeekStepController, WeekStepState, String>
weekStepControllerProvider = NotifierProvider.autoDispose
    .family<WeekStepController, WeekStepState, String>(
      WeekStepController.new,
    );

/// The logic of the routine + frequency page: suggest a weekly count that
/// fits her routine, keep it within her limit, and save it on Continue.
/// Derived from the flow on every change, so it never disagrees with her
/// saved answers.
class WeekStepController extends Notifier<WeekStepState> {
  WeekStepController(this.pageId);

  final String pageId;

  OnboardingController get _flow =>
      ref.read(onboardingControllerProvider.notifier);

  @override
  WeekStepState build() {
    final flow = ref.watch(onboardingControllerProvider);
    final answers = flow.answers;
    // The page may be on its way out after her path changed: show nothing
    // rather than fail while it animates away.
    final steps =
        flow.pageGroups
            .where((group) => group.contains(pageId))
            .firstOrNull
            ?.steps ??
        const [];
    final frequency = steps.whereType<FrequencyStep>().firstOrNull;

    final min = frequency?.min ?? 0;
    final max = frequency?.allowedMax(answers) ?? 0;
    final count = switch (answers[frequency?.id]) {
      NumberAnswer(:final value) => value,
      _ => frequency?.suggestionFor(answers) ?? min,
    };
    final questionsAnswered = steps
        .where((step) => step is! FrequencyStep)
        .every((step) => flow.resolution.isAnswered(step.id));

    return WeekStepState(
      steps: steps,
      count: count,
      min: min,
      max: max,
      canContinue:
          steps.isNotEmpty &&
          questionsAnswered &&
          (frequency == null || (count >= min && count <= max)),
    );
  }

  /// She picked her routine. Saves it and re-suggests her weekly count,
  /// since what fits a beginner doesn't fit someone training daily.
  void selectRoutine(SingleChoiceStep step, ChoiceOption option) {
    final answers = ref.read(onboardingControllerProvider).answers;
    final choice = ChoiceAnswer(option.id);
    if (answers[step.id] == choice) return;
    final frequency = state.frequency;
    final suggested = frequency?.suggestionFor({...answers, step.id: choice});
    _flow.answerGroup(pageId, {
      step.id: choice,
      if (frequency != null && suggested != null)
        frequency.id: NumberAnswer(suggested),
    });
  }

  /// She moved the picker to [count].
  FrequencyChange setCount(int count) {
    final frequency = state.frequency;
    if (frequency == null || count < state.min || count == state.count) {
      return FrequencyChange.ignored;
    }
    if (count > state.max) return FrequencyChange.overLimit;
    _flow.answerGroup(pageId, {frequency.id: NumberAnswer(count)});
    return FrequencyChange.changed;
  }

  /// Moves on. The count she sees is saved first, so a suggestion she
  /// accepted without touching the picker counts as her answer.
  void continuePage() {
    if (!state.canContinue) return;
    final frequency = state.frequency;
    final answers = ref.read(onboardingControllerProvider).answers;
    if (frequency != null && !answers.containsKey(frequency.id)) {
      _flow.answerGroup(pageId, {frequency.id: NumberAnswer(state.count)});
    }
    _flow.continueGroup(pageId);
  }
}
