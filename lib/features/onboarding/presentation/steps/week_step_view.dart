import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/core/design/widgets/primary_button.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/l10n/language_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/controllers/week_step_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/flow_header.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/rhythm_picker.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/routine_selector.dart';

/// The week is a pace she can sustain, rather than a calendar to fill.
class WeekStepView extends ConsumerStatefulWidget {
  const WeekStepView({required this.steps, super.key});

  final List<FlowStep> steps;

  @override
  ConsumerState<WeekStepView> createState() => _WeekStepViewState();
}

class _WeekStepViewState extends ConsumerState<WeekStepView> {
  // The logic lives in WeekStepController; this keeps only the screen's
  // own things: the "you've hit the limit" message and the haptics.
  var _atLimit = false;

  String get _pageId => widget.steps.first.id;

  WeekStepController get _page =>
      ref.read(weekStepControllerProvider(_pageId).notifier);

  void _selectRoutine(SingleChoiceStep step, ChoiceOption option) {
    setState(() => _atLimit = false);
    _page.selectRoutine(step, option);
  }

  void _setCount(int count) {
    switch (_page.setCount(count)) {
      case FrequencyChange.changed:
        HapticFeedback.selectionClick().ignore();
        setState(() => _atLimit = false);
      case FrequencyChange.overLimit:
        HapticFeedback.mediumImpact().ignore();
        setState(() => _atLimit = true);
      case FrequencyChange.ignored:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            widget.steps.first.groupTitle ??
                                widget.steps.first.title,
                            state.answers,
                          ),
                          textAlign: TextAlign.center,
                          style: text.headlineMedium!.copyWith(fontSize: 31),
                        ),
                        const SizedBox(height: 26),
                        for (final step
                            in widget.steps.whereType<SingleChoiceStep>()) ...[
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
                                _selectRoutine(step, option),
                          ),
                        ],
                        if (frequency != null) ...[
                          const SizedBox(height: 8),
                          RhythmPicker(
                            count: count,
                            min: frequency.min,
                            max: max,
                            extent: heroSize,
                            onChanged: _setCount,
                          ),
                          const SizedBox(height: 18),
                          Semantics(
                            liveRegion: true,
                            child: AnimatedSwitcher(
                              duration: duration,
                              child: Text(
                                _atLimit
                                    ? l10n.weekLimit(max)
                                    : frequency
                                              .countCopy(count)
                                              ?.description
                                              .resolve(language) ??
                                          '',
                                key: ValueKey(
                                  '$count:$_atLimit:$language',
                                ),
                                textAlign: TextAlign.center,
                                style: text.bodyMedium!.copyWith(
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ),
                          ),
                        ] else if (widget.steps.first.subtitle
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
                onPressed: page.canContinue ? _page.continuePage : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
