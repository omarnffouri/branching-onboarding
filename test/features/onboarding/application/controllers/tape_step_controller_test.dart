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

  test('submitting saves the value and moves on', () {
    open();

    page().submit(82);

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
