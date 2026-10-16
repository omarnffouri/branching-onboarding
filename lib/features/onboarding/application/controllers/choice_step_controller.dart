import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:meta/meta.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

/// What the choice page needs to show.
@immutable
final class ChoiceStepState {
  const ChoiceStepState({
    required this.step,
    required this.options,
    required this.selectedIds,
    required this.canContinue,
  });

  final ChoiceStep step;

  /// The options her earlier answers make visible.
  final List<ChoiceOption> options;
  final Set<String> selectedIds;
  final bool canContinue;

  bool get isMulti => step is MultiChoiceStep;
  bool get usesBodyMap => switch (step) {
    MultiChoiceStep(display: ChoiceDisplay.body) => true,
    _ => false,
  };

  bool isSelected(ChoiceOption option) => selectedIds.contains(option.id);
}

/// One per single or multi choice step, keyed by step id.
final NotifierProviderFamily<ChoiceStepController, ChoiceStepState, String>
choiceStepControllerProvider = NotifierProvider.autoDispose
    .family<ChoiceStepController, ChoiceStepState, String>(
      ChoiceStepController.new,
    );

/// The logic of a choice page: which options she sees, what she picked,
/// and whether she can move on. Derived from the flow on every change, so
/// it can never disagree with her saved answers.
class ChoiceStepController extends Notifier<ChoiceStepState> {
  ChoiceStepController(this.stepId);

  final String stepId;

  OnboardingController get _flow =>
      ref.read(onboardingControllerProvider.notifier);

  @override
  ChoiceStepState build() {
    final step = ref.read(flowConfigProvider).stepById(stepId);
    if (step is! ChoiceStep) {
      throw ArgumentError.value(stepId, 'stepId', 'is not a choice step');
    }
    final flow = ref.watch(onboardingControllerProvider);
    return ChoiceStepState(
      step: step,
      options: step.visibleOptions(flow.answers),
      selectedIds: switch (flow.answers[stepId]) {
        ChoiceAnswer(:final optionId) => {optionId},
        MultiChoiceAnswer(:final optionIds) => optionIds,
        _ => const {},
      },
      canContinue: flow.resolution.isAnswered(stepId),
    );
  }

  /// She tapped an option: picks it, or toggles it on a multi choice.
  /// Returns false when the tap no longer applies (e.g. a stale tap on a
  /// page that is being left).
  bool select(ChoiceOption option) => _flow.selectChoice(stepId, option.id);

  void continueStep() => _flow.continueFrom(stepId);
}
