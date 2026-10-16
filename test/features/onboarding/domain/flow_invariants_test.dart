import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer_formatter.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_engine.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/localized_text.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/plan_summary.dart';

import '../../../helpers/config_fixtures.dart';

/// Example tests check the paths we thought of. This one sends a thousand
/// indecisive members through the real config: answering at random, going
/// back, changing their minds. After every move, the rules that make the
/// flow safe must still hold.
void main() {
  final config = loadBundledConfig();
  final engine = FlowEngine(config);

  T pick<T>(List<T> items, Random random) =>
      items[random.nextInt(items.length)];

  Answer randomAnswer(FlowStep step, Answers answers, Random random) {
    if (step.optional && random.nextBool()) return const SkippedAnswer();
    return switch (step) {
      SingleChoiceStep() => ChoiceAnswer(
        pick(step.visibleOptions(answers), random).id,
      ),
      MultiChoiceStep() => MultiChoiceAnswer(
        (step.visibleOptions(answers).map((o) => o.id).toList()
              ..shuffle(random))
            .take(
              step.minSelected +
                  random.nextInt(
                    step.visibleOptions(answers).length - step.minSelected + 1,
                  ),
            ),
      ),
      TextInputStep(kind: TextInputKind.email) => TextAnswer(
        'member${random.nextInt(1000)}@example.com',
      ),
      TextInputStep() => TextAnswer(pick(['Layla', 'Noura', 'Sara'], random)),
      NumberStep(:final min, :final max) => NumberAnswer(
        min + random.nextInt(max - min + 1),
      ),
      FrequencyStep(:final min) => NumberAnswer(
        min + random.nextInt(step.allowedMax(answers) - min + 1),
      ),
      InfoStep() => const Acknowledged(),
    };
  }

  void expectSafe(FlowResolution resolution) {
    final ids = resolution.path.map((s) => s.id).toList();

    // No stale answers: everything she has answered is on her path.
    for (final stepId in resolution.answers.keys) {
      expect(ids, contains(stepId), reason: 'stale answer to $stepId');
      if (resolution.answers[stepId] is SkippedAnswer) {
        expect(config.stepById(stepId)!.optional, isTrue);
        expect(resolution.isAnswered(stepId), isTrue);
      }
    }

    // Resolving is stable: doing it again changes nothing.
    final again = engine.resolve(resolution.answers);
    expect(again.answers, resolution.answers);
    expect(again.path.map((s) => s.id), ids);

    // The path keeps config order.
    final configOrder = config.steps.map((s) => s.id).toList();
    final positions = ids.map(configOrder.indexOf).toList();
    expect(positions, [...positions]..sort());

    // No dead ends: every question on her path can be answered.
    for (final step in resolution.path) {
      if (step is ChoiceStep) {
        final visible = step.visibleOptions(resolution.answers).length;
        final needed = step is MultiChoiceStep ? max(1, step.minSelected) : 1;
        expect(visible, greaterThanOrEqualTo(needed), reason: step.id);
      }
    }
  }

  void expectCompletePlan(FlowResolution resolution) {
    final answers = resolution.answers;
    final shown = <LocalizedText>[
      firstMatch(config.plan.titles, answers)!,
      for (final stat in config.plan.stats) ?firstMatch(stat.variants, answers),
      for (final highlight in config.plan.highlights)
        if (highlight.when?.evaluate(answers) ?? true) ...[
          highlight.title,
          highlight.body,
        ],
    ];
    for (final language in config.languages) {
      final formatter = AnswerFormatter(config, language);
      final summary = PlanSummary.build(config, resolution, language);
      for (final MapEntry(:key, :value) in answers.entries) {
        if (value is SkippedAnswer) {
          expect(formatter.describe(key, answers), isNull);
          expect(
            summary.answers.map((row) => row.stepId),
            isNot(contains(key)),
          );
        }
      }
      for (final text in shown) {
        for (final placeholder in placeholdersIn(text)) {
          expect(
            formatter.describe(placeholder, answers),
            isNotNull,
            reason:
                'plan copy uses {$placeholder} but it is not on her path: '
                '${text.resolve(language)}',
          );
        }
      }
    }
    // The summary only ever lists steps from her path.
    for (final step in config.steps.where((s) => s.summaryLabel != null)) {
      if (!resolution.contains(step.id)) {
        expect(
          AnswerFormatter(config, 'en').describe(step.id, answers),
          isNull,
        );
      }
    }
  }

  test('1,000 random members: no dead ends, no stale answers', () {
    final random = Random(20261015);
    final pathsSeen = <String>{};
    var skippedWaists = 0;
    var measuredWaists = 0;

    for (var member = 0; member < 1000; member++) {
      var answers = <String, Answer>{};
      var current = engine.resolve(answers).path.first.id;
      var moves = 0;

      while (true) {
        final resolution = engine.resolve(answers);
        expectSafe(resolution);
        expect(resolution.contains(current), isTrue);

        // A quarter of the time, she goes back to an earlier step.
        final index = resolution.indexOf(current);
        if (index > 0 && moves < 60 && random.nextDouble() < 0.25) {
          current = resolution.path[random.nextInt(index)].id;
          moves++;
          continue;
        }

        final step = config.stepById(current)!;
        answers = engine.resolve({
          ...resolution.answers,
          current: randomAnswer(step, resolution.answers, random),
        }).answers;

        final updated = engine.resolve(answers);
        // Answering a step never removes it from her path.
        expect(updated.contains(current), isTrue);

        final next = updated.stepAfter(current);
        if (next == null) break;
        current = next.id;
        moves++;
      }

      final finished = engine.resolve(answers);
      expect(finished.isComplete, isTrue);
      expectCompletePlan(finished);
      switch (finished.answers['waist']) {
        case SkippedAnswer():
          skippedWaists++;
        case NumberAnswer():
          measuredWaists++;
        case _:
          break;
      }
      pathsSeen.add(finished.path.map((s) => s.id).join('>'));
    }

    // The walk really explored every branch: the default path, the
    // lymphatic explainer, and getting back into it plain, after an injury
    // and after a baby.
    expect(pathsSeen, hasLength(5));
    expect(skippedWaists, greaterThan(0));
    expect(measuredWaists, greaterThan(0));
  });
}
