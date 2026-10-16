import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_state.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

/// A live view of the config for whoever is testing the flow: every step,
/// whether it is on her path, and if not, the rule that skipped it.
///
/// Opened with a long press on the progress bar (or the welcome wordmark).
/// A developer tool, so it stays in English and left to right.
Future<void> showFlowInspector(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.background,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
  ),
  builder: (_) => const Directionality(
    textDirection: TextDirection.ltr,
    child: FlowInspector(),
  ),
);

enum _Status { answered, current, upcoming, skipped }

class FlowInspector extends ConsumerWidget {
  const FlowInspector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(flowConfigProvider);
    final state = ref.watch(onboardingControllerProvider);
    final formatter = ref.watch(answerFormatterProvider);
    final text = Theme.of(context).textTheme;
    final resolution = state.resolution;

    _Status statusOf(FlowStep step) {
      if (!resolution.contains(step.id)) return _Status.skipped;
      if (state.stage == OnboardingStage.questions &&
          state.currentStepId == step.id) {
        return _Status.current;
      }
      return resolution.isAnswered(step.id)
          ? _Status.answered
          : _Status.upcoming;
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Flow inspector', style: text.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Live from assets/config/onboarding.json. '
            '${resolution.path.length} of ${config.steps.length} steps are '
            'on her path; stage: ${state.stage.name}.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final step in config.steps)
            _StepRow(
              step: step,
              status: statusOf(step),
              answer: switch (step) {
                InfoStep() when resolution.isAnswered(step.id) => 'seen',
                _ => formatter.describe(step.id, resolution.answers),
              },
            ),
          const SizedBox(height: 16),
          Text(
            'Funnel events are logged to the console under '
            '"onboarding.analytics".',
            style: text.bodySmall,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              ref
                  .read(onboardingControllerProvider.notifier)
                  .restart()
                  .ignore();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Reset progress'),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.status,
    required this.answer,
  });

  final FlowStep step;
  final _Status status;
  final String? answer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (icon, color) = switch (status) {
      _Status.answered => (Icons.check_circle_rounded, AppColors.success),
      _Status.current => (
        Icons.radio_button_checked_rounded,
        AppColors.primary,
      ),
      _Status.upcoming => (Icons.radio_button_unchecked, AppColors.primarySoft),
      _Status.skipped => (Icons.block_rounded, AppColors.border),
    };
    final skipped = status == _Status.skipped;
    final detail = skipped
        ? 'skipped: needs ${step.showIf?.describe()}'
        : [
            if (step.showIf case final showIf?) 'shown: ${showIf.describe()}',
            if (answer case final answer?) '→ $answer',
          ].join('   ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${step.id}  ·  ${step.runtimeType}',
                  style: text.labelMedium!.copyWith(
                    fontFamily: 'Poppins',
                    color: skipped ? AppColors.inkMuted : AppColors.ink,
                    decoration: skipped ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    style: text.bodySmall!.copyWith(fontFamily: 'Poppins'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
