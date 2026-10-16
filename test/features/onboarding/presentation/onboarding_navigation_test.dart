import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traininpink_onboarding/app.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_state.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';

import '../../../helpers/config_fixtures.dart';
import '../../../helpers/fakes.dart';

void main() {
  Future<ProviderContainer> pumpFlow(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(440, 956)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final config = loadBundledConfig();
    final store = InMemoryOnboardingStore()
      ..language = 'en'
      ..progress = {
        'configVersion': config.version,
        'stage': 'questions',
        'currentStepId': 'waist',
        'answers': {
          'name': 'Layla',
          'goal': 'feel_lighter',
          'lymph_info': true,
          'waist': 78,
          'current_training': 'sometimes',
          'days_per_week': 3,
        },
        'selectedPlanId': 'yearly',
      };
    final container = createContainer(store: store, config: config);
    container
        .read(onboardingControllerProvider.notifier)
        .dismissResumeGreeting();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TraininpinkApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  OnboardingState state(ProviderContainer container) =>
      container.read(onboardingControllerProvider);

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'repeated waist, rhythm and focus navigation disposes listeners',
    (tester) async {
      final container = await pumpFlow(tester);
      for (var round = 0; round < 8; round++) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(state(container).currentStepId, 'current_training');
        for (final label in ['Just starting', 'Sometimes', 'Regularly']) {
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('This feels right'));
        await tester.pumpAndSettle();
        expect(state(container).currentStepId, 'focus_areas');
        await back(tester);
        expect(state(container).currentStepId, 'current_training');
        await back(tester);
        expect(state(container).currentStepId, 'waist');
        expect(tester.takeException(), isNull);
      }
      expect(state(container).answers['days_per_week'], const NumberAnswer(4));
    },
  );

  testWidgets('edge swipes and re-entry during reverse transitions are safe', (
    tester,
  ) async {
    final container = await pumpFlow(tester);
    for (var round = 0; round < 8; round++) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(state(container).currentStepId, 'current_training');
      await tester.timedDragFrom(
        const Offset(2, 450),
        const Offset(390, 0),
        const Duration(milliseconds: 250),
      );
      await tester.pumpAndSettle();
      expect(state(container).currentStepId, 'waist');
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      container
          .read(onboardingControllerProvider.notifier)
          .backFromStep('current_training');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      container
          .read(onboardingControllerProvider.notifier)
          .continueFrom('waist');
      await tester.pumpAndSettle();
      expect(state(container).currentStepId, 'current_training');
      await back(tester);
      expect(tester.takeException(), isNull);
    }
  });
}
