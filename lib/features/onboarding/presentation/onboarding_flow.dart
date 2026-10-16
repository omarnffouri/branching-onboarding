import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/core/l10n/language_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_state.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/building_plan_screen.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/fade_through_page.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/flow_header.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/flow_inspector.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/plan_screen.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/resume_banner.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/step_hero.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/step_screen.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/week_step_view.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/welcome_screen.dart';
import 'package:traininpink_onboarding/features/paywall/presentation/paywall_screen.dart';
import 'package:traininpink_onboarding/features/paywall/presentation/success_screen.dart';

/// The onboarding, rendered from state.
///
/// The page stack is *derived*: welcome, then every step on her path up to
/// the current one, then the plan and paywall. Navigation is just state
/// changing, and the `Navigator` animates the difference. Because each step
/// is a real `CupertinoPage`, the iPhone edge-swipe back works natively and
/// mirrors in Arabic; a swipe reports back through `onPopInvoked`.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  var _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode the photos up front so no screen ever pops its image in late.
    if (!_precached) {
      _precached = true;
      final config = ref.read(flowConfigProvider);
      for (final image in [
        welcomeImage,
        planImage,
        paywallImage,
        successImage,
        for (final step in config.steps)
          if (step.image case final image?) StepHero.providerFor(image),
      ]) {
        precacheImage(image, context).ignore();
      }
    }
  }

  void _openInspector() {
    HapticFeedback.mediumImpact().ignore();
    showFlowInspector(context).ignore();
  }

  List<Page<void>> _pages(OnboardingState state) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    if (state.stage == OnboardingStage.subscribed) {
      return const [
        FadeThroughPage(key: ValueKey('success'), child: SuccessScreen()),
      ];
    }

    final lastStep = state.stage == OnboardingStage.questions
        ? state.currentPageIndex
        : state.pageGroups.length - 1;

    return [
      FadeThroughPage(
        key: const ValueKey('welcome'),
        child: WelcomeScreen(onOpenInspector: _openInspector),
      ),
      if (state.stage != OnboardingStage.welcome)
        for (final group in state.pageGroups.take(lastStep + 1))
          CupertinoPage(
            key: ValueKey('step:${group.first.id}'),
            name: group.first.id,
            child: group.first.group == null
                ? StepScreen(step: group.first)
                : WeekStepView(steps: group.steps),
            onPopInvoked: (didPop, _) {
              if (didPop) controller.backFromStep(group.first.id);
            },
          ),
      if (state.stage == OnboardingStage.building)
        const FadeThroughPage(
          key: ValueKey('building'),
          canPop: false,
          child: BuildingPlanScreen(),
        ),
      if (state.stage case OnboardingStage.plan || OnboardingStage.paywall)
        FadeThroughPage(
          key: const ValueKey('plan'),
          child: const PlanScreen(),
          onPopInvoked: (didPop, _) {
            if (didPop) controller.backFromPlan();
          },
        ),
      if (state.stage == OnboardingStage.paywall)
        CupertinoPage(
          key: const ValueKey('paywall'),
          fullscreenDialog: true,
          child: const PaywallScreen(),
          onPopInvoked: (didPop, _) {
            if (didPop) controller.closePaywall();
          },
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final language = ref.watch(languageProvider);
    final showHeader = state.stage == OnboardingStage.questions;
    final config = ref.watch(flowConfigProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: ColoredBox(
        color: AppColors.background,
        child: Stack(
          children: [
            NavigatorPopHandler(
              onPopWithResult: (_) => _navigatorKey.currentState?.maybePop(),
              child: Navigator(
                key: _navigatorKey,
                pages: _pages(state),
                // Pages report pops through onPopInvoked; state then drops
                // the page, so there is nothing left to do here.
                onDidRemovePage: (_) {},
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !showHeader,
                child: AnimatedSlide(
                  offset: showHeader ? Offset.zero : const Offset(0, -0.3),
                  duration: AppMotion.medium,
                  curve: AppMotion.emphasized,
                  child: AnimatedOpacity(
                    opacity: showHeader ? 1 : 0,
                    duration: AppMotion.medium,
                    child: FlowHeader(
                      progress: state.progress,
                      currentStep: state.currentPageIndex + 1,
                      totalSteps: state.pageGroups.length,
                      onBack: () {
                        if (state.currentStepId case final stepId?) {
                          controller.backFromStep(stepId);
                        }
                      },
                      otherLanguageLabel: language == 'ar' ? 'EN' : 'ع',
                      onToggleLanguage: () => ref
                          .read(languageProvider.notifier)
                          .select(language == 'ar' ? 'en' : 'ar'),
                      onOpenInspector: _openInspector,
                      solid: switch (state.currentStepId) {
                        final id? => switch (config.stepById(id)) {
                          InfoStep() || NumberStep() => false,
                          _ => true,
                        },
                        null => true,
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (state.resumed)
              Positioned(
                top: showHeader
                    ? FlowHeader.extentOf(context)
                    : MediaQuery.paddingOf(context).top + AppSpacing.sm,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                child: ResumeBanner(
                  name: ref
                      .read(answerFormatterProvider)
                      .describe('name', state.answers),
                  onDismissed: controller.dismissResumeGreeting,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
