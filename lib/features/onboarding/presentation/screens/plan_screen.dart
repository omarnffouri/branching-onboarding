import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/l10n/language_controller.dart';
import 'package:traininpink_onboarding/core/ui/app_assets.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';
import 'package:traininpink_onboarding/core/ui/widgets/entrance.dart';
import 'package:traininpink_onboarding/core/ui/widgets/pinned_footer.dart';
import 'package:traininpink_onboarding/core/ui/widgets/pressable.dart';
import 'package:traininpink_onboarding/core/ui/widgets/primary_button.dart';
import 'package:traininpink_onboarding/core/ui/widgets/status_bar_scrim.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/plan_summary.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/config_icons.dart';

/// Her plan: built from the path she took, and editable in place. Tapping
/// an answer re-enters the flow at that question; the plan she comes back
/// to reflects the change.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final controller = ref.read(onboardingControllerProvider.notifier);
    final summary = PlanSummary.build(
      ref.watch(flowConfigProvider),
      ref.watch(onboardingControllerProvider).resolution,
      ref.watch(languageProvider),
    );
    final headerHeight = MediaQuery.paddingOf(context).top + 260;
    var order = 0;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: StatusBarScrim(
              showAfter: headerHeight - MediaQuery.paddingOf(context).top,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: headerHeight,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const Image(
                            image: AppAssets.plan,
                            fit: BoxFit.cover,
                            alignment: Alignment(0, 0.6),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: [0.45, 1],
                                colors: [
                                  Color(0x00FFF7F7),
                                  AppColors.background,
                                ],
                              ),
                            ),
                          ),
                          PositionedDirectional(
                            start: AppSpacing.page,
                            bottom: AppSpacing.md,
                            child: Entrance(
                              index: order++,
                              child: _Pill(
                                icon: Icons.auto_awesome_rounded,
                                text: l10n.planEyebrow,
                                filled: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.md,
                      AppSpacing.page,
                      AppSpacing.xl,
                    ),
                    sliver: SliverList.list(
                      children: [
                        Entrance(
                          index: order++,
                          child: Text(
                            summary.title,
                            style: text.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Entrance(
                          index: order++,
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final stat in summary.stats)
                                _Pill(
                                  icon: iconFor(stat.icon),
                                  text: stat.text,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Entrance(
                          index: order++,
                          child: Text(
                            l10n.planHighlightsTitle,
                            style: text.headlineSmall,
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (final highlight in summary.highlights)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: Entrance(
                              index: order++,
                              child: _HighlightCard(highlight: highlight),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xl),
                        Entrance(
                          index: order++,
                          child: Text(
                            l10n.planAnswersTitle,
                            style: text.headlineSmall,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Entrance(
                          index: order++,
                          child: Text(
                            l10n.planAnswersHint,
                            style: text.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Entrance(
                          index: order++,
                          child: _AnswersCard(
                            rows: summary.answers,
                            onEdit: controller.editFromPlan,
                          ),
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
              label: l10n.planCta,
              onPressed: controller.openPaywall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, this.filled = false});

  final IconData icon;
  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final color = filled ? Colors.white : AppColors.primary;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 14, 8),
      decoration: BoxDecoration(
        color: filled ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: filled ? null : Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.labelMedium!.copyWith(color: filled ? color : null),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.highlight});

  final PlanHighlightItem highlight;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.blush,
              shape: BoxShape.circle,
            ),
            child: Icon(iconFor(highlight.icon), color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(highlight.title, style: text.titleLarge),
                const SizedBox(height: 4),
                Text(highlight.body, style: text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswersCard extends StatelessWidget {
  const _AnswersCard({required this.rows, required this.onEdit});

  final List<PlanAnswerRow> rows;
  final ValueChanged<String> onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 18,
                endIndent: 18,
                color: AppColors.border,
              ),
            Semantics(
              button: true,
              label: l10n.planEditSemantics(row.label),
              child: Pressable(
                onTap: () => onEdit(row.stepId),
                pressedScale: 0.985,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 12, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(row.label, style: text.bodySmall),
                            const SizedBox(height: 2),
                            Text(
                              row.value,
                              style: text.titleMedium!.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primarySoft,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
