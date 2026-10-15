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
      final step = state().resolution.path[state().currentIndex];
      final answer =
          answers[step.id] ??
          switch (step) {
            SingleChoiceStep(:final options) => ChoiceAnswer(options.first.id),
            MultiChoiceStep(:final options) => MultiChoiceAnswer([
              options.first.id,
            ]),
            TextInputStep(kind: TextInputKind.email) => const TextAnswer(
              'layla@example.com',
            ),
            TextInputStep() => const TextAnswer('Layla'),
            InfoStep() => const Acknowledged(),
          };
      answerAndContinue(answer);
    }
  }

  test('starts on the welcome screen, then the first question', () {
    expect(state().stage, OnboardingStage.welcome);

    controller().start();

    expect(state().stage, OnboardingStage.questions);
    expect(state().currentStepId, 'name');
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
      answerAndContinue(MultiChoiceAnswer(['arms', 'glutes']));

      expect(state().stage, OnboardingStage.plan);
      expect(
        state().answers['focus_areas'],
        MultiChoiceAnswer(['arms', 'glutes']),
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
