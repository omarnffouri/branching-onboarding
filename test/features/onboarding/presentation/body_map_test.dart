import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traininpink_onboarding/core/design/app_theme.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/choice_step_view.dart';

import '../../../helpers/config_fixtures.dart';
import '../../../helpers/fakes.dart';

void main() {
  setUpAll(() async {
    for (final family in ['Poppins', 'IBMPlexSansArabic']) {
      final loader = FontLoader(family);
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
      }
      await loader.load();
    }
  });

  Future<ProviderContainer> pumpAreas(
    WidgetTester tester, {
    String language = 'en',
  }) async {
    tester.view
      ..physicalSize = const Size(440, 956)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final config = loadBundledConfig();
    final store = InMemoryOnboardingStore()
      ..language = language
      ..progress = {
        'configVersion': config.version,
        'stage': 'questions',
        'currentStepId': 'focus_areas',
        'answers': {
          'name': 'Layla',
          'goal': 'build_strength',
          'current_training': 'sometimes',
          'days_per_week': 3,
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
          home: ChoiceStepView(
            step: config.stepById('focus_areas')! as ChoiceStep,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Iterable<String> selected(ProviderContainer container) => switch (container
      .read(onboardingControllerProvider)
      .answers['focus_areas']) {
    MultiChoiceAnswer(:final optionIds) => optionIds,
    _ => const [],
  };

  /// A point on the figure, in its 200 × 420 design space.
  Future<void> tapFigure(WidgetTester tester, Offset design) async {
    final figure = find.byKey(const ValueKey('body-figure'));
    final box = tester.getRect(figure);
    final scale = [box.width / 200, box.height / 420].reduce(
      (a, b) => a < b ? a : b,
    );
    final origin =
        box.topLeft +
        Offset((box.width - 200 * scale) / 2, (box.height - 420 * scale) / 2);
    await tester.tapAt(origin + design * scale);
    await tester.pumpAndSettle();
  }

  testWidgets('tapping the figure and the chips select the same areas', (
    tester,
  ) async {
    final container = await pumpAreas(tester);
    expect(find.text('Belly & waist'), findsOneWidget);

    await tapFigure(tester, const Offset(100, 190));
    expect(selected(container), ['belly']);

    await tapFigure(tester, const Offset(77, 340));
    expect(selected(container), unorderedEquals(['belly', 'legs']));

    await tester.tap(find.byKey(const ValueKey('body-chip:belly')));
    await tester.pumpAndSettle();
    expect(selected(container), ['legs']);

    // The head is not a focus area.
    await tapFigure(tester, const Offset(100, 38));
    expect(selected(container), ['legs']);

    // Two taps inside one frame both land.
    await tester.tap(find.byKey(const ValueKey('body-chip:arms')));
    await tester.tap(find.byKey(const ValueKey('body-chip:belly')));
    await tester.pumpAndSettle();
    expect(selected(container), unorderedEquals(['legs', 'arms', 'belly']));
    expect(tester.takeException(), isNull);
  });

  testWidgets('picking a hidden area turns her around to show it', (
    tester,
  ) async {
    final container = await pumpAreas(tester);
    await tester.tap(find.byKey(const ValueKey('body-chip:glutes')));
    await tester.pumpAndSettle();
    expect(selected(container), ['glutes']);

    // Now facing the back: the same point is her glutes, not her belly.
    await tapFigure(tester, const Offset(100, 250));
    expect(selected(container), isEmpty);
    await tapFigure(tester, const Offset(100, 150));
    expect(selected(container), ['posture']);

    await tester.tap(find.text('Front'));
    await tester.pumpAndSettle();
    await tapFigure(tester, const Offset(100, 190));
    expect(selected(container), unorderedEquals(['posture', 'belly']));
    expect(tester.takeException(), isNull);
  });

  testWidgets('chips are announced as checkable in Arabic', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpAreas(tester, language: 'ar');
    await tester.tap(find.text('الأرداف'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.byKey(const ValueKey('body-chip:glutes'))),
      matchesSemantics(
        label: 'الأرداف',
        isButton: true,
        hasCheckedState: true,
        isChecked: true,
        hasTapAction: true,
      ),
    );
    expect(tester.takeException(), isNull);
    handle.dispose();
  });
}
