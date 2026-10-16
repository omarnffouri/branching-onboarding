import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/l10n/language_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/data/onboarding_store.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer_formatter.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

/// Loaded and validated in `main` before the first frame, so the UI never
/// renders a loading state for something that takes milliseconds.
final flowConfigProvider = Provider<FlowConfig>(
  (ref) => throw UnimplementedError('Override flowConfigProvider in main'),
);

final onboardingStoreProvider = Provider<OnboardingStore>(
  (ref) => throw UnimplementedError('Override onboardingStoreProvider in main'),
);

/// Fills `{step}` placeholders in config copy, in the current language.
final answerFormatterProvider = Provider<AnswerFormatter>(
  (ref) => AnswerFormatter(
    ref.watch(flowConfigProvider),
    ref.watch(languageProvider),
  ),
);
