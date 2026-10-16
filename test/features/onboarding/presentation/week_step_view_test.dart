import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/ui/app_theme.dart';
import 'package:traininpink_onboarding/core/ui/widgets/primary_button.dart';
import 'package:traininpink_onboarding/features/onboarding/application/controllers/week_step_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/week_step_view.dart';

import '../../../helpers/config_fixtures.dart';
import '../../../helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    for (final family in ['Poppins', 'IBMPlexSansArabic']) {
      final loader = FontLoader(family);
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
      }
      await loader.load();
    }
  });
  Future<ProviderContainer> pumpWeek(
    WidgetTester tester, {
    String language = 'en',
    String stepId = 'current_training',
    Map<String, Object> answers = const {},
    bool reduceMotion = true,
    Size size = const Size(360, 800),
  }) async {
    tester.view.reset();
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final config = loadBundledConfig();
    final store = InMemoryOnboardingStore()
      ..language = language
      ..progress = {
        'configVersion': config.version,
        'stage': 'questions',
        'currentStepId': stepId,
        'answers': {'name': 'Layla', 'goal': 'build_strength', ...answers},
        'selectedPlanId': 'yearly',
      };
    final container = createContainer(store: store, config: config);
    final state = container.read(onboardingControllerProvider);
    final steps = state.pageGroups[state.currentPageIndex].steps;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.forLanguage(language),
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reduceMotion,
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child!,
          ),
          home: WeekStepView(steps: steps),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  for (final language in ['en', 'ar']) {
    for (final stepId in ['current_training', 'last_trained']) {
      testWidgets('$stepId exposes selectable answers at 1.3x in $language', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        try {
          final container = await pumpWeek(
            tester,
            language: language,
            stepId: stepId,
            size: const Size(320, 740),
            answers: {
              'goal': stepId == 'last_trained'
                  ? 'get_back_into_it'
                  : 'build_strength',
            },
          );
          final step =
              loadBundledConfig().stepById(stepId)! as SingleChoiceStep;
          final options = step.visibleOptions(
            container.read(onboardingControllerProvider).answers,
          );
          Finder option(ChoiceOption option) =>
              find.bySemanticsLabel(option.label.resolve(language));
          final positions = [
            for (final answer in options) tester.getRect(option(answer)),
          ];
          for (final answer in options) {
            final node = tester.getSemantics(option(answer));
            expect(node.flagsCollection.isButton, isTrue);
            expect(node.flagsCollection.isSelected == Tristate.isTrue, isFalse);
            expect(
              node.getSemanticsData().hasAction(SemanticsAction.tap),
              isTrue,
            );
            expect(
              tester.getSize(option(answer)).height,
              greaterThanOrEqualTo(48),
            );
            expect(
              tester.getRect(option(answer)).left,
              greaterThanOrEqualTo(0),
            );
            expect(
              tester.getRect(option(answer)).right,
              lessThanOrEqualTo(320),
            );
          }

          await tester.tap(option(options.first));
          await tester.pumpAndSettle();
          expect(
            tester
                    .getSemantics(option(options.first))
                    .flagsCollection
                    .isSelected ==
                Tristate.isTrue,
            isTrue,
          );
          expect(
            [for (final answer in options) tester.getRect(option(answer))],
            positions,
          );
          await tester.tap(option(options[1]));
          await tester.pumpAndSettle();
          expect(
            tester
                    .getSemantics(option(options.first))
                    .flagsCollection
                    .isSelected ==
                Tristate.isTrue,
            isFalse,
          );
          expect(
            tester
                    .getSemantics(option(options[1]))
                    .flagsCollection
                    .isSelected ==
                Tristate.isTrue,
            isTrue,
          );
          await tester.tap(option(options[1]));
          await tester.pumpAndSettle();
          expect(
            container.read(onboardingControllerProvider).answers[stepId],
            ChoiceAnswer(options[1].id),
          );
          expect(tester.takeException(), isNull);
        } finally {
          handle.dispose();
        }
      });
    }
  }

  testWidgets('routine suggests a count and plus respects the cap', (
    tester,
  ) async {
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final container = await pumpWeek(tester);
    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text('Sometimes'));
    await tester.pumpAndSettle();
    expect(
      container.read(onboardingControllerProvider).answers['days_per_week'],
      const NumberAnswer(3),
    );
    expect(find.text('A little consistency goes a long way.'), findsOneWidget);
    await tester.ensureVisible(find.byIcon(Icons.add_rounded));
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(
      container.read(onboardingControllerProvider).answers['days_per_week'],
      const NumberAnswer(4),
    );
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(
      find.text("Let's start with 4 sessions. You can add more later."),
      findsOneWidget,
    );
    expect(
      container.read(onboardingControllerProvider).answers['days_per_week'],
      const NumberAnswer(4),
    );
    expect(haptics, contains('HapticFeedbackType.mediumImpact'));
    expect(haptics, contains('HapticFeedbackType.selectionClick'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping adjusts frequency and Continue completes the group', (
    tester,
  ) async {
    final container = await pumpWeek(tester);
    await tester.tap(find.text('Sometimes'));
    await tester.pumpAndSettle();
    final picker = find.byKey(const ValueKey('rhythm-picker'));
    await tester.ensureVisible(picker);
    await tester.drag(picker, const Offset(-70, 0));
    await tester.pumpAndSettle();
    expect(
      container.read(onboardingControllerProvider).answers['days_per_week'],
      const NumberAnswer(2),
    );
    await tester.tap(find.text('This feels right'));
    await tester.pumpAndSettle();
    expect(
      container.read(onboardingControllerProvider).currentStepId,
      'focus_areas',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic exposes the count as an adjustable slider at 1.3x', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final container = await pumpWeek(tester, language: 'ar');
    await tester.tap(find.text('أحياناً'));
    await tester.pumpAndSettle();
    final picker = find.byKey(const ValueKey('rhythm-picker'));
    await tester.ensureVisible(picker);
    expect(Directionality.of(tester.element(picker)), TextDirection.rtl);
    final semantics = find
        .ancestor(of: picker, matching: find.byType(Semantics))
        .first;
    expect(
      tester.getSemantics(semantics),
      matchesSemantics(
        label: 'اكتشفي إيقاعكِ',
        value: '3 جلسات في الأسبوع',
        increasedValue: '4 جلسات في الأسبوع',
        decreasedValue: '2 جلسات في الأسبوع',
        hint: 'اسحبي لتختاري إيقاعكِ',
        isSlider: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
    await tester.drag(picker, const Offset(-70, 0));
    await tester.pumpAndSettle();
    expect(
      container.read(onboardingControllerProvider).answers['days_per_week'],
      const NumberAnswer(4),
    );
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('routine changes replace the suggestion and motion settles', (
    tester,
  ) async {
    final container = await pumpWeek(tester, reduceMotion: false);
    await tester.tap(find.text('Regularly'));
    await tester.pumpAndSettle();
    expect(
      container.read(onboardingControllerProvider).answers['days_per_week'],
      const NumberAnswer(4),
    );
    await tester.tap(find.text('Just starting'));
    await tester.pumpAndSettle();
    expect(
      container.read(onboardingControllerProvider).answers['days_per_week'],
      const NumberAnswer(2),
    );
    expect(find.byKey(const ValueKey('rhythm-count:2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved weekday answers retain only their session count', (
    tester,
  ) async {
    final container = await pumpWeek(
      tester,
      answers: const {
        'current_training': 'regularly',
        'days_per_week': [0, 2, 4, 6],
      },
    );
    expect(
      container.read(onboardingControllerProvider).answers['days_per_week'],
      const NumberAnswer(4),
    );
    expect(find.byKey(const ValueKey('rhythm-count:4')), findsOneWidget);
    expect(find.text('Sun'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the comeback frequency uses the earlier training answer', (
    tester,
  ) async {
    final container = await pumpWeek(
      tester,
      stepId: 'days_per_week',
      answers: const {
        'goal': 'get_back_into_it',
        'last_trained': 'few_weeks',
        'stop_reason': 'busy',
      },
    );
    expect(find.text('Right now, I’m…'), findsNothing);
    // The suggestion for her comeback is shown straight away…
    expect(
      container.read(weekStepControllerProvider('days_per_week')).count,
      3,
    );
    // …and saved as her answer when she continues with it.
    container
        .read(weekStepControllerProvider('days_per_week').notifier)
        .continuePage();
    expect(
      container.read(onboardingControllerProvider).answers['days_per_week'],
      const NumberAnswer(3),
    );
    expect(tester.takeException(), isNull);
  });
}
