import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/core/design/widgets/pressable.dart';
import 'package:traininpink_onboarding/core/design/widgets/primary_button.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/l10n/language_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/flow_header.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/rhythm_picker.dart';

/// The week is a pace she can sustain, rather than a calendar to fill.
class WeekStepView extends ConsumerStatefulWidget {
  const WeekStepView({required this.steps, super.key});

  final List<FlowStep> steps;

  @override
  ConsumerState<WeekStepView> createState() => _WeekStepViewState();
}

class _WeekStepViewState extends ConsumerState<WeekStepView> {
  var _atLimit = false;

  FrequencyStep? get _frequency =>
      widget.steps.whereType<FrequencyStep>().firstOrNull;
  String get _pageId => widget.steps.first.id;
  OnboardingController get _controller =>
      ref.read(onboardingControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final step = _frequency;
      final state = ref.read(onboardingControllerProvider);
      if (step == null ||
          state.currentStepId != _pageId ||
          state.answers.containsKey(step.id)) {
        return;
      }
      final suggested = step.suggestionFor(state.answers);
      if (suggested != null) {
        _controller.answerGroup(_pageId, {step.id: NumberAnswer(suggested)});
      }
    });
  }

  void _selectRoutine(SingleChoiceStep step, ChoiceOption option) {
    final state = ref.read(onboardingControllerProvider);
    if (state.answers[step.id] == ChoiceAnswer(option.id)) return;
    final answers = <String, Answer>{step.id: ChoiceAnswer(option.id)};
    final frequency = _frequency;
    final suggested = frequency?.suggestionFor({...state.answers, ...answers});
    setState(() => _atLimit = false);
    _controller.answerGroup(_pageId, {
      ...answers,
      if (frequency != null && suggested != null)
        frequency.id: NumberAnswer(suggested),
    });
  }

  void _setCount(int count) {
    final step = _frequency!;
    final answers = ref.read(onboardingControllerProvider).answers;
    if (count > step.allowedMax(answers)) {
      setState(() => _atLimit = true);
      HapticFeedback.mediumImpact().ignore();
      return;
    }
    if (count < step.min) return;
    HapticFeedback.selectionClick().ignore();
    setState(() => _atLimit = false);
    _controller.answerGroup(_pageId, {step.id: NumberAnswer(count)});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final language = ref.watch(languageProvider);
    final formatter = ref.watch(answerFormatterProvider);
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final frequency = _frequency;
    final count = switch (state.answers[frequency?.id]) {
      NumberAnswer(:final value) => value,
      _ => frequency?.suggestionFor(state.answers) ?? frequency?.min ?? 2,
    };
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.medium;
    final canContinue = widget.steps.every(
      (step) => state.resolution.isAnswered(step.id),
    );

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
                          _RoutineWords(
                            options: step.visibleOptions(state.answers),
                            selected: switch (state.answers[step.id]) {
                              ChoiceAnswer(:final optionId) => optionId,
                              _ => null,
                            },
                            language: language,
                            duration: duration,
                            onSelected: (option) =>
                                _selectRoutine(step, option),
                          ),
                        ],
                        if (frequency != null) ...[
                          const SizedBox(height: 8),
                          RhythmPicker(
                            count: count,
                            min: frequency.min,
                            max: frequency.allowedMax(state.answers),
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
                                    ? l10n.weekLimit(
                                        frequency.allowedMax(state.answers),
                                      )
                                    : frequency
                                              .countCopy(count)
                                              ?.description
                                              .resolve(language) ??
                                          '',
                                key: ValueKey('$count:$_atLimit:$language'),
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
                onPressed: canContinue
                    ? () => _controller.continueGroup(_pageId)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineWords extends StatelessWidget {
  const _RoutineWords({
    required this.options,
    required this.selected,
    required this.language,
    required this.duration,
    required this.onSelected,
  });

  final List<ChoiceOption> options;
  final String? selected;
  final String language;
  final Duration duration;
  final ValueChanged<ChoiceOption> onSelected;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in options)
          Expanded(
            child: Semantics(
              button: true,
              selected: option.id == selected,
              inMutuallyExclusiveGroup: true,
              child: Pressable(
                onTap: () => onSelected(option),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(3, 12, 3, 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: duration,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: option.id == selected
                              ? AppColors.primaryDeep
                              : AppColors.inkMuted,
                          fontWeight: option.id == selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        child: Text(option.label.resolve(language)),
                      ),
                      const SizedBox(height: 10),
                      AnimatedContainer(
                        duration: duration,
                        height: 2,
                        width: option.id == selected ? 26 : 0,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
