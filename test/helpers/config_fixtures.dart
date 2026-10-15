import 'dart:convert';
import 'dart:io';

import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

/// The real config the app ships, so tests break when the content does.
FlowConfig loadBundledConfig() => FlowConfig.fromJson(
  jsonDecode(File('assets/config/onboarding.json').readAsStringSync()),
);

/// A small, valid config to bend in validator tests.
Map<String, Object?> minimalConfigJson({
  List<Map<String, Object?>>? steps,
  Map<String, Object?>? plan,
  Map<String, Object?>? paywall,
}) => {
  'version': 1,
  'languages': ['en', 'ar'],
  'steps':
      steps ??
      [
        choiceStepJson('goal', ['a', 'b']),
        choiceStepJson('follow_up', ['x'], showIf: answerEquals('goal', 'a')),
      ],
  'plan':
      plan ??
      {
        'titles': [
          {'text': text('Your plan')},
        ],
        'stats': <Object?>[],
        'highlights': <Object?>[],
      },
  'paywall':
      paywall ??
      {
        'currency': 'AED',
        'defaultPlanId': 'yearly',
        'plans': [
          {
            'id': 'yearly',
            'title': text('Yearly'),
            'price': 349,
            'billingMonths': 12,
            'trialDays': 7,
          },
          {
            'id': 'monthly',
            'title': text('Monthly'),
            'price': 59,
            'billingMonths': 1,
          },
        ],
      },
};

Map<String, Object?> text(String en, {String? ar}) => {
  'en': en,
  'ar': ar ?? 'ع $en',
};

Map<String, Object?> answerEquals(String stepId, String value) => {
  'answer': stepId,
  'equals': value,
};

Map<String, Object?> choiceStepJson(
  String id,
  List<String> optionIds, {
  String type = 'single',
  Map<String, Object?>? showIf,
  Map<String, Map<String, Object?>> optionShowIf = const {},
}) => {
  'id': id,
  'type': type,
  'title': text('Question $id'),
  'summaryLabel': text(id),
  'showIf': ?showIf,
  'options': [
    for (final optionId in optionIds)
      {
        'id': optionId,
        'label': text(optionId),
        'showIf': ?optionShowIf[optionId],
      },
  ],
};
