import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/l10n/language_controller.dart';
import 'package:traininpink_onboarding/core/ui/app_assets.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';
import 'package:traininpink_onboarding/core/ui/widgets/entrance.dart';
import 'package:traininpink_onboarding/core/ui/widgets/flow_background.dart';
import 'package:traininpink_onboarding/core/ui/widgets/pressable.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/plan_summary.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/member_card.dart';

class SuccessScreen extends ConsumerWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final language = ref.watch(languageProvider);
    final state = ref.watch(onboardingControllerProvider);
    final paywall = ref.watch(flowConfigProvider).paywall;
    final name =
        ref.watch(answerFormatterProvider).describe('name', state.answers) ??
        '';
    final subscription = state.subscription;
    final plan = paywall.planById(subscription?.planId ?? state.selectedPlanId);
    final body = plan.hasTrial && subscription != null
        ? l10n.successTrialBody(
            DateFormat.yMMMMd(language).format(
              subscription.subscribedAt.add(Duration(days: plan.trialDays)),
            ),
          )
        : l10n.successBody(plan.title.resolve(language));
    final height = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: FlowBackground()),
          // The photo fades out into the flowing background beneath it.
          ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.55, 1],
              colors: [Colors.white, Colors.transparent],
            ).createShader(bounds),
            child: SizedBox(
              height: height * 0.6,
              width: double.infinity,
              child: const Image(
                image: AppAssets.success,
                fit: BoxFit.cover,
                alignment: Alignment(0, -0.2),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Entrance(
                    index: 0,
                    child: MemberCard(
                      name: name,
                      email: ref
                          .watch(answerFormatterProvider)
                          .describe('email', state.answers),
                      active: true,
                      details: [
                        plan.title.resolve(language),
                        ...PlanSummary.build(
                          ref.watch(flowConfigProvider),
                          state.resolution,
                          language,
                        ).stats.take(1).map((stat) => stat.text),
                      ].join(' · '),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Entrance(
                    index: 1,
                    child: Text(
                      l10n.successTitle(name),
                      style: text.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Entrance(index: 2, child: Text(body, style: text.bodyLarge)),
                  const SizedBox(height: AppSpacing.xxl),
                  Entrance(
                    index: 3,
                    child: Center(
                      child: Pressable(
                        onTap: () => ref
                            .read(onboardingControllerProvider.notifier)
                            .restart(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            border: Border.all(color: AppColors.border),
                            color: AppColors.surface,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.replay_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.successRestart,
                                style: text.labelMedium!.copyWith(
                                  color: AppColors.primary,
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
            ),
          ),
        ],
      ),
    );
  }
}
