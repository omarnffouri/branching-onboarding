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
