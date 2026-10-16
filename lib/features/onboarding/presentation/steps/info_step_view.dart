import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/core/design/widgets/entrance.dart';
import 'package:traininpink_onboarding/core/design/widgets/flow_background.dart';
import 'package:traininpink_onboarding/core/design/widgets/primary_button.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/l10n/language_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/config_icons.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/flow_points.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/step_hero.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/step_layout.dart';

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
      return _ImmersiveInfo(
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
        child: _IconBadge(step.icon),
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

class _IconBadge extends StatelessWidget {
  const _IconBadge(this.icon);

  final String? icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      color: AppColors.blush,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.surface, width: 4),
      boxShadow: AppShadows.card,
    ),
    child: Icon(iconFor(icon), color: AppColors.primary, size: 28),
  );
}

/// An info step with a photo, laid out like a magazine page: the photo
/// covers the top of the screen with no frame and fades into the flowing
/// background; the title sits on that fade and the steps follow.
class _ImmersiveInfo extends StatelessWidget {
  const _ImmersiveInfo({
    required this.image,
    required this.focus,
    required this.icon,
    required this.title,
    required this.points,
    required this.button,
    this.subtitle,
    this.body,
  });

  final String image;
  final Alignment focus;
  final String? icon;
  final String title;
  final String? subtitle;
  final String? body;
  final List<FlowPoint> points;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final route = ModalRoute.of(context)?.animation;
    final animate = route != null && !MediaQuery.disableAnimationsOf(context);
    final photoHeight = MediaQuery.sizeOf(context).height * 0.55;

    Widget photo = Image(
      image: StepHero.providerFor(image),
      fit: BoxFit.cover,
      alignment: focus,
      gaplessPlayback: true,
    );
    if (animate) {
      final eased = route.drive(CurveTween(curve: AppMotion.emphasized));
      photo = AnimatedBuilder(
        animation: eased,
        builder: (context, child) =>
            Transform.scale(scale: 1.1 - 0.1 * eased.value, child: child),
        child: photo,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FlowBackground(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: photoHeight,
            // Fades out at the bottom into the flowing background, and a
            // little at the top so the header stays legible.
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.3, 0.5, 0.86],
                colors: [
                  Color(0x80FFFFFF),
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
              ).createShader(bounds),
              child: ClipRect(child: photo),
            ),
          ),
          SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      photoHeight * 0.8,
                      AppSpacing.page,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Entrance(
                          index: 0,
                          child: Text(title, style: text.headlineMedium),
                        ),
                        if (subtitle case final subtitle?) ...[
                          const SizedBox(height: 8),
                          Entrance(
                            index: 1,
                            child: Text(subtitle, style: text.bodyLarge),
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (points.isNotEmpty)
                          FlowPoints(points: points, firstIndex: 2)
                        else if (body case final body?)
                          Entrance(
                            index: 2,
                            child: Text(
                              body,
                              style: text.bodyLarge!.copyWith(
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.sm,
                    AppSpacing.page,
                    AppSpacing.md,
                  ),
                  child: button,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
