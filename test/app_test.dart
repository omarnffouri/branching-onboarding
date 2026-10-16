import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traininpink_onboarding/app.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/config_icons.dart';

import 'helpers/config_fixtures.dart';
import 'helpers/fakes.dart';

void main() {
  final config = loadBundledConfig();

  Future<void> pumpApp(WidgetTester tester, InMemoryOnboardingStore store) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [
            flowConfigProvider.overrideWithValue(config),
            onboardingStoreProvider.overrideWithValue(store),
            onboardingAnalyticsProvider.overrideWithValue((_, _) {}),
          ],
          child: const TraininpinkApp(),
        ),
      );

  testWidgets('welcome leads into the first question', (tester) async {
    await pumpApp(tester, InMemoryOnboardingStore()..language = 'en');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Build my plan'));
    // The name screen has gently looping motion, so it never "settles".
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.text('First things first. What should we call you?'),
      findsOneWidget,
    );
  });

  testWidgets('Arabic lays the whole app out right to left', (tester) async {
    await pumpApp(tester, InMemoryOnboardingStore()..language = 'ar');
    await tester.pumpAndSettle();

    final title = find.text('صمّمي خطتي');
    expect(title, findsOneWidget);
    expect(Directionality.of(tester.element(title)), TextDirection.rtl);
  });

  testWidgets('a member who left mid-flow is greeted and resumes', (
    tester,
  ) async {
    final store = InMemoryOnboardingStore()
      ..language = 'en'
      ..progress = {
        'configVersion': config.version,
        'stage': 'questions',
        'currentStepId': 'goal',
        'answers': {'name': 'Layla'},
        'selectedPlanId': 'yearly',
      };
    await pumpApp(tester, store);
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    expect(find.text('Welcome back, Layla'), findsOneWidget);
    expect(
      find.text('Nice to meet you, Layla. What brings you here?'),
      findsOneWidget,
    );

    // Let the banner dismiss itself.
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  test('every icon the config names exists in the app', () {
    final names = <String?>[
      for (final step in config.steps)
        if (step is InfoStep) ...[
          step.icon,
          for (final point in step.points) point.icon,
        ],
      for (final stat in config.plan.stats) stat.icon,
      for (final highlight in config.plan.highlights) highlight.icon,
    ].nonNulls;

    for (final name in names) {
      expect(configIcons, contains(name), reason: 'unknown icon "$name"');
    }
  });

  test('every image the config names is bundled', () {
    for (final step in config.steps) {
      if (step.image case final image?) {
        expect(
          File('assets/images/steps/$image').existsSync(),
          isTrue,
          reason: '${step.id} uses missing image $image',
        );
      }
    }
  });
}
