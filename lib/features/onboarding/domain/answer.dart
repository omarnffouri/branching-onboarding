import 'package:meta/meta.dart';

/// Her answer to one step. Every step on the path produces one, including
/// info screens (an [Acknowledged]), so "has she been through this step?" has
/// a single answer everywhere: is there an entry for it.
@immutable
sealed class Answer {
  const Answer();

  /// Persisted form. Parsing it back needs the step it belongs to, see
  /// `FlowStep.answerFromJson`.
  Object toJson();
}

final class ChoiceAnswer extends Answer {
  const ChoiceAnswer(this.optionId);

  final String optionId;

  @override
  Object toJson() => optionId;

  @override
  bool operator ==(Object other) =>
      other is ChoiceAnswer && other.optionId == optionId;

  @override
  int get hashCode => optionId.hashCode;

  @override
  String toString() => 'ChoiceAnswer($optionId)';
}

final class MultiChoiceAnswer extends Answer {
  MultiChoiceAnswer(Iterable<String> optionIds)
    : optionIds = Set.unmodifiable(optionIds);

  final Set<String> optionIds;

  @override
  Object toJson() => optionIds.toList();

  @override
  bool operator ==(Object other) =>
      other is MultiChoiceAnswer &&
      other.optionIds.length == optionIds.length &&
      other.optionIds.containsAll(optionIds);

  @override
  int get hashCode => Object.hashAllUnordered(optionIds);

  @override
  String toString() => 'MultiChoiceAnswer($optionIds)';
}

final class TextAnswer extends Answer {
  const TextAnswer(this.value);

  final String value;

  @override
  Object toJson() => value;

  @override
  bool operator ==(Object other) => other is TextAnswer && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'TextAnswer($value)';
}

/// She has seen an info screen and moved on.
final class Acknowledged extends Answer {
  const Acknowledged();

  @override
  Object toJson() => true;

  @override
  bool operator ==(Object other) => other is Acknowledged;

  @override
  int get hashCode => (Acknowledged).hashCode;

  @override
  String toString() => 'Acknowledged()';
}

/// Answers keyed by step id.
typedef Answers = Map<String, Answer>;
