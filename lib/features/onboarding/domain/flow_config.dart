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
    this.image,
    this.imageFocus = ImageFocus.center,
    this.group,
    this.groupTitle,
  });

  factory FlowStep.fromJson(Object? json, String path) {
    final map = readMap(json, path);
    final id = map.string('id', path);
    final title = LocalizedText.fromJson(map['title'], '$path.title');
    final subtitle = _optionalText(map, 'subtitle', path);
    final showIf = _optionalCondition(map, 'showIf', path);
    final summaryLabel = _optionalText(map, 'summaryLabel', path);
    final image = map.optionalString('image', path);
    final group = map.optionalString('group', path);
    final groupTitle = _optionalText(map, 'groupTitle', path);
    final imageFocus = map.containsKey('imageFocus')
        ? ImageFocus.fromJson(map['imageFocus'], '$path.imageFocus')
        : ImageFocus.center;

    return switch (map.string('type', path)) {
      'single' => SingleChoiceStep(
        id: id,
        title: title,
        group: group,
        groupTitle: groupTitle,
        subtitle: subtitle,
        showIf: showIf,
        summaryLabel: summaryLabel,
        image: image,
        imageFocus: imageFocus,
        options: _options(map, path),
      ),
      'multi' => MultiChoiceStep(
        id: id,
        title: title,
        group: group,
        groupTitle: groupTitle,
        subtitle: subtitle,
        showIf: showIf,
        summaryLabel: summaryLabel,
        image: image,
        imageFocus: imageFocus,
        options: _options(map, path),
        minSelected: map.integer('minSelected', path, fallback: 1),
      ),
      'text' => TextInputStep(
        id: id,
        title: title,
        group: group,
        groupTitle: groupTitle,
        subtitle: subtitle,
        showIf: showIf,
        summaryLabel: summaryLabel,
        image: image,
        imageFocus: imageFocus,
        kind: TextInputKind.fromJson(map.string('input', path), '$path.input'),
        placeholder: _optionalText(map, 'placeholder', path),
      ),
      'number' => NumberStep(
        id: id,
        title: title,
        group: group,
        groupTitle: groupTitle,
        subtitle: subtitle,
        showIf: showIf,
        summaryLabel: summaryLabel,
        image: image,
        imageFocus: imageFocus,
        unit: LocalizedText.fromJson(map['unit'], '$path.unit'),
        min: map.integer('min', path),
        max: map.integer('max', path),
        initial: map.integer('initial', path),
        measureWidth: switch (map['measureWidth']) {
          null => null,
          final num value when value > 0 && value <= 1 => value.toDouble(),
          _ => throw ConfigFormatException(
            '$path.measureWidth',
            'expected a fraction between 0 and 1',
          ),
        },
        measureAt: switch (map['measureAt']) {
          null => 0.5,
          final num value when value > 0 && value < 1 => value.toDouble(),
          _ => throw ConfigFormatException(
            '$path.measureAt',
            'expected a fraction between 0 and 1',
          ),
        },
      ),
      'frequency' => FrequencyStep(
        id: id,
        title: title,
        group: group,
        groupTitle: groupTitle,
        subtitle: subtitle,
        showIf: showIf,
        summaryLabel: summaryLabel,
        min: map.integer('min', path),
        max: map.integer('max', path),
        maxIf: [
          for (final (i, rule) in map.optionalList('maxIf', path).indexed)
            FrequencyMaxRule.fromJson(rule, '$path.maxIf[$i]'),
        ],
        suggestedBy: [
          for (final source in map.list('suggestedBy', path))
            if (source is String)
              source
            else
              throw ConfigFormatException(
                '$path.suggestedBy',
                'expected step ids',
              ),
        ],
        suggested: {
          for (final entry in readMap(
            map['suggested'],
            '$path.suggested',
          ).entries)
            entry.key: readMap(
              map['suggested'],
              '$path.suggested',
            ).integer(entry.key, '$path.suggested'),
        },
        counts: [
          for (final (i, count) in map.list('counts', path).indexed)
            FrequencyCount.fromJson(count, '$path.counts[$i]'),
        ],
      ),
      'info' => InfoStep(
        id: id,
        title: title,
        group: group,
        groupTitle: groupTitle,
        subtitle: subtitle,
        showIf: showIf,
        image: image,
        imageFocus: imageFocus,
        body: _optionalText(map, 'body', path),
        points: [
          for (final (i, point) in map.optionalList('points', path).indexed)
            InfoPoint.fromJson(point, '$path.points[$i]'),
        ],
        icon: map.optionalString('icon', path),
      ),
      final type => throw ConfigFormatException(
        '$path.type',
        'unknown step type "$type" '
            '(expected single, multi, text, number, frequency or info)',
      ),
    };
  }

  final String id;

  /// Consecutive steps with the same group share a presentation page.
  final String? group;
  final LocalizedText? groupTitle;
  final LocalizedText title;
  final LocalizedText? subtitle;

  /// Only on her path when this holds. Null means always.
  final Condition? showIf;

  /// Label for this answer on the plan screen. Null keeps it off the plan.
  final LocalizedText? summaryLabel;

  /// Optional photo shown above the question, a file name in
  /// `assets/images/steps/`. Pictures are content, so they live in the
  /// config with the copy.
  final String? image;

  /// Which part of the photo to keep when it's cropped, -1..1 on each axis.
  final ImageFocus imageFocus;

  /// Returns [answer] if it is still a valid answer to this step given the
  /// answers that come before it, otherwise null.
  ///
  /// This is what removes answers that no longer make sense, e.g. "5 days a
  /// week" after she changes her routine to "rarely" and that option is gone.
  Answer? sanitize(Answer answer, Answers earlier);

  /// Parses the persisted form produced by [Answer.toJson].
  Answer? answerFromJson(Object? json);

  /// Every piece of copy on this step, for language and placeholder checks.
  Iterable<LocalizedText> get texts => [
    title,
    ?subtitle,
    ?summaryLabel,
    ?groupTitle,
  ];

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
    super.image,
    super.imageFocus,
    super.group,
    super.groupTitle,
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
    super.image,
    super.imageFocus,
    super.group,
    super.groupTitle,
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
    super.image,
    super.imageFocus,
    super.group,
    super.groupTitle,
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
    super.image,
    super.imageFocus,
    super.group,
    super.groupTitle,
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

/// A whole number picked within a range, e.g. her waist measurement.
final class NumberStep extends FlowStep {
  const NumberStep({
    required super.id,
    required super.title,
    required this.unit,
    required this.min,
    required this.max,
    required this.initial,
    this.measureAt = 0.5,
    this.measureWidth,
    super.subtitle,
    super.showIf,
    super.summaryLabel,
    super.image,
    super.imageFocus,
    super.group,
    super.groupTitle,
  });

  final LocalizedText unit;
  final int min;
  final int max;

  /// Where the picker starts before she moves it.
  final int initial;

  /// How far down the photo (0 top, 1 bottom) the measurement is taken,
  /// e.g. her waist line. Lives with the photo so swapping it is config.
  final double measureAt;

  /// How much of the screen's width the measured part spans (her waist),
  /// so the tape wraps exactly around it. Null spans the screen.
  final double? measureWidth;

  @override
  Iterable<LocalizedText> get texts => [...super.texts, unit];

  @override
  Answer? sanitize(Answer answer, Answers earlier) => switch (answer) {
    NumberAnswer(:final value) when value >= min && value <= max => answer,
    _ => null,
  };

  @override
  Answer? answerFromJson(Object? json) =>
      json is int ? NumberAnswer(json) : null;
}

/// A weekly session count, with the same backward-only caps as choice options.
final class FrequencyStep extends FlowStep {
  const FrequencyStep({
    required super.id,
    required super.title,
    required this.min,
    required this.max,
    required this.counts,
    this.maxIf = const [],
    this.suggestedBy = const [],
    this.suggested = const {},
    super.subtitle,
    super.showIf,
    super.summaryLabel,
    super.group,
    super.groupTitle,
  });

  final int min;

  /// Default cap; the first matching rule overrides it.
  final int max;
  final List<FrequencyMaxRule> maxIf;
  final List<String> suggestedBy;
  final Map<String, int> suggested;
  final List<FrequencyCount> counts;

  int allowedMax(Answers answers) {
    for (final rule in maxIf) {
      if (rule.when.evaluate(answers)) return rule.max;
    }
    return max;
  }

  int? suggestionFor(Answers answers) {
    for (final source in suggestedBy) {
      if (answers[source] case ChoiceAnswer(:final optionId)) {
        final count = suggested[optionId];
        if (count != null && sanitize(NumberAnswer(count), answers) != null) {
          return count;
        }
      }
    }
    return null;
  }

  FrequencyCount? countCopy(int count) {
    for (final copy in counts) {
      if (copy.count == count) return copy;
    }
    return null;
  }

  @override
  Iterable<LocalizedText> get texts => [
    ...super.texts,
    for (final count in counts) ...[count.label, count.description],
  ];

  @override
  Answer? sanitize(Answer answer, Answers earlier) => switch (answer) {
    NumberAnswer(:final value)
        when value >= min && value <= allowedMax(earlier) =>
      answer,
    _ => null,
  };

  @override
  Answer? answerFromJson(Object? json) {
    if (json is int) return NumberAnswer(json);
    // Keep the frequency from the previous weekday picker on app upgrades.
    if (json is List<Object?> &&
        json.every((day) => day is int && day >= 0 && day <= 6)) {
      return NumberAnswer(json.toSet().length);
    }
    return null;
  }
}

final class FrequencyMaxRule {
  const FrequencyMaxRule({required this.when, required this.max});

  factory FrequencyMaxRule.fromJson(Object? json, String path) {
    final map = readMap(json, path);
    return FrequencyMaxRule(
      when: Condition.fromJson(map['when'], '$path.when'),
      max: map.integer('max', path),
    );
  }

  final Condition when;
  final int max;
}

final class FrequencyCount {
  const FrequencyCount({
    required this.count,
    required this.label,
    required this.description,
  });

  factory FrequencyCount.fromJson(Object? json, String path) {
    final map = readMap(json, path);
    return FrequencyCount(
      count: map.integer('count', path),
      label: LocalizedText.fromJson(map['label'], '$path.label'),
      description: LocalizedText.fromJson(
        map['description'],
        '$path.description',
      ),
    );
  }

  final int count;
  final LocalizedText label;
  final LocalizedText description;
}

/// A screen with no question: reassurance, education, social proof.
final class InfoStep extends FlowStep {
  const InfoStep({
    required super.id,
    required super.title,
    this.body,
    this.points = const [],
    this.icon,
    super.subtitle,
    super.showIf,
    super.image,
    super.imageFocus,
    super.group,
    super.groupTitle,
  });

  /// A paragraph, or (better for skimming) a few [points].
  final LocalizedText? body;
  final List<InfoPoint> points;
  final String? icon;

  @override
  Iterable<LocalizedText> get texts => [
    ...super.texts,
    ?body,
    for (final point in points) ...[point.title, point.text],
  ];

  @override
  Answer? sanitize(Answer answer, Answers earlier) =>
      answer is Acknowledged ? answer : null;

  @override
  Answer? answerFromJson(Object? json) =>
      json == true ? const Acknowledged() : null;
}

/// Art direction for a cropped photo: -1 is the left/top edge, 1 the
/// right/bottom, 0 the centre.
final class ImageFocus {
  const ImageFocus(this.x, this.y);

  factory ImageFocus.fromJson(Object? json, String path) {
    final map = readMap(json, path);
    double axis(String key) {
      final value = map[key] ?? 0;
      if (value is num && value >= -1 && value <= 1) return value.toDouble();
      throw ConfigFormatException(
        '$path.$key',
        'expected a number from -1 to 1',
      );
    }

    return ImageFocus(axis('x'), axis('y'));
  }

  static const center = ImageFocus(0, 0);

  final double x;
  final double y;
}

/// One beat of an info screen, shown as a step in a short flow.
final class InfoPoint {
  const InfoPoint({
    required this.icon,
    required this.title,
    required this.text,
  });

  factory InfoPoint.fromJson(Object? json, String path) {
    final map = readMap(json, path);
    return InfoPoint(
      icon: map.string('icon', path),
      title: LocalizedText.fromJson(map['title'], '$path.title'),
      text: LocalizedText.fromJson(map['text'], '$path.text'),
    );
  }

  final String icon;
  final LocalizedText title;
  final LocalizedText text;
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
