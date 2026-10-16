import 'package:flutter_test/flutter_test.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer_formatter.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_engine.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/localized_text.dart';

import '../../../helpers/config_fixtures.dart';

void main() {
  late FlowConfig config;
  late FlowEngine engine;

  setUp(() {
    config = loadBundledConfig();
    engine = FlowEngine(config);
  });

  List<String> pathFor(Answers answers) =>
      engine.resolve(answers).path.map((s) => s.id).toList();

  /// What the controller does on every change: keep only what still applies.
  Answers change(Answers answers, String stepId, Answer answer) =>
      engine.resolve({...answers, stepId: answer}).answers;

  const name = TextAnswer('Layla');
  const getBack = ChoiceAnswer('get_back_into_it');

  group('branching', () {
    final cases = <({String description, Answers answers, List<String> path})>[
      (
        description: 'no answers yet: the default path',
        answers: {},
        path: [
          'name',
          'goal',
          'current_training',
          'days_per_week',
          'focus_areas',
          'session_length',
          'email',
        ],
      ),
      (
        description: 'getting back into it: asks about the break instead',
        answers: {'name': name, 'goal': getBack},
        path: [
          'name',
          'goal',
          'last_trained',
          'stop_reason',
          'days_per_week',
          'focus_areas',
          'session_length',
          'email',
        ],
      ),
      (
        description: 'stopped because of an injury: adds the injury branch',
        answers: {
          'name': name,
          'goal': getBack,
          'last_trained': const ChoiceAnswer('few_months'),
          'stop_reason': const ChoiceAnswer('injury'),
        },
        path: [
          'name',
          'goal',
          'last_trained',
          'stop_reason',
          'injury_areas',
          'injury_info',
          'days_per_week',
          'focus_areas',
          'session_length',
          'email',
        ],
      ),
      (
        description: 'weight loss: adds the lymphatic explainer',
        answers: {'name': name, 'goal': const ChoiceAnswer('lose_weight')},
        path: [
          'name',
          'goal',
          'lymph_info',
          'waist',
          'current_training',
          'days_per_week',
          'focus_areas',
          'session_length',
          'email',
        ],
      ),
    ];

    for (final c in cases) {
      test(c.description, () => expect(pathFor(c.answers), c.path));
    }
  });

  group('changing an earlier answer', () {
    test('the brief\'s example: leaving "get back into it" drops its answers '
        'from the path and the plan', () {
      var answers = <String, Answer>{'name': name};
      answers = change(answers, 'goal', getBack);
      answers = change(
        answers,
        'last_trained',
        const ChoiceAnswer('few_weeks'),
      );
      expect(answers, contains('last_trained'));

      answers = change(answers, 'goal', const ChoiceAnswer('build_strength'));

      expect(answers.keys, ['name', 'goal']);
      expect(pathFor(answers), isNot(contains('last_trained')));
      final formatter = AnswerFormatter(config, 'en');
      expect(formatter.describe('last_trained', answers), isNull);
    });

    test('a nested branch goes when its parent answer changes', () {
      var answers = <String, Answer>{
        'name': name,
        'goal': getBack,
        'last_trained': const ChoiceAnswer('few_months'),
        'stop_reason': const ChoiceAnswer('injury'),
        'injury_areas': MultiChoiceAnswer(const ['knees']),
        'injury_info': const Acknowledged(),
        'days_per_week': const NumberAnswer(2),
      };
      answers = engine.resolve(answers).answers;

      answers = change(answers, 'stop_reason', const ChoiceAnswer('busy'));

      expect(answers.keys, isNot(contains('injury_areas')));
      expect(answers.keys, isNot(contains('injury_info')));
      // Answers that are still on her path survive the change.
      expect(answers['last_trained'], const ChoiceAnswer('few_months'));
      expect(answers['days_per_week'], const NumberAnswer(2));
    });

    test('a week above a lowered max is dropped, the rest are kept', () {
      var answers = <String, Answer>{
        'name': name,
        'goal': const ChoiceAnswer('build_strength'),
        'current_training': const ChoiceAnswer('regularly'),
        'days_per_week': const NumberAnswer(5),
        'focus_areas': MultiChoiceAnswer(const ['arms']),
      };
      answers = engine.resolve(answers).answers;
      expect(answers, contains('days_per_week'));

      // Five days is only offered to women who already train regularly.
      answers = change(
        answers,
        'current_training',
        const ChoiceAnswer('rarely'),
      );

      expect(answers, isNot(contains('days_per_week')));
      expect(answers['focus_areas'], MultiChoiceAnswer(const ['arms']));
    });

    test('a stale answer can never steer the flow', () {
      // stop_reason is left over from a branch she is no longer on.
      final resolution = engine.resolve({
        'goal': const ChoiceAnswer('build_strength'),
        'stop_reason': const ChoiceAnswer('injury'),
      });

      expect(resolution.contains('injury_areas'), isFalse);
      expect(resolution.answers, isNot(contains('stop_reason')));
    });

    test('an answer of the wrong shape is dropped', () {
      final resolution = engine.resolve({
        'goal': MultiChoiceAnswer(const ['lose_weight']),
        'email': const TextAnswer('not-an-email'),
      });

      expect(resolution.answers, isEmpty);
    });
  });

  group('session frequency', () {
    FrequencyStep frequency() =>
        config.stepById('days_per_week')! as FrequencyStep;

    test('caps preserve the existing routine and comeback limits', () {
      for (final (id, max) in [
        ('rarely', 3),
        ('sometimes', 4),
        ('regularly', 5),
      ]) {
        final answers = <String, Answer>{'current_training': ChoiceAnswer(id)};
        expect(frequency().allowedMax(answers), max);
        expect(frequency().sanitize(NumberAnswer(max), answers), isNotNull);
        expect(frequency().sanitize(NumberAnswer(max + 1), answers), isNull);
      }
      expect(
        frequency().allowedMax({
          'last_trained': const ChoiceAnswer('few_weeks'),
        }),
        4,
      );
      expect(
        frequency().allowedMax({
          'last_trained': const ChoiceAnswer('over_a_year'),
        }),
        3,
      );
    });

    test('configured suggestions are valid for every routine', () {
      for (final source in frequency().suggestedBy) {
        final step = config.stepById(source)! as SingleChoiceStep;
        for (final option in step.options) {
          final answers = <String, Answer>{source: ChoiceAnswer(option.id)};
          final suggestion = frequency().suggestionFor(answers)!;
          expect(
            frequency().sanitize(NumberAnswer(suggestion), answers),
            isNotNull,
          );
        }
      }
      expect(
        frequency().suggestionFor({
          'current_training': const ChoiceAnswer('rarely'),
        }),
        2,
      );
      expect(
        frequency().suggestionFor({
          'current_training': const ChoiceAnswer('sometimes'),
        }),
        3,
      );
      expect(
        frequency().suggestionFor({
          'current_training': const ChoiceAnswer('regularly'),
        }),
        4,
      );
    });

    test('a frequency above a lowered comeback cap is removed', () {
      final answers = engine.resolve({
        'goal': getBack,
        'last_trained': const ChoiceAnswer('few_weeks'),
        'days_per_week': const NumberAnswer(4),
      }).answers;
      expect(answers, contains('days_per_week'));
      expect(
        change(answers, 'last_trained', const ChoiceAnswer('few_months')),
        isNot(contains('days_per_week')),
      );
    });

    test('counts round trip and previous weekdays migrate to their count', () {
      const answer = NumberAnswer(3);
      expect(answer.toJson(), 3);
      expect(frequency().answerFromJson(answer.toJson()), answer);
      expect(frequency().answerFromJson([0, 2, 4]), answer);
      expect(frequency().answerFromJson([0, '2', 4]), isNull);
      expect(frequency().answerFromJson([0, 7]), isNull);
      expect(frequency().answerFromJson('three'), isNull);
      expect(frequency().sanitize(const NumberAnswer(1), const {}), isNull);
    });

    test('the formatter and plan describe sessions in both languages', () {
      const answers = <String, Answer>{'days_per_week': NumberAnswer(3)};
      final en = AnswerFormatter(config, 'en');
      final ar = AnswerFormatter(config, 'ar');
      expect(en.describe('days_per_week', answers), '3 sessions');
      expect(ar.describe('days_per_week', answers), '3 جلسات');
      expect(en.count('days_per_week', answers), 3);
      expect(
        en.fill(const LocalizedText({'en': '{days_per_week} a week'}), answers),
        '3 sessions a week',
      );
      expect(
        ar.fill(
          const LocalizedText({'ar': '{days_per_week} أسبوعياً'}),
          answers,
        ),
        '3 جلسات أسبوعياً',
      );
      expect(
        en.fill(config.plan.stats.first.variants.first.text, answers),
        '3 sessions a week',
      );
    });
  });

  group('number answers', () {
    const feelLighter = ChoiceAnswer('feel_lighter');

    test('a waist in range is kept and reads with its unit', () {
      final answers = engine.resolve({
        'name': name,
        'goal': feelLighter,
        'waist': const NumberAnswer(82),
      }).answers;

      expect(answers['waist'], const NumberAnswer(82));
      expect(AnswerFormatter(config, 'en').describe('waist', answers), '82 cm');
      expect(AnswerFormatter(config, 'ar').describe('waist', answers), '82 سم');
    });

    test('a waist out of range is dropped', () {
      final answers = engine.resolve({
        'goal': feelLighter,
        'waist': const NumberAnswer(400),
      }).answers;

      expect(answers, isNot(contains('waist')));
    });

    test('the waist question goes when her goal changes', () {
      var answers = engine.resolve({
        'name': name,
        'goal': feelLighter,
        'waist': const NumberAnswer(82),
      }).answers;

      answers = change(answers, 'goal', const ChoiceAnswer('build_strength'));

      expect(answers, isNot(contains('waist')));
    });
  });

  group('navigation helpers', () {
    test('step after, step before and first unanswered follow the path', () {
      final resolution = engine.resolve({'name': name, 'goal': getBack});

      expect(resolution.stepAfter('goal')?.id, 'last_trained');
      expect(resolution.stepBefore('last_trained')?.id, 'goal');
      expect(resolution.stepBefore('name'), isNull);
      expect(resolution.stepAfter('email'), isNull);
      expect(resolution.firstUnanswered?.id, 'last_trained');
      expect(resolution.isComplete, isFalse);
    });

    test('after an edit, only the questions the edit opened are asked', () {
      final resolution = engine.resolve({
        'name': name,
        'goal': getBack,
        'days_per_week': const NumberAnswer(2),
        'focus_areas': MultiChoiceAnswer(const ['belly']),
        'session_length': const ChoiceAnswer('ten'),
        'email': const TextAnswer('layla@example.com'),
      });

      expect(resolution.firstUnansweredAfter('goal')?.id, 'last_trained');
      expect(resolution.firstUnansweredAfter('stop_reason'), isNull);
    });
  });

  group('AnswerFormatter', () {
    final answers = <String, Answer>{
      'name': name,
      'focus_areas': MultiChoiceAnswer(const ['posture', 'belly', 'legs']),
    };

    test('lists choices in config order, in each language', () {
      expect(
        AnswerFormatter(config, 'en').describe('focus_areas', answers),
        'Belly & waist, Legs & thighs and Posture & back',
      );
      expect(
        AnswerFormatter(config, 'ar').describe('focus_areas', answers),
        'البطن والخصر، الساقين والفخذين والقوام والظهر',
      );
    });

    test('fills placeholders with her answers', () {
      final goal = config.stepById('goal')!;
      expect(
        AnswerFormatter(config, 'en').fill(goal.title, answers),
        'Nice to meet you, Layla. What brings you here?',
      );
    });
  });
}
