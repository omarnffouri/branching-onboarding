import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

/// Presentation only: grouping never changes the engine's ordered path.
final class StepGroup {
  StepGroup(Iterable<FlowStep> steps) : steps = List.unmodifiable(steps);

  final List<FlowStep> steps;

  FlowStep get first => steps.first;
  FlowStep get last => steps.last;

  bool contains(String stepId) => steps.any((step) => step.id == stepId);

  static List<StepGroup> fromPath(List<FlowStep> path) {
    final groups = <StepGroup>[];
    var pending = <FlowStep>[];
    for (final step in path) {
      if (pending.isNotEmpty &&
          (step.group == null || step.group != pending.last.group)) {
        groups.add(StepGroup(pending));
        pending = [];
      }
      pending.add(step);
    }
    if (pending.isNotEmpty) groups.add(StepGroup(pending));
    return List.unmodifiable(groups);
  }

  static StepGroup containing(List<FlowStep> path, String stepId) =>
      fromPath(path).firstWhere((group) => group.contains(stepId));
}
