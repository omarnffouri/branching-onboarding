import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traininpink_onboarding/features/onboarding/application/controllers/text_step_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

import '../../../../helpers/config_fixtures.dart';
import '../../../../helpers/fakes.dart';

void main() {
  late ProviderContainer container;

  /// Opens the app on [stepId] with [answers] already given.
  void openOn(String stepId, [Map<String, Object?> answers = const {}]) {
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
    )..listen(textStepControllerProvider(stepId), (_, _) {});
  }

  TextStepController page(String stepId) =>
      container.read(textStepControllerProvider(stepId).notifier);
  TextStepState text(String stepId) =>
      container.read(textStepControllerProvider(stepId));
  String? currentStep() =>
      container.read(onboardingControllerProvider).currentStepId;
  Answer? saved(String stepId) =>
      container.read(onboardingControllerProvider).answers[stepId];

  /// Walks the real flow from the start to the email step, answering every
  /// question on the way, so the flow is genuinely on that step.
  void openOnEmail() {
    openOn('name');
    final flow = container.read(onboardingControllerProvider.notifier);
    while (currentStep() != 'email') {
      final state = container.read(onboardingControllerProvider);
      final pageId = state.currentStepId!;
      for (final step in state.pageGroups[state.currentPageIndex].steps) {
        final answer = switch (step) {
          SingleChoiceStep(:final options) => ChoiceAnswer(options.first.id),
          MultiChoiceStep(:final options) => MultiChoiceAnswer([
            options.first.id,
          ]),
          TextInputStep() => const TextAnswer('Layla'),
          NumberStep(:final initial) => NumberAnswer(initial),
          FrequencyStep(:final min) => NumberAnswer(min),
          InfoStep() => const Acknowledged(),
        };
        flow.answerGroup(pageId, {step.id: answer});
      }
      flow.continueGroup(pageId);
    }
    container.listen(textStepControllerProvider('email'), (_, _) {});
  }

  test('a new step starts empty; coming back shows what she typed', () {
    openOn('name');
    expect(text('name').input, '');
    expect(text('name').status.canContinue, isFalse);

    openOn('name', {'name': 'Layla'});
    expect(text('name').input, 'Layla');
  });

  test('a valid value is saved to the flow as she types', () {
    openOn('name');

    page('name').changed('  Layla ');

    expect(saved('name'), const TextAnswer('Layla'));
  });

  test('making the value invalid clears the saved answer', () {
    openOnEmail();
    page('email').changed('layla@example.com');
    expect(saved('email'), isNotNull);

    page('email').changed('layla@');

    expect(saved('email'), isNull);
  });

  test('a valid submit moves on', () {
    openOn('name');
    page('name').changed('Layla');

    expect(page('name').submit(), isTrue);
    expect(currentStep(), 'goal');
  });

  test('an invalid submit stays and shows the error', () {
    openOnEmail();
    page('email').changed('layla@');

    expect(page('email').submit(), isFalse);
    expect(currentStep(), 'email');
    expect(text('email').status.showError, isTrue);
  });

  test('fixing the value clears the error straight away', () {
    openOnEmail();
    page('email')
      ..changed('layla@')
      ..submit()
      ..changed('layla@example.com');

    expect(text('email').status.showError, isFalse);
  });

  test('a second tap after moving on is not a rejection', () {
    openOn('name');
    page('name').changed('Layla');
    page('name').submit();

    expect(page('name').submit(), isTrue);
    expect(currentStep(), 'goal');
  });
}
