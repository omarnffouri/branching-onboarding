import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traininpink_onboarding/features/onboarding/application/controllers/week_step_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

import '../../../../helpers/config_fixtures.dart';
import '../../../../helpers/fakes.dart';

void main() {
  // The pace page groups "how often do you train" and "sessions a week";
  // it is keyed by its first step.
  const page = 'current_training';
  late ProviderContainer container;

  setUp(() {
    final config = loadBundledConfig();
    // Listening keeps the auto-disposed controller alive.
    container = createContainer(
      store: InMemoryOnboardingStore()
        ..progress = {
          'configVersion': config.version,
          'stage': 'questions',
          'currentStepId': page,
          'answers': {'name': 'Layla', 'goal': 'build_strength'},
          'selectedPlanId': 'yearly',
        },
    )..listen(weekStepControllerProvider(page), (_, _) {});
  });

  WeekStepController controller() =>
      container.read(weekStepControllerProvider(page).notifier);
  WeekStepState week() => container.read(weekStepControllerProvider(page));
  Answers answers() => container.read(onboardingControllerProvider).answers;

  SingleChoiceStep routine() =>
      week().steps.whereType<SingleChoiceStep>().single;
  ChoiceOption option(String id) =>
      routine().options.firstWhere((option) => option.id == id);

  test(
    'before she picks a routine, the minimum shows and she cannot go on',
    () {
      expect(week().count, 2);
      expect(week().canContinue, isFalse);
    },
  );

  group('picking a routine', () {
    test('saves it and suggests a weekly count to match', () {
      controller().selectRoutine(routine(), option('sometimes'));

      expect(answers()['current_training'], const ChoiceAnswer('sometimes'));
      expect(answers()['days_per_week'], const NumberAnswer(3));
      expect(week().count, 3);
      expect(week().max, 4);
      expect(week().canContinue, isTrue);
    });

    test('a lighter routine lowers the limit and re-suggests', () {
      controller()
        ..selectRoutine(routine(), option('regularly'))
        ..selectRoutine(routine(), option('rarely'));

      expect(week().max, 3);
      expect(week().count, 2);
      expect(answers()['days_per_week'], const NumberAnswer(2));
    });
  });

  group('changing the count', () {
    setUp(() => controller().selectRoutine(routine(), option('rarely')));

    test('within the limit it is saved', () {
      expect(controller().setCount(3), FrequencyChange.changed);
      expect(answers()['days_per_week'], const NumberAnswer(3));
    });

    test('above the limit it is refused, and the page explains why', () {
      expect(controller().setCount(4), FrequencyChange.overLimit);
      expect(answers()['days_per_week'], const NumberAnswer(2));
      expect(week().atLimit, isTrue);

      controller().setCount(3);
      expect(week().atLimit, isFalse);
    });

    test('picking a routine clears the limit message', () {
      controller().setCount(4);
      controller().selectRoutine(routine(), option('rarely'));

      expect(week().atLimit, isFalse);
    });

    test('below the minimum, or the same count, nothing happens', () {
      expect(controller().setCount(1), FrequencyChange.ignored);
      expect(controller().setCount(2), FrequencyChange.ignored);
      expect(answers()['days_per_week'], const NumberAnswer(2));
    });
  });

  test('continuing saves the count she sees and moves past the page', () {
    controller()
      ..selectRoutine(routine(), option('sometimes'))
      ..continuePage();

    final flow = container.read(onboardingControllerProvider);
    expect(flow.answers['days_per_week'], const NumberAnswer(3));
    expect(flow.currentStepId, isNot(anyOf(page, 'days_per_week')));
  });

  test('continuing before a routine is picked does nothing', () {
    controller().continuePage();

    expect(container.read(onboardingControllerProvider).currentStepId, page);
  });
}
