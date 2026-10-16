import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/l10n/language_controller.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';
import 'package:traininpink_onboarding/core/ui/widgets/entrance.dart';
import 'package:traininpink_onboarding/core/ui/widgets/flow_background.dart';
import 'package:traininpink_onboarding/core/ui/widgets/primary_button.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/step_layout.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/flow_points.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/icon_badge.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/immersive_info.dart';

/// A pause between questions: reassurance that her answer was heard.
class InfoStepView extends ConsumerWidget {
  const InfoStepView({required this.step, super.key});

  final InfoStep step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageProvider);
    final formatter = ref.watch(answerFormatterProvider);
    final answers = ref.watch(
      onboardingControllerProvider.select((state) => state.answers),
    );

    final points = [
      for (final point in step.points)
        (
          icon: point.icon,
          title: formatter.fill(point.title, answers),
          text: formatter.fill(point.text, answers),
        ),
    ];
    final continueButton = PrimaryButton(
      label: l10n.continueButton,
      onPressed: () =>
          ref.read(onboardingControllerProvider.notifier).continueFrom(step.id),
    );

    if (step.image case final image?) {
      return ImmersiveInfo(
        image: image,
        focus: Alignment(step.imageFocus.x, step.imageFocus.y),
        icon: step.icon,
        title: formatter.fill(step.title, answers),
        subtitle: step.subtitle?.resolve(language),
        body: step.body == null ? null : formatter.fill(step.body!, answers),
        points: points,
        button: continueButton,
      );
    }

    return StepLayout(
      backdrop: const FlowBackground(),
      leading: Align(
        alignment: AlignmentDirectional.centerStart,
        child: IconBadge(step.icon),
      ),
      title: formatter.fill(step.title, answers),
      subtitle: step.subtitle?.resolve(language),
      footer: continueButton,
      children: [
        if (points.isNotEmpty)
          FlowPoints(
            firstIndex: StepLayout.firstContentIndex,
            points: points,
          ),
        if (step.body case final body?)
          Entrance(
            index: StepLayout.firstContentIndex,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: AppColors.surface),
                boxShadow: AppShadows.card,
              ),
              child: Text(
                formatter.fill(body, answers),
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: AppColors.ink,
                  fontSize: 16.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
