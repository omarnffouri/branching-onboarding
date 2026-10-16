import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/l10n/language_controller.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';
import 'package:traininpink_onboarding/core/ui/widgets/primary_button.dart';
import 'package:traininpink_onboarding/features/onboarding/application/controllers/week_step_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/flow_header.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/rhythm_picker.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/routine_selector.dart';

/// The week is a pace she can sustain, rather than a calendar to fill.
///
/// Everything lives in WeekStepController; this only lays the page out.
class WeekStepView extends ConsumerWidget {
  const WeekStepView({required this.steps, super.key});

  final List<FlowStep> steps;

  String get _pageId => steps.first.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(weekStepControllerProvider(_pageId).notifier);
    final state = ref.watch(onboardingControllerProvider);
    final language = ref.watch(languageProvider);
    final formatter = ref.watch(answerFormatterProvider);
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final page = ref.watch(weekStepControllerProvider(_pageId));
    final frequency = page.frequency;
    final count = page.count;
    final max = page.max;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.medium;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final header = FlowHeader.extentOf(context);
                  final heroSize = math.min(
                    constraints.maxWidth - AppSpacing.page * 2,
                    (constraints.maxHeight - header - 365).clamp(220.0, 308.0),
                  );
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      header + 14,
                      AppSpacing.page,
                      16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.weekEyebrow,
                          textAlign: TextAlign.center,
                          style: text.labelSmall!.copyWith(
                            color: AppColors.primary,
                            letterSpacing: language == 'ar' ? 0 : 2.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          formatter.fill(
                            steps.first.groupTitle ?? steps.first.title,
                            state.answers,
                          ),
                          textAlign: TextAlign.center,
                          style: text.headlineMedium!.copyWith(fontSize: 31),
                        ),
                        const SizedBox(height: 26),
                        for (final step
                            in steps.whereType<SingleChoiceStep>()) ...[
                          Text(
                            formatter.fill(step.title, state.answers),
                            textAlign: TextAlign.center,
                            style: text.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          RoutineSelector(
                            options: step.visibleOptions(state.answers),
                            selected: switch (state.answers[step.id]) {
                              ChoiceAnswer(:final optionId) => optionId,
                              _ => null,
                            },
                            language: language,
                            onSelected: (option) =>
                                controller.selectRoutine(step, option),
                          ),
                        ],
                        if (frequency != null) ...[
                          const SizedBox(height: 8),
                          RhythmPicker(
                            count: count,
                            min: frequency.min,
                            max: max,
                            extent: heroSize,
                            onChanged: controller.setCount,
                          ),
                          const SizedBox(height: 18),
                          Semantics(
                            liveRegion: true,
                            child: AnimatedSwitcher(
                              duration: duration,
                              child: Text(
                                page.atLimit
                                    ? l10n.weekLimit(max)
                                    : frequency
                                              .countCopy(count)
                                              ?.description
                                              .resolve(language) ??
                                          '',
                                key: ValueKey(
                                  '$count:${page.atLimit}:$language',
                                ),
                                textAlign: TextAlign.center,
                                style: text.bodyMedium!.copyWith(
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ),
                          ),
                        ] else if (steps.first.subtitle
                            case final subtitle?) ...[
                          const SizedBox(height: 24),
                          Text(
                            subtitle.resolve(language),
                            textAlign: TextAlign.center,
                            style: text.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                8,
                AppSpacing.page,
                16,
              ),
              child: PrimaryButton(
                label: l10n.rhythmCta,
                onPressed: page.canContinue ? controller.continuePage : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
