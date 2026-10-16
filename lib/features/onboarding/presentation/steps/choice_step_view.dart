import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/l10n/language_controller.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';
import 'package:traininpink_onboarding/core/ui/widgets/choice_card.dart';
import 'package:traininpink_onboarding/core/ui/widgets/entrance.dart';
import 'package:traininpink_onboarding/core/ui/widgets/primary_button.dart';
import 'package:traininpink_onboarding/features/onboarding/application/controllers/choice_step_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/step_layout.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/body_map.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/step_hero.dart';

/// Single choice moves on by itself a beat after she taps, like the
/// Traininpink app. Multi choice waits for Continue.
///
/// Everything lives in ChoiceStepController, including the beat before a
/// single choice moves on; this only lays the page out.
class ChoiceStepView extends ConsumerWidget {
  const ChoiceStepView({required this.step, super.key});

  final ChoiceStep step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageProvider);
    final formatter = ref.watch(answerFormatterProvider);
    final answers = ref.watch(
      onboardingControllerProvider.select((state) => state.answers),
    );
    final page = ref.watch(choiceStepControllerProvider(step.id));
    final controller = ref.read(choiceStepControllerProvider(step.id).notifier);
    void select(ChoiceOption option) => controller.select(
      option,
      instant: MediaQuery.disableAnimationsOf(context),
    );

    return StepLayout(
      hero: switch (step.image) {
        final image? when !page.usesBodyMap => StepHero(
          image: image,
          focus: Alignment(step.imageFocus.x, step.imageFocus.y),
        ),
        _ => null,
      },
      title: formatter.fill(step.title, answers),
      subtitle: step.subtitle?.resolve(language),
      footer: page.isMulti || page.showContinue
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (page.isMulti)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AnimatedSwitcher(
                      duration: AppMotion.fast,
                      child: Text(
                        l10n.multiSelectedCount(page.selectedIds.length),
                        key: ValueKey(page.selectedIds.length),
                        style: Theme.of(context).textTheme.labelMedium!
                            .copyWith(color: AppColors.inkMuted),
                      ),
                    ),
                  ),
                PrimaryButton(
                  label: l10n.continueButton,
                  onPressed: page.canContinue ? controller.continueStep : null,
                ),
              ],
            )
          : null,
      children: [
        if (page.usesBodyMap)
          Entrance(
            index: StepLayout.firstContentIndex,
            child: BodyMap(
              options: page.options,
              selected: page.selectedIds,
              labelOf: (option) => option.label.resolve(language),
              height: math.min(340, MediaQuery.sizeOf(context).height * 0.38),
              side: page.bodySide,
              onTurn: controller.turnTo,
              onToggle: select,
            ),
          )
        else
          for (final (i, option) in page.options.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Entrance(
                index: StepLayout.firstContentIndex + i,
                child: ChoiceCard(
                  label: option.label.resolve(language),
                  description: option.description?.resolve(language),
                  selected: page.isSelected(option),
                  multiSelect: page.isMulti,
                  onTap: () => select(option),
                ),
              ),
            ),
      ],
    );
  }
}
