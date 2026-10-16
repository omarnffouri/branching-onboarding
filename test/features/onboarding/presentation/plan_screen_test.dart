import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/ui/app_theme.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/screens/plan_screen.dart';

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

  for (final language in ['en', 'ar']) {
    testWidgets('weekly session counts fit in the $language plan at 1.3x', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(320, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final config = loadBundledConfig();
      final store = InMemoryOnboardingStore()
        ..language = language
        ..progress = {
          'configVersion': config.version,
          'stage': 'plan',
          'currentStepId': 'email',
          'answers': {
            'name': 'Layla',
            'goal': 'build_strength',
            'current_training': 'regularly',
            'days_per_week': 5,
            'focus_areas': ['arms'],
            'session_length': 'twenty',
            'email': 'layla@example.com',
          },
          'selectedPlanId': 'yearly',
        };
      final container = createContainer(store: store, config: config);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.forLanguage(language),
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: const PlanScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          language == 'en' ? '5 sessions a week' : '5 جلسات أسبوعياً',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
