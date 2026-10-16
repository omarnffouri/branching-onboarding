import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:meta/meta.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

/// What the measuring page needs to show.
@immutable
final class TapeStepState {
  const TapeStepState({required this.step, required this.value});

  final NumberStep step;

  /// Her saved measurement, or the starting value if she has none (or
  /// skipped it).
  final int value;
}

/// One per measured step (her waist), keyed by step id.
final NotifierProviderFamily<TapeStepController, TapeStepState, String>
tapeStepControllerProvider = NotifierProvider.autoDispose
    .family<TapeStepController, TapeStepState, String>(
      TapeStepController.new,
    );

/// The logic of a measuring page: keep the value within range, save it,
/// move on with it, or skip an optional measurement. The tape's motion
/// (dragging, snapping, haptics) belongs to the page.
class TapeStepController extends Notifier<TapeStepState> {
  TapeStepController(this.stepId);

  final String stepId;

  OnboardingController get _flow =>
      ref.read(onboardingControllerProvider.notifier);

  @override
  TapeStepState build() {
    final step = ref.read(flowConfigProvider).stepById(stepId);
    if (step is! NumberStep) {
      throw ArgumentError.value(stepId, 'stepId', 'is not a number step');
    }
    ref.watch(onboardingControllerProvider.select((flow) => flow.answers));
    return TapeStepState(step: step, value: _flow.measurementValueFor(step));
  }

  /// Keeps any value within the step's range.
  int clamp(num value) => value.round().clamp(state.step.min, state.step.max);

  /// Saves where she settled the tape.
  void record(num value) => _flow.recordMeasurement(stepId, clamp(value));

  /// Saves the value and moves on.
  void submit(num value) => _flow.submitMeasurement(stepId, clamp(value));

  /// Skips an optional measurement; required ones ignore this.
  void skip() => _flow.skipStep(stepId);
}
