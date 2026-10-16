import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/ui/app_theme.dart';
import 'package:traininpink_onboarding/core/ui/widgets/primary_button.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_state.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/text_step_view.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/member_card.dart';
import 'package:traininpink_onboarding/features/paywall/presentation/success_screen.dart';

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

  Widget host(
    ProviderContainer container,
    Widget home, {
    String language = 'en',
    double textScale = 1,
  }) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.forLanguage(language),
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: true,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: home,
    ),
  );

  Future<ProviderContainer> pumpStep(
    WidgetTester tester, {
    String stepId = 'email',
    String language = 'en',
    String? email,
    double textScale = 1,
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
        'currentStepId': stepId,
        'answers': {
          if (stepId != 'name') ...{
            'name': language == 'ar' ? 'ليلى' : 'Layla',
            'goal': 'build_strength',
            'current_training': 'regularly',
            'days_per_week': 3,
            'focus_areas': ['arms'],
            'session_length': 'twenty',
          },
          'email': ?email,
        },
        'selectedPlanId': 'yearly',
      };
    final container = createContainer(store: store, config: config);
    await tester.pumpWidget(
      host(
        container,
        TextStepView(step: config.stepById(stepId)! as TextInputStep),
        language: language,
        textScale: textScale,
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  MemberCard card(WidgetTester tester) =>
      tester.widget<MemberCard>(find.byType(MemberCard));

  testWidgets('name still updates the member card and saves on continue', (
    tester,
  ) async {
    final container = await pumpStep(tester, stepId: 'name');
    await tester.enterText(find.byType(TextField), 'Noura');
    await tester.pumpAndSettle();
    expect(card(tester).name, 'Noura');
    expect(card(tester).email, isNull);
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(container.read(onboardingControllerProvider).currentStepId, 'goal');
    expect(tester.takeException(), isNull);
  });

  testWidgets('email previews live and invalid edits clear a saved address', (
    tester,
  ) async {
    final container = await pumpStep(tester, email: 'layla@example.com');
    expect(card(tester).name, 'Layla');
    expect(card(tester).email, 'layla@example.com');

    await tester.enterText(find.byType(TextField), 'layla@');
    await tester.pumpAndSettle();
    expect(card(tester).email, 'layla@');
    expect(
      container.read(onboardingControllerProvider).answers['email'],
      isNull,
    );
    expect(find.text('Please enter a valid email address.'), findsNothing);

    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(TextField)));
    expect(find.text(l10n.emailInvalid), findsOneWidget);
    expect(container.read(onboardingControllerProvider).currentStepId, 'email');

    await tester.enterText(find.byType(TextField), 'noura@example.com');
    await tester.pumpAndSettle();
    expect(find.text(l10n.emailInvalid), findsNothing);
    expect(card(tester).email, 'noura@example.com');
    expect(tester.takeException(), isNull);
  });

  testWidgets('domain correction updates the card and completed membership', (
    tester,
  ) async {
    final container = await pumpStep(tester);
    await tester.enterText(find.byType(TextField), 'layla@gmial.com');
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(find.byType(TextField)));
    await tester.ensureVisible(find.text(l10n.emailUseSuggestion));
    await tester.tap(find.text(l10n.emailUseSuggestion));
    await tester.pumpAndSettle();
    expect(card(tester).email, 'layla@gmail.com');
    expect(
      container.read(onboardingControllerProvider).answers['email'],
      const TextAnswer('layla@gmail.com'),
    );
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(
      container.read(onboardingControllerProvider).stage,
      OnboardingStage.building,
    );
    container.read(onboardingControllerProvider.notifier)
      ..finishBuilding()
      ..openPaywall()
      ..subscribe();
    await tester.pumpWidget(host(container, const SuccessScreen()));
    await tester.pumpAndSettle();
    expect(card(tester).email, 'layla@gmail.com');
    expect(card(tester).active, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final language in ['en', 'ar']) {
    testWidgets('email remains LTR with the keyboard at 1.3x in $language', (
      tester,
    ) async {
      await pumpStep(tester, language: language, textScale: 1.3);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      const email = 'layla.long.email.address@example.com';
      await tester.enterText(find.byType(TextField), email);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textDirection, TextDirection.ltr);
      expect(field.keyboardType, TextInputType.emailAddress);
      expect(field.autofillHints, [AutofillHints.email]);
      final cardEmail = find.descendant(
        of: find.byType(MemberCard),
        matching: find.text(email),
      );
      expect(tester.widget<Text>(cardEmail).textDirection, TextDirection.ltr);
      expect(
        tester.getBottomLeft(find.byType(TextField)).dy,
        lessThan(tester.getTopLeft(find.byType(PrimaryButton)).dy),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
