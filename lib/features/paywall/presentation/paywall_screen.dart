import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/design/app_assets.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/core/design/widgets/choice_card.dart';
import 'package:traininpink_onboarding/core/design/widgets/entrance.dart';
import 'package:traininpink_onboarding/core/design/widgets/pinned_footer.dart';
import 'package:traininpink_onboarding/core/design/widgets/pressable.dart';
import 'package:traininpink_onboarding/core/design/widgets/primary_button.dart';
import 'package:traininpink_onboarding/core/design/widgets/status_bar_scrim.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/paywall/presentation/price_format.dart';

/// Plans come from the config. The selected plan is unmistakable, the
/// button says exactly what will happen, and a trial explains itself with
/// a timeline instead of small print.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final paywall = ref.watch(flowConfigProvider).paywall;
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final name = ref
        .watch(answerFormatterProvider)
        .describe(
          'name',
          state.answers,
        );
    final selected = paywall.planById(state.selectedPlanId);
    String price(double amount) => formatPrice(l10n, paywall.currency, amount);
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: StatusBarScrim(
              showAfter: 250,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: topInset + 250,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const Image(
                            image: AppAssets.paywall,
                            fit: BoxFit.cover,
                            alignment: Alignment(0, 0.45),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: [0.55, 1],
                                colors: [
                                  Color(0x00FFF7F7),
                                  AppColors.background,
                                ],
                              ),
                            ),
                          ),
                          PositionedDirectional(
                            top: topInset + AppSpacing.sm,
                            end: AppSpacing.lg,
                            child: _CloseButton(
                              label: l10n.closeButton,
                              onTap: controller.closePaywall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      0,
                      AppSpacing.page,
                      AppSpacing.xl,
                    ),
                    sliver: SliverList.list(
                      children: [
                        Entrance(
                          index: 0,
                          child: Text(
                            l10n.paywallTitle(name ?? ''),
                            style: text.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Entrance(
                          index: 1,
                          child: Text(
                            l10n.paywallSubtitle,
                            style: text.bodyLarge,
                          ),
                        ),
                        const SizedBox(height: 28),
                        for (final (i, plan) in paywall.plans.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Entrance(
                              index: 2 + i,
                              child: _PlanOption(
                                plan: plan,
                                selected: plan.id == selected.id,
                                savePercent: _savePercent(plan, paywall),
                                price: price,
                                onTap: () => controller.selectPlan(plan.id),
                              ),
                            ),
                          ),
                        AnimatedSize(
                          duration: AppMotion.medium,
                          curve: AppMotion.standard,
                          alignment: Alignment.topCenter,
                          child: AnimatedSwitcher(
                            duration: AppMotion.medium,
                            child: selected.hasTrial
                                ? Padding(
                                    key: ValueKey(selected.id),
                                    padding: const EdgeInsets.only(top: 14),
                                    child: _TrialTimeline(
                                      trialDays: selected.trialDays,
                                      billedPrice: price(selected.price),
                                    ),
                                  )
                                : const SizedBox(width: double.infinity),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          l10n.paywallFinePrint,
                          style: text.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          PinnedFooter(
            child: PrimaryButton(
              label: selected.hasTrial
                  ? l10n.paywallCtaTrial(selected.trialDays)
                  : l10n.paywallCtaSubscribe(
                      selected.billingMonths == 1
                          ? l10n.paywallPerMonth(price(selected.price))
                          : price(selected.price),
                    ),
              haptic: PressHaptic.medium,
              onPressed: controller.subscribe,
            ),
          ),
        ],
      ),
    );
  }

  /// Rounded down, so the claim is never bigger than the real saving.
  static int _savePercent(PricingPlan plan, PaywallConfig paywall) =>
      ((1 - plan.pricePerMonth / paywall.referenceMonthlyPrice) * 100).floor();
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.plan,
    required this.selected,
    required this.savePercent,
    required this.price,
    required this.onTap,
  });

  final PricingPlan plan;
  final bool selected;
  final int savePercent;
  final String Function(double amount) price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final language = Localizations.localeOf(context).languageCode;
    final billed = switch (plan.billingMonths) {
      1 => l10n.paywallBilledMonthly,
      12 => l10n.paywallBilledYearly(price(plan.price)),
      final months => l10n.paywallBilledEveryMonths(price(plan.price), months),
    };

    final card = AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      padding: const EdgeInsetsDirectional.fromSTEB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: selected ? AppColors.blush : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
        boxShadow: selected ? AppShadows.raised : AppShadows.card,
      ),
      child: Row(
        children: [
          RadioIndicator(selected: selected),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.title.resolve(language), style: text.titleLarge),
                const SizedBox(height: 3),
                Text(billed, style: text.bodySmall),
                if (plan.hasTrial) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.paywallTrialDays(plan.trialDays),
                    style: text.labelMedium!.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.paywallPerMonth(price(plan.pricePerMonth)),
                style: text.titleMedium!.copyWith(fontWeight: FontWeight.w600),
              ),
              if (savePercent > 0) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    l10n.paywallSave(savePercent),
                    style: text.labelSmall!.copyWith(color: AppColors.success),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            card,
            if (plan.badge case final badge?)
              PositionedDirectional(
                top: -11,
                end: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    badge.resolve(language),
                    style: text.labelSmall!.copyWith(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrialTimeline extends StatelessWidget {
  const _TrialTimeline({required this.trialDays, required this.billedPrice});

  final int trialDays;
  final String billedPrice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reminderDay = (trialDays - 2).clamp(1, trialDays);
    final steps = [
      (
        icon: Icons.lock_open_rounded,
        title: l10n.paywallTimelineToday,
        body: l10n.paywallTimelineTodayBody,
      ),
      (
        icon: Icons.notifications_none_rounded,
        title: l10n.paywallTimelineDay(reminderDay),
        body: l10n.paywallTimelineReminderBody,
      ),
      (
        icon: Icons.workspace_premium_outlined,
        title: l10n.paywallTimelineDay(trialDays),
        body: l10n.paywallTimelineBillingBody(billedPrice),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.paywallTimelineTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          for (final (i, step) in steps.indexed)
            _TimelineRow(
              icon: step.icon,
              title: step.title,
              body: step.body,
              isFirst: i == 0,
              isLast: i == steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.isFirst,
    required this.isLast,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFirst ? AppColors.primary : AppColors.blush,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isFirst ? Colors.white : AppColors.primary,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.track,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 6, bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(body, style: text.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: Pressable(
      onTap: onTap,
      pressedScale: 0.9,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close_rounded, color: AppColors.ink, size: 22),
      ),
    ),
  );
}
