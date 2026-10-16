import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show NotifierProviderFamily;
import 'package:meta/meta.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

/// What the measuring page needs to show.
@immutable
final class TapeStepState {
  const TapeStepState({
    required this.step,
    required this.value,
    required this.position,
  });

  final NumberStep step;

  /// Her saved measurement, or the starting value if she has none (or
  /// skipped it).
  final int value;

  /// Where the tape sits right now: fractional while she drags or it snaps,
  /// always within the step's range.
  final double position;

  /// The whole number under the needle.
  int get shown => position.round();
}

/// One per measured step (her waist), keyed by step id.
final NotifierProviderFamily<TapeStepController, TapeStepState, String>
tapeStepControllerProvider = NotifierProvider.autoDispose
    .family<TapeStepController, TapeStepState, String>(
      TapeStepController.new,
    );

/// The logic of a measuring page: where the tape sits, a haptic tick on
/// each whole number, saving where she settles, moving on, or skipping an
/// optional measurement. Only the snap animation belongs to the page.
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
    final value = _flow.measurementValueFor(step);
    // Keep the tape where she left it while it agrees with her saved value;
    // follow the value when it changes elsewhere (a skip, an edit).
    final previous = stateOrNull;
    return TapeStepState(
      step: step,
      value: value,
      position: previous != null && previous.shown == value
          ? previous.position
          : value.toDouble(),
    );
  }

  /// Keeps any value within the step's range.
  int clamp(num value) => value.round().clamp(state.step.min, state.step.max);

  /// Moves the tape while she drags or it snaps. Returns true when a new
  /// whole number lands under the needle, for a haptic tick.
  bool moveTo(double position) {
    final next = position.clamp(state.step.min, state.step.max).toDouble();
    final crossed = next.round() != state.shown;
    state = TapeStepState(step: state.step, value: state.value, position: next);
    if (crossed) HapticFeedback.selectionClick().ignore();
    return crossed;
  }

  /// She dragged the tape by [units] (cm).
  void dragBy(double units) => moveTo(state.position + units);

  /// She let go: saves the nearest whole number and returns it, so the page
  /// can snap the tape onto it ([instant] under Reduce Motion).
  double settle({bool instant = false}) {
    final target = state.shown.toDouble();
    if (instant) moveTo(target);
    record(target);
    return target;
  }

  /// The − / + buttons and accessibility actions: one cm at a time.
  void nudge(int delta) {
    moveTo((state.shown + delta).toDouble());
    record(state.position);
  }

  /// Saves where she settled the tape.
  void record(num value) => _flow.recordMeasurement(stepId, clamp(value));

  /// Saves where the tape sits and moves on.
  void submit() => _flow.submitMeasurement(stepId, clamp(state.position));

  /// Skips an optional measurement; required ones ignore this. The page
  /// stays alive behind the next one, and the tape goes back to the start.
  void skip() {
    _flow.skipStep(stepId);
    HapticFeedback.lightImpact().ignore();
  }
}
