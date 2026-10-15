import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

/// Decides which steps she sees, given what she has answered.
///
/// The path is never stored, only derived. Answers go in and the path comes
/// out, so there is no second source of truth that can drift when she goes
/// back and changes her mind.
final class FlowEngine {
  const FlowEngine(this.config);

  final FlowConfig config;

  /// Walks the config in order. A step joins the path when its `showIf` holds
  /// against the answers kept so far, and its answer is kept only if it is
  /// still valid there.
  ///
  /// Because conditions only ever see kept answers, an answer from a branch
  /// she has left can never steer the flow, and it is dropped from the
  /// result. `ConfigValidator` guarantees conditions only look backwards, so
  /// one pass is enough.
  FlowResolution resolve(Answers answers) {
    final path = <FlowStep>[];
    final kept = <String, Answer>{};
    for (final step in config.steps) {
      if (!(step.showIf?.evaluate(kept) ?? true)) continue;
      path.add(step);
      final answer = answers[step.id];
      final valid = answer == null ? null : step.sanitize(answer, kept);
      if (valid != null) kept[step.id] = valid;
    }
    return FlowResolution(List.unmodifiable(path), Map.unmodifiable(kept));
  }
}

/// Her path through the flow and the answers that belong to it.
final class FlowResolution {
  FlowResolution(this.path, this.answers)
    : _indexById = {for (final (i, step) in path.indexed) step.id: i};

  final List<FlowStep> path;

  /// Only answers to steps on [path], all valid.
  final Answers answers;

  final Map<String, int> _indexById;

  bool contains(String stepId) => _indexById.containsKey(stepId);

  /// -1 when the step is not on her path.
  int indexOf(String stepId) => _indexById[stepId] ?? -1;

  bool isAnswered(String stepId) => answers.containsKey(stepId);

  bool get isComplete => path.every((step) => isAnswered(step.id));

  FlowStep? stepAfter(String stepId) {
    final index = indexOf(stepId);
    return index >= 0 && index + 1 < path.length ? path[index + 1] : null;
  }

  FlowStep? stepBefore(String stepId) {
    final index = indexOf(stepId);
    return index > 0 ? path[index - 1] : null;
  }

  FlowStep? get firstUnanswered {
    for (final step in path) {
      if (!isAnswered(step.id)) return step;
    }
    return null;
  }

  /// The next step after [stepId] she has not answered yet. Used when she
  /// edits an answer from the plan: she only sees what the change opened up.
  FlowStep? firstUnansweredAfter(String stepId) {
    for (final step in path.skip(indexOf(stepId) + 1)) {
      if (!isAnswered(step.id)) return step;
    }
    return null;
  }
}
