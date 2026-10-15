import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/config_json.dart';

/// A rule over her answers, written in the config as `showIf` or `when`.
///
/// Deliberately small: comparing one answer, plus `all` / `any` / `not` to
/// combine them. That covers every branch product has asked for so far while
/// staying readable by someone who is not an engineer.
///
/// ```json
/// { "answer": "goal", "equals": "get_back_into_it" }
/// { "answer": "goal", "in": ["lose_weight", "feel_lighter"] }
/// { "answer": "injury_areas", "includes": "knees" }
/// { "any": [ ... ] }  { "all": [ ... ] }  { "not": { ... } }
/// ```
sealed class Condition {
  const Condition();

  factory Condition.fromJson(Object? json, String path) {
    final map = readMap(json, path);
    if (map.containsKey('all')) {
      return AllOf(_children(map.list('all', path), '$path.all'));
    }
    if (map.containsKey('any')) {
      return AnyOf(_children(map.list('any', path), '$path.any'));
    }
    if (map.containsKey('not')) {
      return Not(Condition.fromJson(map['not'], '$path.not'));
    }

    final stepId = map.string('answer', path);
    if (map.containsKey('equals')) {
      return AnswerEquals(stepId, map.string('equals', path));
    }
    if (map.containsKey('in')) {
      final values = [
        for (final (i, value) in map.list('in', path).indexed)
          if (value is String)
            value
          else
            throw ConfigFormatException('$path.in[$i]', 'expected a string'),
      ];
      return AnswerIn(stepId, values);
    }
    if (map.containsKey('includes')) {
      return AnswerIncludes(stepId, map.string('includes', path));
    }
    throw ConfigFormatException(
      path,
      'expected one of "equals", "in", "includes", "all", "any" or "not"',
    );
  }

  static List<Condition> _children(List<Object?> json, String path) {
    if (json.isEmpty) throw ConfigFormatException(path, 'must not be empty');
    return [
      for (final (i, child) in json.indexed)
        Condition.fromJson(child, '$path[$i]'),
    ];
  }

  bool evaluate(Answers answers);

  /// Every answer comparison inside this condition, for validation.
  Iterable<AnswerCondition> get leaves;

  /// Human-readable form, shown in the flow inspector.
  String describe();
}

/// Compares the answer to a single step.
sealed class AnswerCondition extends Condition {
  const AnswerCondition(this.stepId);

  final String stepId;

  /// Option ids (or text) this condition compares against.
  List<String> get values;

  @override
  Iterable<AnswerCondition> get leaves => [this];
}

final class AnswerEquals extends AnswerCondition {
  const AnswerEquals(super.stepId, this.value);

  final String value;

  @override
  List<String> get values => [value];

  @override
  bool evaluate(Answers answers) => switch (answers[stepId]) {
    ChoiceAnswer(:final optionId) => optionId == value,
    TextAnswer(value: final text) => text == value,
    _ => false,
  };

  @override
  String describe() => '$stepId = $value';
}

final class AnswerIn extends AnswerCondition {
  const AnswerIn(super.stepId, this.values);

  @override
  final List<String> values;

  @override
  bool evaluate(Answers answers) => switch (answers[stepId]) {
    ChoiceAnswer(:final optionId) => values.contains(optionId),
    _ => false,
  };

  @override
  String describe() => '$stepId in [${values.join(', ')}]';
}

final class AnswerIncludes extends AnswerCondition {
  const AnswerIncludes(super.stepId, this.value);

  final String value;

  @override
  List<String> get values => [value];

  @override
  bool evaluate(Answers answers) => switch (answers[stepId]) {
    MultiChoiceAnswer(:final optionIds) => optionIds.contains(value),
    _ => false,
  };

  @override
  String describe() => '$stepId includes $value';
}

final class AllOf extends Condition {
  const AllOf(this.conditions);

  final List<Condition> conditions;

  @override
  bool evaluate(Answers answers) =>
      conditions.every((c) => c.evaluate(answers));

  @override
  Iterable<AnswerCondition> get leaves => conditions.expand((c) => c.leaves);

  @override
  String describe() => conditions.map((c) => c.describe()).join(' and ');
}

final class AnyOf extends Condition {
  const AnyOf(this.conditions);

  final List<Condition> conditions;

  @override
  bool evaluate(Answers answers) => conditions.any((c) => c.evaluate(answers));

  @override
  Iterable<AnswerCondition> get leaves => conditions.expand((c) => c.leaves);

  @override
  String describe() => '(${conditions.map((c) => c.describe()).join(' or ')})';
}

final class Not extends Condition {
  const Not(this.condition);

  final Condition condition;

  @override
  bool evaluate(Answers answers) => !condition.evaluate(answers);

  @override
  Iterable<AnswerCondition> get leaves => condition.leaves;

  @override
  String describe() => 'not (${condition.describe()})';
}
