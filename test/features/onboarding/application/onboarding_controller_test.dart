import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_state.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

import '../../../helpers/fakes.dart';

void main() {
  late InMemoryOnboardingStore store;
  late ProviderContainer container;

  OnboardingController controller() =>
      container.read(onboardingControllerProvider.notifier);
  OnboardingState state() => container.read(onboardingControllerProvider);

  setUp(() {
    store = InMemoryOnboardingStore();
    container = createContainer(store: store);
  });

  /// Answers the step on screen and continues, as a member would.
  void answerAndContinue(Answer answer) {
    final stepId = state().currentStepId!;
    controller()
      ..answer(stepId, answer)
      ..continueFrom(stepId);
  }

  /// Walks to the end of the questions with sensible default answers,
  /// overriding the ones given in [answers].
  void finishQuestions([Map<String, Answer> answers = const {}]) {
    while (state().stage == OnboardingStage.questions) {
      final pageId = state().currentStepId!;
      final group = state().pageGroups[state().currentPageIndex];
      for (final step in group.steps) {
        final answer =
            answers[step.id] ??
            switch (step) {
              SingleChoiceStep(:final options) => ChoiceAnswer(
                options.first.id,
              ),
              MultiChoiceStep(:final options) => MultiChoiceAnswer([
                options.first.id,
              ]),
              TextInputStep(kind: TextInputKind.email) => const TextAnswer(
                'layla@example.com',
              ),
              TextInputStep() => const TextAnswer('Layla'),
              NumberStep(:final initial) => NumberAnswer(initial),
              FrequencyStep(:final min) => NumberAnswer(min),
              InfoStep() => const Acknowledged(),
            };
        controller().answerGroup(pageId, {step.id: answer});
      }
      controller().continueGroup(pageId);
    }
  }

  test('starts on the welcome screen, then the first question', () {
    expect(state().stage, OnboardingStage.welcome);

    controller().start();

    expect(state().stage, OnboardingStage.questions);
    expect(state().currentStepId, 'name');
  });

  group('submit', () {
    test('a valid answer is saved and moves on', () {
      controller().start();

      expect(controller().submit('name', const TextAnswer('Layla')), isTrue);
      expect(state().currentStepId, 'goal');
      expect(state().textAnswerOf('name'), 'Layla');
    });

    test('an invalid answer is rejected and she stays', () {
      controller().start();

      expect(controller().submit('name', const TextAnswer('')), isFalse);
      expect(state().currentStepId, 'name');
      expect(state().answers, isNot(contains('name')));
    });

    test('a stale second submit is not reported as a rejection', () {
      controller().start();
      controller().submit('name', const TextAnswer('Layla'));

      expect(controller().submit('name', const TextAnswer('Layla')), isTrue);
      expect(state().currentStepId, 'goal');
    });

    test('textAnswerOf is empty for a step without a valid text answer', () {
      expect(state().textAnswerOf('name'), '');
      expect(state().textAnswerOf('goal'), '');
    });
  });

  test('a double tap on Continue moves exactly one step', () {
    controller()
      ..start()
      ..answer('name', const TextAnswer('Layla'))
      ..continueFrom('name')
      ..continueFrom('name');

    expect(state().currentStepId, 'goal');
  });

  test('Continue does nothing until the step is answered', () {
    controller()
      ..start()
      ..continueFrom('name');

    expect(state().currentStepId, 'name');
  });

  test('measurement and skip actions cannot change required text answers', () {
    controller()
      ..start()
      ..answer('name', const TextAnswer('Layla'))
      ..skipStep('name')
      ..recordMeasurement('name', 82)
      ..submitMeasurement('name', 82)
      ..skipStep('missing')
      ..recordMeasurement('missing', 82)
      ..submitMeasurement('missing', 82);

    expect(state().currentStepId, 'name');
    expect(state().answers['name'], const TextAnswer('Layla'));
  });

  group('measurement actions', () {
    void openWaist() {
      controller().start();
      answerAndContinue(const TextAnswer('Layla'));
      answerAndContinue(const ChoiceAnswer('feel_lighter'));
      answerAndContinue(const Acknowledged());
      expect(state().currentStepId, 'waist');
    }

    NumberStep waistStep() =>
        state().path.firstWhere((step) => step.id == 'waist') as NumberStep;

    test(
      'recording saves a measurement without advancing and survives resume',
      () {
        openWaist();
        final step = waistStep();
        expect(controller().measurementValueFor(step), step.initial);
        controller().recordMeasurement('waist', 82);

        expect(state().currentStepId, 'waist');
        expect(state().answers['waist'], const NumberAnswer(82));
        expect(controller().measurementValueFor(step), 82);
        container = createContainer(store: store);
        expect(state().currentStepId, 'waist');
        expect(controller().measurementValueFor(step), 82);
      },
    );

    test('submit validates the measurement and advances only once', () {
      openWaist();
      controller()
        ..recordMeasurement('waist', 82)
        ..submitMeasurement('waist', waistStep().max + 1);
      expect(state().currentStepId, 'waist');
      expect(state().answers, isNot(contains('waist')));

      controller()
        ..submitMeasurement('waist', 84)
        ..submitMeasurement('waist', 90);
      expect(state().currentStepId, 'current_training');
      expect(state().answers['waist'], const NumberAnswer(84));
    });

    test('skipping completes the step once and resumes at the next page', () {
      openWaist();
      final step = waistStep();
      final progress = state().progress;
      controller()
        ..skipStep('waist')
        ..skipStep('waist')
        ..recordMeasurement('waist', 90)
        ..submitMeasurement('waist', 90);

      expect(state().currentStepId, 'current_training');
      expect(state().resolution.isAnswered('waist'), isTrue);
      expect(state().progress, greaterThan(progress));
      expect(controller().measurementValueFor(step), step.initial);
      expect(
        store.progress!['answers']! as Map<String, Object?>,
        containsPair('waist', 'skipped'),
      );

      container = createContainer(store: store);
      expect(state().currentStepId, 'current_training');
      expect(state().answers['waist'], const SkippedAnswer());
    });

    test(
      'returning to a skipped measurement submits initial as a real value',
      () {
        openWaist();
        final step = waistStep();
        controller()
          ..skipStep('waist')
          ..backFromStep('current_training');
        expect(state().currentStepId, 'waist');
        expect(controller().measurementValueFor(step), step.initial);

        controller().submitMeasurement(
          'waist',
          controller().measurementValueFor(step),
        );
        expect(state().answers['waist'], NumberAnswer(step.initial));
        expect(state().currentStepId, 'current_training');
      },
    );

    test('a skipped waist leaves the plan complete after save and restore', () {
      controller().start();
      finishQuestions({
        'goal': const ChoiceAnswer('feel_lighter'),
        'waist': const SkippedAnswer(),
      });
      controller().finishBuilding();
      container = createContainer(store: store);

      expect(state().stage, OnboardingStage.plan);
      expect(state().resolution.isComplete, isTrue);
      expect(state().answers['waist'], const SkippedAnswer());
    });

    test('a saved skip on a required step is dropped and revisited', () {
      openWaist();
      final savedAnswers = store.progress!['answers']! as Map<String, Object?>;
      store.progress = {
        ...?store.progress,
        'answers': {...savedAnswers, 'goal': 'skipped'},
      };
      container = createContainer(store: store);

      expect(state().currentStepId, 'goal');
      expect(state().answers, isNot(contains('goal')));
      expect(state().answers, isNot(contains('waist')));
    });
  });

  test('going back keeps the answer she is still on', () {
    controller().start();
    answerAndContinue(const TextAnswer('Layla'));
    answerAndContinue(const ChoiceAnswer('feel_lighter'));
    expect(state().currentStepId, 'lymph_info');

    controller()
      ..backFromStep('lymph_info')
      ..backFromStep('lymph_info'); // A second, stale back is ignored.

    expect(state().currentStepId, 'goal');
    expect(state().answers['goal'], const ChoiceAnswer('feel_lighter'));
  });

  test('closing the app midway resumes exactly where she left off', () {
    controller().start();
    answerAndContinue(const TextAnswer('Layla'));
    answerAndContinue(const ChoiceAnswer('get_back_into_it'));

    // A fresh app session reading the same storage.
    container = createContainer(store: store);

    expect(state().stage, OnboardingStage.questions);
    expect(state().currentStepId, 'last_trained');
    expect(state().answers['name'], const TextAnswer('Layla'));
    expect(state().resumed, isTrue);
  });

  test('progress saved by an older config version is discarded', () {
    controller().start();
    answerAndContinue(const TextAnswer('Layla'));
    store.progress = {...?store.progress, 'configVersion': 0};

    container = createContainer(store: store);

    expect(state().stage, OnboardingStage.welcome);
    expect(state().answers, isEmpty);
  });

  group('editing from the plan', () {
    setUp(() {
      controller().start();
      finishQuestions({'goal': const ChoiceAnswer('build_strength')});
      controller().finishBuilding();
    });

    test('only asks the questions the new answer opens, then returns', () {
      controller().editFromPlan('goal');
      answerAndContinue(const ChoiceAnswer('get_back_into_it'));

      expect(state().currentStepId, 'last_trained');
      answerAndContinue(const ChoiceAnswer('few_months'));
      expect(state().currentStepId, 'stop_reason');
      answerAndContinue(const ChoiceAnswer('busy'));

      expect(state().stage, OnboardingStage.plan);
      expect(state().answers, isNot(contains('current_training')));
      expect(state().answers['last_trained'], const ChoiceAnswer('few_months'));
    });

    test('an edit that closes a branch goes straight back to the plan', () {
      controller().editFromPlan('focus_areas');
      answerAndContinue(MultiChoiceAnswer(const ['arms', 'glutes']));

      expect(state().stage, OnboardingStage.plan);
      expect(
        state().answers['focus_areas'],
        MultiChoiceAnswer(const ['arms', 'glutes']),
      );
    });
  });

  group('grouped pages', () {
    void openWeek() {
      controller().start();
      answerAndContinue(const TextAnswer('Layla'));
      answerAndContinue(const ChoiceAnswer('build_strength'));
    }

    test('Continue needs both answers and skips the whole group once', () {
      openWeek();
      controller()
        ..answerGroup('current_training', {
          'current_training': const ChoiceAnswer('rarely'),
        })
        ..continueGroup('current_training');
      expect(state().currentStepId, 'current_training');
      controller()
        ..answerGroup('current_training', {
          'days_per_week': const NumberAnswer(2),
        })
        ..continueGroup('current_training')
        ..continueGroup('current_training');
      expect(state().currentStepId, 'focus_areas');
      expect(state().answers['days_per_week'], const NumberAnswer(2));
    });

    test('back crosses the whole group and stale page actions are ignored', () {
      openWeek();
      controller()
        ..answerGroup('current_training', {
          'current_training': const ChoiceAnswer('sometimes'),
          'days_per_week': const NumberAnswer(3),
        })
        ..continueGroup('current_training')
        ..answerGroup('current_training', {
          'days_per_week': const NumberAnswer(2),
        })
        ..backFromStep('focus_areas');
      expect(state().currentStepId, 'current_training');
      expect(state().answers['days_per_week'], const NumberAnswer(3));
      controller()
        ..backFromStep('current_training')
        ..backFromStep('current_training');
      expect(state().currentStepId, 'goal');
    });

    test(
      'caps are re-evaluated and group answers cannot touch other pages',
      () {
        openWeek();
        controller().answerGroup('current_training', {
          'current_training': const ChoiceAnswer('regularly'),
          'days_per_week': const NumberAnswer(5),
        });
        controller().answerGroup('current_training', {
          'current_training': const ChoiceAnswer('rarely'),
        });
        expect(state().answers, isNot(contains('days_per_week')));
        controller().answerGroup('current_training', {
          'goal': const ChoiceAnswer('get_back_into_it'),
        });
        expect(state().answers['goal'], const ChoiceAnswer('build_strength'));
      },
    );

    test('progress counts the week once while the engine keeps both steps', () {
      openWeek();
      expect(state().path, hasLength(7));
      expect(state().pageGroups, hasLength(6));
      expect(state().currentPageIndex, 2);
      expect(state().progress, 3 / 7);
    });

    test('saved cursor inside a group resumes at its first question', () {
      openWeek();
      store.progress = {...?store.progress, 'currentStepId': 'days_per_week'};
      container = createContainer(store: store);
      expect(state().currentStepId, 'current_training');
    });

    test('a legacy count answer before the saved cursor is revisited', () {
      controller().start();
      finishQuestions({'goal': const ChoiceAnswer('build_strength')});
      final savedAnswers = store.progress!['answers']! as Map<String, Object?>;
      store.progress = {
        ...?store.progress,
        'stage': 'questions',
        'currentStepId': 'focus_areas',
        'answers': {...savedAnswers, 'days_per_week': 'two'},
      };
      container = createContainer(store: store);
      expect(state().currentStepId, 'current_training');
      expect(state().answers['name'], const TextAnswer('Layla'));
      expect(state().answers, isNot(contains('days_per_week')));
    });

    test(
      'a plan edit to frequency opens the group and returns to the plan',
      () {
        controller().start();
        finishQuestions({'goal': const ChoiceAnswer('build_strength')});
        controller()
          ..finishBuilding()
          ..editFromPlan('days_per_week');
        expect(state().currentStepId, 'current_training');
        controller()
          ..answerGroup('current_training', {
            'days_per_week': const NumberAnswer(2),
          })
          ..continueGroup('current_training');
        expect(state().stage, OnboardingStage.plan);
      },
    );

    test('nonconsecutive week questions retain the comeback path order', () {
      controller().start();
      answerAndContinue(const TextAnswer('Layla'));
      answerAndContinue(const ChoiceAnswer('get_back_into_it'));
      expect(
        state().pageGroups[state().currentPageIndex].steps.map(
          (step) => step.id,
        ),
        ['last_trained'],
      );
      answerAndContinue(const ChoiceAnswer('few_months'));
      expect(state().currentStepId, 'stop_reason');
      answerAndContinue(const ChoiceAnswer('busy'));
      expect(state().currentStepId, 'days_per_week');
      expect(
        state().pageGroups[state().currentPageIndex].steps.map(
          (step) => step.id,
        ),
        ['days_per_week'],
      );
    });
  });

  test('subscribing records the chosen plan and survives a restart', () {
    controller().start();
    finishQuestions();
    controller()
      ..finishBuilding()
      ..openPaywall()
      ..selectPlan('monthly')
      ..subscribe();

    container = createContainer(store: store);

    expect(state().stage, OnboardingStage.subscribed);
    expect(state().subscription?.planId, 'monthly');
  });

  test('the funnel is instrumented', () {
    final events = <TrackedEvent>[];
    container = createContainer(store: store, events: events);

    controller().start();
    answerAndContinue(const TextAnswer('Layla'));

    expect(events.map((e) => e.event), [
      'onboarding_started',
      'step_viewed',
      'step_completed',
      'step_viewed',
    ]);
    expect(events.last.properties, containsPair('step', 'goal'));
  });
}
