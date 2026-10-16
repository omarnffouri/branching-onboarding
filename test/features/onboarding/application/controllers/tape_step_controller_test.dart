import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traininpink_onboarding/features/onboarding/application/controllers/tape_step_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';

import '../../../../helpers/config_fixtures.dart';
import '../../../../helpers/fakes.dart';

void main() {
  const step = 'waist';
  late ProviderContainer container;

  void open({Object? waist}) {
    final config = loadBundledConfig();
    // Listening keeps the auto-disposed controller alive.
    container = createContainer(
      store: InMemoryOnboardingStore()
        ..progress = {
          'configVersion': config.version,
          'stage': 'questions',
          'currentStepId': step,
          'answers': {
            'name': 'Layla',
            'goal': 'feel_lighter',
            'lymph_info': true,
            'waist': ?waist,
          },
          'selectedPlanId': 'yearly',
        },
    )..listen(tapeStepControllerProvider(step), (_, _) {});
  }

  TapeStepController page() =>
      container.read(tapeStepControllerProvider(step).notifier);
  TapeStepState tape() => container.read(tapeStepControllerProvider(step));
  Answer? saved() => container.read(onboardingControllerProvider).answers[step];
  String? currentStep() =>
      container.read(onboardingControllerProvider).currentStepId;

  test('starts at the configured value, or at her saved one', () {
    open();
    expect(tape().value, tape().step.initial);

    open(waist: 84);
    expect(tape().value, 84);
  });

  test('values are kept within the range and rounded', () {
    open();

    expect(page().clamp(tape().step.max + 40), tape().step.max);
    expect(page().clamp(tape().step.min - 40), tape().step.min);
    expect(page().clamp(79.6), 80);
  });

  test('recording saves where she settled, within range', () {
    open();

    page().record(1000);

    expect(saved(), NumberAnswer(tape().step.max));
    expect(tape().value, tape().step.max);
  });

  test('the tape moves within range and ticks on each whole number', () {
    open();
    final start = tape().value;

    expect(page().moveTo(start + 0.3), isFalse);
    expect(tape().position, start + 0.3);
    expect(page().moveTo(start + 0.6), isTrue);
    expect(tape().shown, start + 1);

    page().moveTo(1000);
    expect(tape().position, tape().step.max);
    // Moving alone saves nothing.
    expect(saved(), isNull);
  });

  test('the buttons move one cm and save it', () {
    open(waist: 84);

    page().nudge(1);

    expect(tape().shown, 85);
    expect(saved(), const NumberAnswer(85));
  });

  test('letting go saves the nearest whole number', () {
    open(waist: 84);
    page().dragBy(1.4);

    expect(page().settle(instant: true), 85);
    expect(tape().position, 85);
    expect(saved(), const NumberAnswer(85));
  });

  test('skipping puts the tape back on the starting value', () {
    open(waist: 84);

    page()
      ..moveTo(90)
      ..skip();

    expect(tape().position, tape().step.initial);
  });

  test('submitting saves the value and moves on', () {
    open();

    page()
      ..moveTo(82)
      ..submit();

    expect(saved(), const NumberAnswer(82));
    expect(currentStep(), isNot(step));
  });

  test('skipping an optional measurement moves on without a value', () {
    open();

    page().skip();

    expect(saved(), const SkippedAnswer());
    expect(currentStep(), isNot(step));
  });
}
