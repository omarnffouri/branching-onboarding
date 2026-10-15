import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/condition.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/config_json.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/email_address.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/localized_text.dart';

/// The whole onboarding, as described by `assets/config/onboarding.json`.
///
/// Parsing only checks shape. Cross-references (does `showIf` point at a real
/// step? does every text exist in Arabic?) are checked by `ConfigValidator`,
/// so that every problem is reported at once instead of one per run.
final class FlowConfig {
  FlowConfig({
    required this.version,
    required this.languages,
    required this.steps,
    required this.plan,
    required this.paywall,
  }) : _stepsById = {for (final step in steps) step.id: step};

  factory FlowConfig.fromJson(Object? json) {
    final map = readMap(json, r'$');
    final languages = [
      for (final (i, language) in map.list('languages', r'$').indexed)
        if (language is String)
          language
        else
          throw ConfigFormatException(
            r'$.languages'
                '[$i]',
            'expected a string',
          ),
    ];
    return FlowConfig(
      version: map.integer('version', r'$'),
      languages: languages,
      steps: [
        for (final (i, step) in map.list('steps', r'$').indexed)
          FlowStep.fromJson(step, 'steps[$i]'),
      ],
      plan: PlanConfig.fromJson(map['plan'], 'plan'),
      paywall: PaywallConfig.fromJson(map['paywall'], 'paywall'),
    );
  }

  /// Bumped when a change makes saved progress meaningless.
  final int version;
  final List<String> languages;
  final List<FlowStep> steps;
  final PlanConfig plan;
  final PaywallConfig paywall;
  final Map<String, FlowStep> _stepsById;

  FlowStep? stepById(String id) => _stepsById[id];
}

// ---------------------------------------------------------------------------
// Steps
// ---------------------------------------------------------------------------

sealed class FlowStep {
  const FlowStep({
    required this.id,
    required this.title,
    this.subtitle,
    this.showIf,
    this.summaryLabel,
  });

  factory FlowStep.fromJson(Object? json, String path) {
    final map = readMap(json, path);
    final id = map.string('id', path);
    final title = LocalizedText.fromJson(map['title'], '$path.title');
    final subtitle = _optionalText(map, 'subtitle', path);
    final showIf = _optionalCondition(map, 'showIf', path);
    final summaryLabel = _optionalText(map, 'summaryLabel', path);

    return switch (map.string('type', path)) {
      'single' => SingleChoiceStep(
        id: id,
        title: title,
        subtitle: subtitle,
        showIf: showIf,
        summaryLabel: summaryLabel,
        options: _options(map, path),
      ),
      'multi' => MultiChoiceStep(
        id: id,
        title: title,
        subtitle: subtitle,
        showIf: showIf,
        summaryLabel: summaryLabel,
        options: _options(map, path),
        minSelected: map.integer('minSelected', path, fallback: 1),
      ),
      'text' => TextInputStep(
        id: id,
        title: title,
        subtitle: subtitle,
        showIf: showIf,
        summaryLabel: summaryLabel,
        kind: TextInputKind.fromJson(map.string('input', path), '$path.input'),
        placeholder: _optionalText(map, 'placeholder', path),
      ),
      'info' => InfoStep(
        id: id,
        title: title,
        subtitle: subtitle,
        showIf: showIf,
        body: LocalizedText.fromJson(map['body'], '$path.body'),
        icon: map.optionalString('icon', path),
      ),
      final type => throw ConfigFormatException(
        '$path.type',
        'unknown step type "$type" (expected single, multi, text or info)',
      ),
    };
  }

  final String id;
  final LocalizedText title;
  final LocalizedText? subtitle;

  /// Only on her path when this holds. Null means always.
  final Condition? showIf;

  /// Label for this answer on the plan screen. Null keeps it off the plan.
  final LocalizedText? summaryLabel;

  /// Returns [answer] if it is still a valid answer to this step given the
  /// answers that come before it, otherwise null.
  ///
  /// This is what removes answers that no longer make sense, e.g. "5 days a
  /// week" after she changes her routine to "rarely" and that option is gone.
  Answer? sanitize(Answer answer, Answers earlier);

  /// Parses the persisted form produced by [Answer.toJson].
  Answer? answerFromJson(Object? json);

  /// Every piece of copy on this step, for language and placeholder checks.
  Iterable<LocalizedText> get texts => [title, ?subtitle, ?summaryLabel];

  static LocalizedText? _optionalText(JsonMap map, String key, String path) =>
      map.containsKey(key)
      ? LocalizedText.fromJson(map[key], '$path.$key')
      : null;

  static Condition? _optionalCondition(JsonMap map, String key, String path) =>
      map.containsKey(key) ? Condition.fromJson(map[key], '$path.$key') : null;

  static List<ChoiceOption> _options(JsonMap map, String path) => [
    for (final (i, option) in map.list('options', path).indexed)
      ChoiceOption.fromJson(option, '$path.options[$i]'),
  ];
}

final class ChoiceOption {
  const ChoiceOption({
    required this.id,
    required this.label,
    this.description,
    this.showIf,
  });

  factory ChoiceOption.fromJson(Object? json, String path) {
    final map = readMap(json, path);
    return ChoiceOption(
      id: map.string('id', path),
      label: LocalizedText.fromJson(map['label'], '$path.label'),
      description: FlowStep._optionalText(map, 'description', path),
      showIf: FlowStep._optionalCondition(map, 'showIf', path),
    );
  }

  final String id;
  final LocalizedText label;
  final LocalizedText? description;

  /// Options can branch too: a beginner is not offered five days a week.
  final Condition? showIf;

  bool isVisible(Answers answers) => showIf?.evaluate(answers) ?? true;
}

/// Shared by single and multi choice steps.
sealed class ChoiceStep extends FlowStep {
  const ChoiceStep({
    required super.id,
    required super.title,
    required this.options,
    super.subtitle,
    super.showIf,
    super.summaryLabel,
  });

  final List<ChoiceOption> options;

  List<ChoiceOption> visibleOptions(Answers answers) => [
    for (final option in options)
      if (option.isVisible(answers)) option,
  ];

  @override
  Iterable<LocalizedText> get texts => [
    ...super.texts,
    for (final option in options) ...[option.label, ?option.description],
  ];
}

final class SingleChoiceStep extends ChoiceStep {
  const SingleChoiceStep({
    required super.id,
    required super.title,
    required super.options,
    super.subtitle,
    super.showIf,
    super.summaryLabel,
  });

  @override
  Answer? sanitize(Answer answer, Answers earlier) => switch (answer) {
    ChoiceAnswer(:final optionId)
        when visibleOptions(earlier).any((o) => o.id == optionId) =>
      answer,
    _ => null,
  };

  @override
  Answer? answerFromJson(Object? json) =>
      json is String ? ChoiceAnswer(json) : null;
}

final class MultiChoiceStep extends ChoiceStep {
  const MultiChoiceStep({
    required super.id,
    required super.title,
    required super.options,
    this.minSelected = 1,
    super.subtitle,
    super.showIf,
    super.summaryLabel,
  });

  final int minSelected;

  @override
  Answer? sanitize(Answer answer, Answers earlier) {
    if (answer is! MultiChoiceAnswer) return null;
    final visible = {for (final o in visibleOptions(earlier)) o.id};
    final kept = answer.optionIds.where(visible.contains).toList();
    if (kept.length < minSelected) return null;
    return kept.length == answer.optionIds.length
        ? answer
        : MultiChoiceAnswer(kept);
  }

  @override
  Answer? answerFromJson(Object? json) => json is List<Object?>
      ? MultiChoiceAnswer(json.whereType<String>())
      : null;
}

enum TextInputKind {
  name(maxLength: 30),
  email(maxLength: 254)
  ;

  const TextInputKind({required this.maxLength});

  factory TextInputKind.fromJson(String value, String path) =>
      values.asNameMap()[value] ??
      (throw ConfigFormatException(path, 'expected "name" or "email"'));

  final int maxLength;

  bool accepts(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > maxLength) return false;
    return switch (this) {
      TextInputKind.name => true,
      TextInputKind.email => EmailAddress.isValid(trimmed),
    };
  }
}

final class TextInputStep extends FlowStep {
  const TextInputStep({
    required super.id,
    required super.title,
    required this.kind,
    this.placeholder,
    super.subtitle,
    super.showIf,
    super.summaryLabel,
  });

  final TextInputKind kind;
  final LocalizedText? placeholder;

  @override
  Iterable<LocalizedText> get texts => [...super.texts, ?placeholder];

  @override
  Answer? sanitize(Answer answer, Answers earlier) => switch (answer) {
    TextAnswer(:final value) when kind.accepts(value) => answer,
    _ => null,
  };

  @override
  Answer? answerFromJson(Object? json) =>
      json is String ? TextAnswer(json) : null;
}

/// A screen with no question: reassurance, education, social proof.
final class InfoStep extends FlowStep {
  const InfoStep({
    required super.id,
    required super.title,
    required this.body,
    this.icon,
    super.subtitle,
    super.showIf,
  });

  final LocalizedText body;
  final String? icon;

  @override
  Iterable<LocalizedText> get texts => [...super.texts, body];

  @override
  Answer? sanitize(Answer answer, Answers earlier) =>
      answer is Acknowledged ? answer : null;

  @override
  Answer? answerFromJson(Object? json) =>
      json == true ? const Acknowledged() : null;
}

// ---------------------------------------------------------------------------
// Plan
// ---------------------------------------------------------------------------

/// Copy that only applies when [when] holds.
final class ConditionalText {
  const ConditionalText({required this.text, this.when});

  factory ConditionalText.fromJson(Object? json, String path) {
    final map = readMap(json, path);
    return ConditionalText(
      text: LocalizedText.fromJson(map['text'], '$path.text'),
      when: FlowStep._optionalCondition(map, 'when', path),
    );
  }

  final LocalizedText text;
  final Condition? when;

  bool matches(Answers answers) => when?.evaluate(answers) ?? true;
}

/// The first variant that matches wins; null when none do.
LocalizedText? firstMatch(List<ConditionalText> variants, Answers answers) {
  for (final variant in variants) {
    if (variant.matches(answers)) return variant.text;
  }
  return null;
}

final class PlanStat {
  const PlanStat({required this.icon, required this.variants});

  factory PlanStat.fromJson(Object? json, String path) {
    final map = readMap(json, path);
    return PlanStat(
      icon: map.string('icon', path),
      variants: [
        for (final (i, variant) in map.list('variants', path).indexed)
          ConditionalText.fromJson(variant, '$path.variants[$i]'),
      ],
    );
  }

  final String icon;
  final List<ConditionalText> variants;
}

final class PlanHighlight {
  const PlanHighlight({
    required this.icon,
    required this.title,
    required this.body,
    this.when,
  });

  factory PlanHighlight.fromJson(Object? json, String path) {
    final map = readMap(json, path);
    return PlanHighlight(
      icon: map.string('icon', path),
      title: LocalizedText.fromJson(map['title'], '$path.title'),
      body: LocalizedText.fromJson(map['body'], '$path.body'),
      when: FlowStep._optionalCondition(map, 'when', path),
    );
  }

  final String icon;
  final LocalizedText title;
  final LocalizedText body;
  final Condition? when;
}

/// How her answers turn into a plan. Lives in the config so that a new branch
/// can change the plan it leads to without touching code.
final class PlanConfig {
  const PlanConfig({
    required this.titles,
    required this.stats,
    required this.highlights,
  });

  factory PlanConfig.fromJson(Object? json, String path) {
    final map = readMap(json, path);
    return PlanConfig(
      titles: [
        for (final (i, title) in map.list('titles', path).indexed)
          ConditionalText.fromJson(title, '$path.titles[$i]'),
      ],
      stats: [
        for (final (i, stat) in map.list('stats', path).indexed)
          PlanStat.fromJson(stat, '$path.stats[$i]'),
      ],
      highlights: [
        for (final (i, highlight) in map.list('highlights', path).indexed)
          PlanHighlight.fromJson(highlight, '$path.highlights[$i]'),
      ],
    );
  }

  final List<ConditionalText> titles;
  final List<PlanStat> stats;
  final List<PlanHighlight> highlights;

  Iterable<Condition> get conditions => [
    for (final title in titles) ?title.when,
    for (final stat in stats)
      for (final variant in stat.variants) ?variant.when,
    for (final highlight in highlights) ?highlight.when,
  ];

  Iterable<LocalizedText> get texts => [
    for (final title in titles) title.text,
    for (final stat in stats)
      for (final variant in stat.variants) variant.text,
    for (final highlight in highlights) ...[highlight.title, highlight.body],
  ];
}

// ---------------------------------------------------------------------------
// Paywall
// ---------------------------------------------------------------------------

final class PricingPlan {
  const PricingPlan({
    required this.id,
    required this.title,
    required this.price,
    required this.billingMonths,
    this.trialDays = 0,
    this.badge,
  });

  factory PricingPlan.fromJson(Object? json, String path) {
    final map = readMap(json, path);
    return PricingPlan(
      id: map.string('id', path),
      title: LocalizedText.fromJson(map['title'], '$path.title'),
      price: map.number('price', path).toDouble(),
      billingMonths: map.integer('billingMonths', path),
      trialDays: map.integer('trialDays', path, fallback: 0),
      badge: FlowStep._optionalText(map, 'badge', path),
    );
  }

  final String id;
  final LocalizedText title;

  /// Price per billing period, in the paywall currency.
  final double price;
  final int billingMonths;
  final int trialDays;
  final LocalizedText? badge;

  bool get hasTrial => trialDays > 0;
  double get pricePerMonth => price / billingMonths;
}

final class PaywallConfig {
  const PaywallConfig({
    required this.currency,
    required this.plans,
    required this.defaultPlanId,
  });

  factory PaywallConfig.fromJson(Object? json, String path) {
    final map = readMap(json, path);
    return PaywallConfig(
      currency: map.string('currency', path),
      plans: [
        for (final (i, plan) in map.list('plans', path).indexed)
          PricingPlan.fromJson(plan, '$path.plans[$i]'),
      ],
      defaultPlanId: map.string('defaultPlanId', path),
    );
  }

  /// ISO 4217 code, e.g. AED.
  final String currency;
  final List<PricingPlan> plans;
  final String defaultPlanId;

  PricingPlan planById(String id) =>
      plans.firstWhere((p) => p.id == id, orElse: () => plans.first);

  /// The most expensive monthly rate, used to show "save 50%".
  double get referenceMonthlyPrice =>
      plans.map((p) => p.pricePerMonth).reduce((a, b) => a > b ? a : b);

  Iterable<LocalizedText> get texts => [
    for (final plan in plans) ...[plan.title, ?plan.badge],
  ];
}
