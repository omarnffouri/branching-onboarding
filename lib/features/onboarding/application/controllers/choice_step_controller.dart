import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:meta/meta.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_state.dart';
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
    required this.isCurrent,
    required this.showContinue,
    required this.bodySide,
  });

  final ChoiceStep step;

  /// The options her earlier answers make visible.
  final List<ChoiceOption> options;
  final Set<String> selectedIds;
  final bool canContinue;

  /// This is the question on screen (the page stays alive behind later ones).
  final bool isCurrent;

  /// Single choice moves on by itself, so Continue only shows for an answer
  /// she already gave: when the page opens on one, or she comes back to it.
  final bool showContinue;

  /// Which way the body map faces.
  final BodySide bodySide;

  ChoiceStepState copyWith({BodySide? bodySide}) => ChoiceStepState(
    step: step,
    options: options,
    selectedIds: selectedIds,
    canContinue: canContinue,
    isCurrent: isCurrent,
    showContinue: showContinue,
    bodySide: bodySide ?? this.bodySide,
  );

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

  /// A single choice moves on by itself, a beat after she taps.
  Timer? _advance;

  @override
  ChoiceStepState build() {
    final step = ref.read(flowConfigProvider).stepById(stepId);
    if (step is! ChoiceStep) {
      throw ArgumentError.value(stepId, 'stepId', 'is not a choice step');
    }
    final flow = ref.watch(onboardingControllerProvider);
    // What the page showed before this change, kept across rebuilds.
    final previous = stateOrNull;
    final answered = flow.resolution.isAnswered(stepId);
    final isCurrent =
        flow.stage == OnboardingStage.questions && flow.currentStepId == stepId;
    // The page stays alive behind later ones: leaving it, or it going
    // away, cancels a pending move on.
    if (!isCurrent) _advance?.cancel();
    ref.onCancel(() => _advance?.cancel());
    return ChoiceStepState(
      step: step,
      options: step.visibleOptions(flow.answers),
      selectedIds: switch (flow.answers[stepId]) {
        ChoiceAnswer(:final optionId) => {optionId},
        MultiChoiceAnswer(:final optionIds) => optionIds,
        _ => const {},
      },
      canContinue: answered,
      isCurrent: isCurrent,
      showContinue: switch (previous) {
        null => answered,
        final previous =>
          previous.showContinue ||
              (isCurrent && !previous.isCurrent && answered),
      },
      bodySide: previous?.bodySide ?? BodySide.front,
    );
  }

  /// She tapped an option: picks it, or toggles it on a multi choice.
  /// Returns false when the tap no longer applies (e.g. a stale tap on a
  /// page that is being left).
  ///
  /// A single choice then moves on after a short beat ([instant] under
  /// Reduce Motion). Picking a body area she can't see turns the figure so
  /// it lands in view.
  bool select(ChoiceOption option, {bool instant = false}) {
    final region = option.region;
    if (region != null &&
        !state.isSelected(option) &&
        !region.visibleOn(state.bodySide)) {
      turnTo(state.bodySide.opposite);
    }
    if (!_flow.selectChoice(stepId, option.id)) return false;
    if (state.step is SingleChoiceStep) {
      _advance?.cancel();
      _advance = Timer(instant ? Duration.zero : AppMotion.selectionBeat, () {
        if (ref.mounted) continueStep();
      });
    }
    return true;
  }

  /// Turns the body map to [side].
  void turnTo(BodySide side) {
    if (side != state.bodySide) state = state.copyWith(bodySide: side);
  }

  void continueStep() {
    _advance?.cancel();
    _flow.continueFrom(stepId);
  }
}
