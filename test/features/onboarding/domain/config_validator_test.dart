import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/config_json.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/config_validator.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

import '../../../helpers/config_fixtures.dart';

void main() {
  List<String> issuesFor(Map<String, Object?> json) => [
    for (final issue in ConfigValidator.validate(FlowConfig.fromJson(json)))
      issue.toString(),
  ];

  test('the bundled config is valid', () {
    expect(ConfigValidator.validate(loadBundledConfig()), isEmpty);
  });

  test('the minimal test config is valid', () {
    expect(issuesFor(minimalConfigJson()), isEmpty);
  });

  test('every option on a body figure needs its own region', () {
    final step = choiceStepJson('areas', ['a', 'b', 'c'], type: 'multi')
      ..['display'] = 'body';
    final options = step['options']! as List<Object?>;
    (options[0]! as Map<String, Object?>)['region'] = 'arms';
    (options[1]! as Map<String, Object?>)['region'] = 'arms';

    expect(issuesFor(minimalConfigJson(steps: [step])), [
      contains('body region "arms" is used twice'),
      contains('option "c" needs a body region'),
    ]);
    expect(
      () => FlowConfig.fromJson(
        minimalConfigJson(
          steps: [
            choiceStepJson('areas', ['a'], type: 'multi')..['display'] = 'map',
          ],
        ),
      ),
      throwsA(isA<ConfigFormatException>()),
    );
  });

  test('a condition may not depend on a later step', () {
    final issues = issuesFor(
      minimalConfigJson(
        steps: [
          choiceStepJson('first', ['a'], showIf: answerEquals('second', 'x')),
          choiceStepJson('second', ['x']),
        ],
      ),
    );

    expect(issues.single, contains('comes later'));
  });

  test('unknown steps and options are reported', () {
    final issues = issuesFor(
      minimalConfigJson(
        steps: [
          choiceStepJson('goal', ['a']),
          choiceStepJson('typo_step', ['x'], showIf: answerEquals('gaol', 'a')),
          choiceStepJson('typo_option', [
            'x',
          ], showIf: answerEquals('goal', 'aa')),
        ],
      ),
    );

    expect(issues, [
      contains('unknown step "gaol"'),
      contains('"goal" has no option "aa"'),
    ]);
  });

  test('operators must suit the step they compare', () {
    final issues = issuesFor(
      minimalConfigJson(
        steps: [
          choiceStepJson('areas', ['knees'], type: 'multi'),
          choiceStepJson('uses_equals', [
            'x',
          ], showIf: answerEquals('areas', 'knees')),
        ],
      ),
    );

    expect(issues.single, contains('use "includes"'));
  });

  test('skipped conditions require an optional target, even when nested', () {
    for (final optional in [false, true]) {
      final issues = issuesFor(
        minimalConfigJson(
          steps: [
            choiceStepJson('goal', ['a'])..['optional'] = optional,
            choiceStepJson(
              'next',
              ['x'],
              showIf: {
                'all': [
                  {
                    'any': [
                      {
                        'not': {'answer': 'goal', 'skipped': true},
                      },
                    ],
                  },
                ],
              },
            ),
          ],
        ),
      );
      if (optional) {
        expect(issues, isEmpty);
      } else {
        expect(
          issues.single,
          contains('"skipped" only works on optional steps'),
        );
        expect(issues.single, contains('"goal" is not optional'));
      }
    }
  });

  test('missing Arabic copy, duplicate ids and placeholders are reported', () {
    final broken = choiceStepJson('goal', ['a', 'a'])
      ..['title'] = {'en': 'Hi {name}'};
    final issues = issuesFor(minimalConfigJson(steps: [broken]));

    expect(issues, [
      contains('missing "ar" copy'),
      contains('placeholder {name} must name an earlier question'),
      contains('duplicate option "a"'),
    ]);
  });

  test('the paywall needs two plans, a trial and a valid default', () {
    final issues = issuesFor(
      minimalConfigJson(
        paywall: {
          'currency': 'AED',
          'defaultPlanId': 'weekly',
          'plans': [
            {
              'id': 'monthly',
              'title': text('Monthly'),
              'price': 59,
              'billingMonths': 1,
            },
          ],
        },
      ),
    );

    expect(issues, [
      contains('at least two plans'),
      contains('is not one of the plans'),
      contains('needs a trial'),
    ]);
  });

  group('frequency config', () {
    Map<String, Object?> bundledJson() =>
        jsonDecode(
              File('assets/config/onboarding.json').readAsStringSync(),
            )
            as Map<String, Object?>;

    Map<String, Object?> weekIn(Map<String, Object?> json) =>
        (json['steps']! as List<Object?>)
            .cast<Map<String, Object?>>()
            .firstWhere((step) => step['id'] == 'days_per_week');

    test('invalid bounds and rule conditions fail validation', () {
      final json = bundledJson();
      weekIn(json)
        ..['min'] = 4
        ..['max'] = 3
        ..['maxIf'] = [
          {'when': answerEquals('session_length', 'ten'), 'max': 8},
        ];
      final issues = issuesFor(json);
      expect(issues, contains(contains('min <= max')));
      expect(issues, contains(contains('comes later')));
      expect(issues, contains(contains('maxIf must stay between min and 7')));
    });

    test('invalid suggestions and sources are reported', () {
      final json = bundledJson();
      weekIn(json)
        ..['suggestedBy'] = ['current_training', 'missing_step']
        ..['suggested'] = {'rarely': 4, 'sometimes': 1, 'unknown': 3};
      final issues = issuesFor(json);
      expect(
        issues,
        contains(contains('suggestedBy must name earlier single choice steps')),
      );
      expect(
        issues,
        contains(contains('pattern "rarely" must respect min and allowed max')),
      );
      expect(issues, contains(contains('unknown suggested option "unknown"')));
    });

    test('count descriptions need both languages and every allowed count', () {
      final json = bundledJson();
      final week = weekIn(json);
      ((week['counts']! as List<Object?>).first!
          as Map<String, Object?>)['description'] = {
        'en': 'A gentle start',
      };
      (week['counts']! as List<Object?>).removeLast();
      final issues = issuesFor(json);
      expect(issues, contains(contains('missing "ar" copy')));
      expect(issues, contains(contains('missing count copy for 5 sessions')));
    });
  });

  test('shape errors point at the exact field', () {
    final json = minimalConfigJson(
      steps: [
        {'id': 'goal', 'type': 'slider', 'title': text('?')},
      ],
    );

    expect(
      () => FlowConfig.fromJson(json),
      throwsA(
        isA<ConfigFormatException>().having(
          (e) => e.toString(),
          'message',
          contains('steps[0].type: unknown step type "slider"'),
        ),
      ),
    );
  });
}
