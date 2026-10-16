import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traininpink_onboarding/features/onboarding/application/controllers/choice_step_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';

import '../../../../helpers/config_fixtures.dart';
import '../../../../helpers/fakes.dart';

void main() {
  late ProviderContainer container;

  void openOn(String stepId, Map<String, Object?> answers) {
    final config = loadBundledConfig();
    // Listening keeps the auto-disposed controller alive.
    container = createContainer(
      store: InMemoryOnboardingStore()
        ..progress = {
          'configVersion': config.version,
          'stage': 'questions',
          'currentStepId': stepId,
          'answers': answers,
          'selectedPlanId': 'yearly',
        },
    )..listen(choiceStepControllerProvider(stepId), (_, _) {});
  }

  ChoiceStepController page(String stepId) =>
      container.read(choiceStepControllerProvider(stepId).notifier);
  ChoiceStepState choice(String stepId) =>
      container.read(choiceStepControllerProvider(stepId));
  Answer? saved(String stepId) =>
      container.read(onboardingControllerProvider).answers[stepId];

  group('single choice (goal)', () {
    setUp(() => openOn('goal', {'name': 'Layla'}));

    test('shows its options, nothing picked, cannot go on yet', () {
      expect(choice('goal').options, hasLength(4));
      expect(choice('goal').selectedIds, isEmpty);
      expect(choice('goal').canContinue, isFalse);
      expect(choice('goal').isMulti, isFalse);
    });

    test('picking an option saves it and allows Continue', () {
      final option = choice('goal').options.first;

      expect(page('goal').select(option), isTrue);
      expect(saved('goal'), ChoiceAnswer(option.id));
      expect(choice('goal').isSelected(option), isTrue);
      expect(choice('goal').canContinue, isTrue);
    });

    test('continuing moves the flow on', () {
      page('goal')
        ..select(choice('goal').options.first)
        ..continueStep();

      expect(
        container.read(onboardingControllerProvider).currentStepId,
        isNot('goal'),
      );
    });
  });

  test('multi choice toggles options on and off', () {
    openOn('focus_areas', {
      'name': 'Layla',
      'goal': 'build_strength',
      'current_training': 'sometimes',
      'days_per_week': 3,
    });
    final first = choice('focus_areas').options[0];
    final second = choice('focus_areas').options[1];

    page('focus_areas')
      ..select(first)
      ..select(second)
      ..select(first);

    expect(choice('focus_areas').isMulti, isTrue);
    expect(choice('focus_areas').selectedIds, {second.id});
  });

  test('a step that is not a choice step is refused', () {
    openOn('goal', {'name': 'Layla'});

    expect(
      () => container.read(choiceStepControllerProvider('name')),
      throwsA(anything),
    );
  });
}
