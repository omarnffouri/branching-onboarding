import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traininpink_onboarding/core/design/app_theme.dart';
import 'package:traininpink_onboarding/core/design/widgets/primary_button.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/screens/onboarding_flow.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/screens/plan_screen.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/tape_step_view.dart';

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

  Future<ProviderContainer> pumpWaist(
    WidgetTester tester, {
    String language = 'en',
    Answer waist = const NumberAnswer(82),
    bool optional = true,
  }) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final config = loadBundledConfig();
    final store = InMemoryOnboardingStore()
      ..language = language
      ..progress = {
        'configVersion': config.version,
        'stage': 'questions',
        'currentStepId': 'waist',
        'answers': {
          'name': language == 'ar' ? 'ليلى' : 'Layla',
          'goal': 'feel_lighter',
          'lymph_info': true,
          'waist': waist.toJson(),
          'current_training': 'sometimes',
          'days_per_week': 3,
          'focus_areas': ['belly'],
          'session_length': 'twenty',
          'email': 'layla@example.com',
        },
        'selectedPlanId': 'yearly',
      };
    final container = createContainer(store: store, config: config);
    container
        .read(onboardingControllerProvider.notifier)
        .dismissResumeGreeting();
    final step = config.stepById('waist')! as NumberStep;
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
              disableAnimations: true,
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child!,
          ),
          home: optional
              ? const OnboardingFlow()
              : TapeStepView(
                  step: NumberStep(
                    id: step.id,
                    title: step.title,
                    unit: step.unit,
                    min: step.min,
                    max: step.max,
                    initial: step.initial,
                  ),
                ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('required number questions do not offer a skip', (tester) async {
    await pumpWaist(tester, optional: false);
    expect(find.text("I'm not sure, skip"), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['en', 'ar']) {
    testWidgets('$language skip has an accessible 44px target under the hint', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
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
      final container = await pumpWaist(tester, language: language);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(TapeStepView)),
      );
      final skip = find.bySemanticsLabel(l10n.skipQuestion);
      expect(
        tester.getSemantics(skip),
        matchesSemantics(
          label: l10n.skipQuestion,
          isButton: true,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
      expect(tester.getSize(skip).height, greaterThanOrEqualTo(44));
      expect(
        tester.getTopLeft(skip).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(find.text(l10n.tapeHint)).dy),
      );
      expect(
        tester.getBottomLeft(skip).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(PrimaryButton)).dy),
      );

      await tester.drag(find.byType(TapeStepView), const Offset(-180, 0));
      await tester.pumpAndSettle();
      expect(
        container.read(onboardingControllerProvider).answers['waist'],
        isNot(const NumberAnswer(82)),
      );
      await tester.tap(skip);
      await tester.tap(skip);
      await tester.pumpAndSettle();
      expect(
        container.read(onboardingControllerProvider).currentStepId,
        'current_training',
      );
      expect(
        container.read(onboardingControllerProvider).answers['waist'],
        const SkippedAnswer(),
      );
      expect(haptics, contains('HapticFeedbackType.lightImpact'));

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      final step = loadBundledConfig().stepById('waist')! as NumberStep;
      expect(find.text('${step.initial}'), findsOneWidget);
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();
      expect(
        container.read(onboardingControllerProvider).answers['waist'],
        NumberAnswer(step.initial),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a restored skip previews initial and Continue saves a number', (
    tester,
  ) async {
    final container = await pumpWaist(tester, waist: const SkippedAnswer());
    final step = loadBundledConfig().stepById('waist')! as NumberStep;
    expect(find.text('${step.initial}'), findsOneWidget);
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(
      container.read(onboardingControllerProvider).answers['waist'],
      NumberAnswer(step.initial),
    );
    expect(tester.takeException(), isNull);
  });

  for (final skipped in [true, false]) {
    testWidgets(
      'plan screen shows waist details only when measured ($skipped)',
      (
        tester,
      ) async {
        final container = await pumpWaist(tester);
        await tester.tap(
          skipped
              ? find.text("I'm not sure, skip")
              : find.byType(PrimaryButton),
        );
        await tester.pumpAndSettle();
        container.read(onboardingControllerProvider.notifier)
          ..continueFrom('current_training')
          ..continueFrom('focus_areas')
          ..continueFrom('session_length')
          ..continueFrom('email')
          ..finishBuilding();
        await tester.pumpAndSettle();
        expect(find.byType(PlanScreen), findsOneWidget);
        final scrollable = find.descendant(
          of: find.byType(PlanScreen),
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(
          find.text('Lymphatic flow sessions'),
          250,
          scrollable: scrollable,
        );
        if (!skipped) {
          await tester.scrollUntilVisible(
            find.text("We'll track your waist, starting at 82 cm"),
            250,
            scrollable: scrollable,
          );
        }
        expect(
          find.text("We'll track your waist, starting at 82 cm"),
          skipped ? findsNothing : findsOneWidget,
        );
        await tester.scrollUntilVisible(
          find.text('Email'),
          250,
          scrollable: scrollable,
        );
        expect(find.text('Waist'), skipped ? findsNothing : findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
