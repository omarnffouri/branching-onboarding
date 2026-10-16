import 'package:traininpink_onboarding/features/onboarding/domain/answer_formatter.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_engine.dart';

typedef PlanStatItem = ({String icon, String text});
typedef PlanHighlightItem = ({String icon, String title, String body});
typedef PlanAnswerRow = ({String stepId, String label, String value});

/// Her plan, in words, built only from the path she actually took.
///
/// Pure function of config + resolution + language, so it is tested without
/// widgets and the plan screen only lays it out.
final class PlanSummary {
  const PlanSummary({
    required this.title,
    required this.stats,
    required this.highlights,
    required this.answers,
  });

  factory PlanSummary.build(
    FlowConfig config,
    FlowResolution resolution,
    String languageCode,
  ) {
    final formatter = AnswerFormatter(config, languageCode);
    final answers = resolution.answers;
    final plan = config.plan;

    return PlanSummary(
      title: formatter.fill(firstMatch(plan.titles, answers)!, answers),
      stats: [
        for (final stat in plan.stats)
          if (firstMatch(stat.variants, answers) case final text?)
            (icon: stat.icon, text: formatter.fill(text, answers)),
      ],
      highlights: [
        for (final highlight in plan.highlights)
          if (highlight.when?.evaluate(answers) ?? true)
            (
              icon: highlight.icon,
              title: formatter.fill(highlight.title, answers),
              body: formatter.fill(highlight.body, answers),
            ),
      ],
      answers: [
        // Walk her path, not the config: steps she skipped cannot appear.
        for (final step in resolution.path)
          if (step.summaryLabel case final label?)
            if (formatter.describe(step.id, answers) case final value?)
              (
                stepId: step.id,
                label: label.resolve(languageCode),
                value: value,
              ),
      ],
    );
  }

  final String title;
  final List<PlanStatItem> stats;
  final List<PlanHighlightItem> highlights;
  final List<PlanAnswerRow> answers;
}
