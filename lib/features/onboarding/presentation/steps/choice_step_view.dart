import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/core/design/widgets/choice_card.dart';
import 'package:traininpink_onboarding/core/design/widgets/entrance.dart';
import 'package:traininpink_onboarding/core/design/widgets/primary_button.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/l10n/language_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/step_hero.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/step_layout.dart';

/// Single choice moves on by itself a beat after she taps, like the
/// Traininpink app. Multi choice waits for Continue.
class ChoiceStepView extends ConsumerStatefulWidget {
  const ChoiceStepView({required this.step, super.key});

  final ChoiceStep step;

  @override
  ConsumerState<ChoiceStepView> createState() => _ChoiceStepViewState();
}

class _ChoiceStepViewState extends ConsumerState<ChoiceStepView> {
  Timer? _advance;

  /// Coming back to a step she already answered shows Continue, so she can
  /// move on without re-tapping her answer. A first visit has none: a tap
  /// is the answer.
  late bool _showContinue = ref
      .read(onboardingControllerProvider)
      .resolution
      .isAnswered(widget.step.id);

  OnboardingController get _controller =>
      ref.read(onboardingControllerProvider.notifier);

  @override
  void dispose() {
    _advance?.cancel();
    super.dispose();
  }

  void _onTap(ChoiceOption option, Answer? current) {
    final stepId = widget.step.id;
    switch (widget.step) {
      case SingleChoiceStep():
        _controller.answer(stepId, ChoiceAnswer(option.id));
        _advance?.cancel();
        _advance = Timer(
          MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppMotion.selectionBeat,
          () => _controller.continueFrom(stepId),
        );
      case MultiChoiceStep():
        final selected = {
          if (current case MultiChoiceAnswer(:final optionIds)) ...optionIds,
        };
        if (!selected.remove(option.id)) selected.add(option.id);
        _controller.answer(stepId, MultiChoiceAnswer(selected));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageProvider);
    final formatter = ref.watch(answerFormatterProvider);
    final state = ref.watch(onboardingControllerProvider);
    final step = widget.step;
    final current = state.answers[step.id];
    final isMulti = step is MultiChoiceStep;

    bool isSelected(ChoiceOption option) => switch (current) {
      ChoiceAnswer(:final optionId) => optionId == option.id,
      MultiChoiceAnswer(:final optionIds) => optionIds.contains(option.id),
      _ => false,
    };

    final selectedCount = switch (current) {
      MultiChoiceAnswer(:final optionIds) => optionIds.length,
      ChoiceAnswer() => 1,
      _ => 0,
    };
    final canContinue = state.resolution.isAnswered(step.id);

    // This page stays alive underneath later steps, so "coming back" is the
    // moment it becomes current again, not when it is first built.
    ref.listen(
      onboardingControllerProvider.select((state) => state.currentStepId),
      (previous, next) {
        if (next == step.id && previous != next && canContinue) {
          setState(() => _showContinue = true);
        }
      },
    );

    return StepLayout(
      hero: switch (step.image) {
        final image? => StepHero(
          image: image,
          focus: Alignment(step.imageFocus.x, step.imageFocus.y),
        ),
        null => null,
      },
      title: formatter.fill(step.title, state.answers),
      subtitle: step.subtitle?.resolve(language),
      footer: isMulti || _showContinue
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMulti)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AnimatedSwitcher(
                      duration: AppMotion.fast,
                      child: Text(
                        l10n.multiSelectedCount(selectedCount),
                        key: ValueKey(selectedCount),
                        style: Theme.of(context).textTheme.labelMedium!
                            .copyWith(color: AppColors.inkMuted),
                      ),
                    ),
                  ),
                PrimaryButton(
                  label: l10n.continueButton,
                  onPressed: canContinue
                      ? () => _controller.continueFrom(step.id)
                      : null,
                ),
              ],
            )
          : null,
      children: [
        for (final (i, option) in step.visibleOptions(state.answers).indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Entrance(
              index: StepLayout.firstContentIndex + i,
              child: ChoiceCard(
                label: option.label.resolve(language),
                description: option.description?.resolve(language),
                selected: isSelected(option),
                multiSelect: isMulti,
                onTap: () => _onTap(option, current),
              ),
            ),
          ),
      ],
    );
  }
}
