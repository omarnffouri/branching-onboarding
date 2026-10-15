import 'package:flutter_test/flutter_test.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer_formatter.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_engine.dart';

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
        'days_per_week': const ChoiceAnswer('two'),
      };
      answers = engine.resolve(answers).answers;

      answers = change(answers, 'stop_reason', const ChoiceAnswer('busy'));

      expect(answers.keys, isNot(contains('injury_areas')));
      expect(answers.keys, isNot(contains('injury_info')));
      // Answers that are still on her path survive the change.
      expect(answers['last_trained'], const ChoiceAnswer('few_months'));
      expect(answers['days_per_week'], const ChoiceAnswer('two'));
    });

    test('an answer whose option disappears is dropped, the rest are kept', () {
      var answers = <String, Answer>{
        'name': name,
        'goal': const ChoiceAnswer('build_strength'),
        'current_training': const ChoiceAnswer('regularly'),
        'days_per_week': const ChoiceAnswer('five'),
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
        'days_per_week': const ChoiceAnswer('two'),
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
