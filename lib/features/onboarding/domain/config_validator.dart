import 'package:traininpink_onboarding/features/onboarding/domain/condition.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/localized_text.dart';

final class ConfigIssue {
  const ConfigIssue(this.path, this.message);

  final String path;
  final String message;

  @override
  String toString() => '$path: $message';
}

final class InvalidConfigException implements Exception {
  const InvalidConfigException(this.issues);

  final List<ConfigIssue> issues;

  @override
  String toString() =>
      'Onboarding config has ${issues.length} problem(s):\n'
      '${issues.map((issue) => '  • $issue').join('\n')}';
}

/// Catches config mistakes before a member does.
///
/// The rule that makes branching safe: a condition may only look at steps
/// that come *earlier* in the config. That rules out cycles and lets
/// `FlowEngine` resolve the whole path in one pass.
///
/// Runs on every app start in debug and in a test against the bundled
/// config, so a bad edit fails CI rather than an onboarding session.
abstract final class ConfigValidator {
  static final _idPattern = RegExp(r'^[a-z][a-z0-9_]*$');

  static void ensureValid(FlowConfig config) {
    final issues = validate(config);
    if (issues.isNotEmpty) throw InvalidConfigException(issues);
  }

  static List<ConfigIssue> validate(FlowConfig config) {
    final issues = <ConfigIssue>[];
    void report(String path, String message) =>
        issues.add(ConfigIssue(path, message));

    if (!config.languages.contains(LocalizedText.fallbackLanguage)) {
      report('languages', 'must include "${LocalizedText.fallbackLanguage}"');
    }
    if (config.steps.isEmpty) report('steps', 'must not be empty');

    void checkLanguages(LocalizedText text, String path) {
      for (final language in config.languages) {
        if (!text.languages.contains(language)) {
          report(path, 'missing "$language" copy');
        }
      }
    }

    // Steps a condition or placeholder at the current position may refer to.
    final earlier = <String, FlowStep>{};

    void checkCondition(Condition condition, String path) {
      for (final leaf in condition.leaves) {
        final target = earlier[leaf.stepId];
        if (target == null) {
          final exists = config.stepById(leaf.stepId) != null;
          report(
            path,
            exists
                ? 'refers to "${leaf.stepId}", which comes later; conditions '
                      'may only depend on earlier steps'
                : 'refers to unknown step "${leaf.stepId}"',
          );
          continue;
        }
        _checkLeaf(leaf, target, path, report);
      }
    }

    void checkPlaceholders(Iterable<LocalizedText> texts, String path) {
      for (final placeholder in texts.expand(placeholdersIn)) {
        final target = earlier[placeholder];
        if (target == null || target is InfoStep) {
          report(
            path,
            'placeholder {$placeholder} must name an earlier question',
          );
        }
      }
    }

    final seenIds = <String>{};
    for (final (i, step) in config.steps.indexed) {
      final path = 'steps[$i] (${step.id})';
      if (!_idPattern.hasMatch(step.id)) {
        report(path, 'id must be lower_snake_case');
      }
      if (!seenIds.add(step.id)) report(path, 'duplicate step id');

      if (step.showIf case final showIf?) {
        checkCondition(showIf, '$path.showIf');
      }
      for (final text in step.texts) {
        checkLanguages(text, path);
      }
      checkPlaceholders(step.texts, path);

      if (step is ChoiceStep) {
        if (step.options.isEmpty) report(path, 'needs at least one option');
        final optionIds = <String>{};
        for (final option in step.options) {
          if (!optionIds.add(option.id)) {
            report(path, 'duplicate option "${option.id}"');
          }
          if (option.showIf case final showIf?) {
            checkCondition(showIf, '$path.options(${option.id}).showIf');
          }
        }
      }
      if (step is MultiChoiceStep &&
          (step.minSelected < 0 || step.minSelected > step.options.length)) {
        report(path, 'minSelected must be between 0 and the option count');
      }

      earlier[step.id] = step;
    }

    // The plan is built after the flow, so it can refer to any step.
    final plan = config.plan;
    for (final condition in plan.conditions) {
      checkCondition(condition, 'plan');
    }
    for (final text in plan.texts) {
      checkLanguages(text, 'plan');
    }
    checkPlaceholders(plan.texts, 'plan');
    if (plan.titles.isEmpty || plan.titles.last.when != null) {
      report('plan.titles', 'must end with a title that has no "when"');
    }

    final paywall = config.paywall;
    if (paywall.plans.length < 2) {
      report('paywall.plans', 'needs at least two plans');
    }
    final planIds = <String>{};
    for (final plan in paywall.plans) {
      final path = 'paywall.plans(${plan.id})';
      if (!planIds.add(plan.id)) report(path, 'duplicate plan id');
      if (plan.price <= 0) report(path, 'price must be positive');
      if (plan.billingMonths <= 0) {
        report(path, 'billingMonths must be positive');
      }
    }
    if (!planIds.contains(paywall.defaultPlanId)) {
      report('paywall.defaultPlanId', 'is not one of the plans');
    }
    if (!paywall.plans.any((plan) => plan.hasTrial)) {
      report('paywall.plans', 'at least one plan needs a trial');
    }
    for (final text in paywall.texts) {
      checkLanguages(text, 'paywall');
    }

    return issues;
  }

  static void _checkLeaf(
    AnswerCondition leaf,
    FlowStep target,
    String path,
    void Function(String path, String message) report,
  ) {
    final optionIds = target is ChoiceStep
        ? {for (final option in target.options) option.id}
        : const <String>{};
    final unknown = leaf.values.where((v) => !optionIds.contains(v));

    switch ((leaf, target)) {
      case (AnswerEquals() || AnswerIn(), SingleChoiceStep()):
      case (AnswerIncludes(), MultiChoiceStep()):
        for (final value in unknown) {
          report(path, '"${target.id}" has no option "$value"');
        }
      case (AnswerEquals(), TextInputStep()):
        break;
      case (AnswerEquals() || AnswerIn(), MultiChoiceStep()):
        report(path, '"${target.id}" is multi choice; use "includes"');
      case (AnswerIncludes(), _):
        report(path, '"includes" only works on multi choice steps');
      case (_, InfoStep()):
        report(path, '"${target.id}" is an info step and has no answer');
      case (AnswerIn(), TextInputStep()):
        report(path, '"in" only works on single choice steps');
    }
  }
}
