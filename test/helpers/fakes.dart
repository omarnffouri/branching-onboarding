import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/data/onboarding_store.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

import 'config_fixtures.dart';

final class InMemoryOnboardingStore implements OnboardingStore {
  Map<String, Object?>? progress;
  String? language;

  @override
  Map<String, Object?>? readProgress() => progress;

  @override
  Future<void> writeProgress(Map<String, Object?> progress) async =>
      this.progress = progress;

  @override
  Future<void> clearProgress() async => progress = null;

  @override
  String? readLanguage() => language;

  @override
  Future<void> writeLanguage(String languageCode) async =>
      language = languageCode;
}

typedef TrackedEvent = ({String event, Map<String, Object?> properties});

/// A container wired like the app, with fakes at the edges.
ProviderContainer createContainer({
  required OnboardingStore store,
  FlowConfig? config,
  List<TrackedEvent>? events,
}) {
  final container = ProviderContainer(
    overrides: [
      flowConfigProvider.overrideWithValue(config ?? loadBundledConfig()),
      onboardingStoreProvider.overrideWithValue(store),
      onboardingAnalyticsProvider.overrideWithValue(
        (event, properties) =>
            events?.add((event: event, properties: properties)),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}
