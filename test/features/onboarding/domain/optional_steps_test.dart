import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer_formatter.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/condition.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/config_json.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_engine.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/plan_summary.dart';

import '../../../helpers/config_fixtures.dart';

void main() {
  final config = loadBundledConfig();
  final engine = FlowEngine(config);
  const skip = SkippedAnswer();
  final json =
      jsonDecode(File('assets/config/onboarding.json').readAsStringSync())
          as Map<String, Object?>;
  final steps = (json['steps']! as List<Object?>).cast<Map<String, Object?>>();

  test('only the bundled waist step is optional', () {
    expect(config.steps.where((step) => step.optional).map((step) => step.id), [
      'waist',
    ]);
    expect(skip.toJson(), 'skipped');
    expect(skip, const SkippedAnswer());
    expect(skip.hashCode, const SkippedAnswer().hashCode);
  });

  for (final type in [
    'single',
    'multi',
    'text',
    'number',
    'frequency',
    'info',
  ]) {
    test('$type parses optional and only allows opted-in skips', () {
      final source = steps.firstWhere((step) => step['type'] == type);
      final requiredJson = {...source}..remove('optional');
      final requiredStep = FlowStep.fromJson(requiredJson, 'step');
      expect(requiredStep.optional, isFalse);
      expect(requiredStep.sanitize(skip, const {}), isNull);
      expect(requiredStep.answerFromJson(skip.toJson()), isNull);

      for (final optional in [true, false]) {
        final step = FlowStep.fromJson({
          ...source,
          'optional': optional,
        }, 'step');
        expect(step.optional, optional);
        expect(step.sanitize(skip, const {}), optional ? skip : isNull);
        expect(step.answerFromJson(skip.toJson()), optional ? skip : isNull);
      }
    });
  }

  test('optional must be a boolean when provided', () {
    for (final value in ['true', 1, null]) {
      expect(
        () => FlowStep.fromJson({...steps.first, 'optional': value}, 'step'),
        throwsA(
          isA<ConfigFormatException>().having(
            (error) => error.path,
            'path',
            'step.optional',
          ),
        ),
      );
    }
  });

  test('a skipped leaf composes with not, all and any', () {
    final skipped = Condition.fromJson({
      'answer': 'waist',
      'skipped': true,
    }, 'when');
    expect(skipped, isA<AnswerSkipped>());
    expect(skipped.evaluate(const {}), isFalse);
    expect(skipped.evaluate(const {'waist': NumberAnswer(82)}), isFalse);
    expect(skipped.evaluate(const {'waist': skip}), isTrue);

    final condition = Condition.fromJson({
      'all': [
        {
          'not': {'answer': 'waist', 'skipped': true},
        },
        {
          'any': [
            {'answer': 'goal', 'equals': 'feel_lighter'},
            {'answer': 'goal', 'equals': 'lose_weight'},
          ],
        },
      ],
    }, 'when');
    expect(
      condition.evaluate(const {
        'goal': ChoiceAnswer('feel_lighter'),
        'waist': skip,
      }),
      isFalse,
    );
    expect(
      condition.evaluate(const {
        'goal': ChoiceAnswer('feel_lighter'),
        'waist': NumberAnswer(82),
      }),
      isTrue,
    );
    expect(condition.leaves.whereType<AnswerSkipped>().single.stepId, 'waist');
  });

  test('skipped conditions require the literal true', () {
    for (final value in [false, 'true', 1, null]) {
      expect(
        () => Condition.fromJson({
          'answer': 'waist',
          'skipped': value,
        }, 'when'),
        throwsA(isA<ConfigFormatException>()),
      );
    }
  });

  for (final language in ['en', 'ar']) {
    for (final goal in ['lose_weight', 'feel_lighter']) {
      test('$language $goal plan omits only skipped waist details', () {
        PlanSummary planWith(Answer waist) {
          final resolution = engine.resolve({
            'name': const TextAnswer('Layla'),
            'goal': ChoiceAnswer(goal),
            'lymph_info': const Acknowledged(),
            'waist': waist,
            'current_training': const ChoiceAnswer('sometimes'),
            'days_per_week': const NumberAnswer(3),
            'focus_areas': MultiChoiceAnswer(const ['belly']),
            'session_length': const ChoiceAnswer('twenty'),
            'email': const TextAnswer('layla@example.com'),
          });
          expect(resolution.isComplete, isTrue);
          expect(resolution.isAnswered('waist'), isTrue);
          return PlanSummary.build(config, resolution, language);
        }

        final skipped = planWith(skip);
        expect(
          skipped.highlights.where((item) => item.icon == 'tape'),
          isEmpty,
        );
        expect(skipped.answers.where((row) => row.stepId == 'waist'), isEmpty);
        expect(
          AnswerFormatter(config, language).describe('waist', const {
            'waist': skip,
          }),
          isNull,
        );

        final measured = planWith(const NumberAnswer(82));
        expect(
          measured.highlights.singleWhere((item) => item.icon == 'tape').title,
          contains('82'),
        );
        expect(
          measured.answers.singleWhere((row) => row.stepId == 'waist').value,
          language == 'en' ? '82 cm' : '82 سم',
        );
        expect(
          measured.answers.where((row) => row.stepId != 'waist'),
          skipped.answers,
        );
      });
    }
  }
}
