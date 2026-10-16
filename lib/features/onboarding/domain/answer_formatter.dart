import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/localized_text.dart';

/// Turns her answers into words in one language, and fills `{step_id}`
/// placeholders in config copy with them.
final class AnswerFormatter {
  const AnswerFormatter(this.config, this.languageCode);

  final FlowConfig config;
  final String languageCode;

  /// Her answer to [stepId] as text, or null if she has not answered it.
  String? describe(String stepId, Answers answers) {
    final step = config.stepById(stepId);
    final answer = answers[stepId];
    if (step == null || answer == null) return null;

    return switch ((step, answer)) {
      (ChoiceStep(:final options), ChoiceAnswer(:final optionId)) => _label(
        options,
        optionId,
      ),
      (ChoiceStep(:final options), MultiChoiceAnswer(:final optionIds)) =>
        joinList([
          // Config order, not tap order, so the plan reads consistently.
          for (final option in options)
            if (optionIds.contains(option.id))
              option.label.resolve(languageCode),
        ]),
      (_, TextAnswer(:final value)) => value.trim(),
      (NumberStep(:final unit), NumberAnswer(:final value)) =>
        '$value ${unit.resolve(languageCode)}',
      (final FrequencyStep frequency, NumberAnswer(:final value)) =>
        frequency.countCopy(value)?.label.resolve(languageCode),
      _ => null,
    };
  }

  int? count(String stepId, Answers answers) =>
      switch ((config.stepById(stepId), answers[stepId])) {
        (FrequencyStep(), NumberAnswer(:final value)) => value,
        _ => null,
      };

  /// Resolves [text] and replaces each `{step_id}` with her answer.
  String fill(LocalizedText text, Answers answers) => text
      .resolve(languageCode)
      .replaceAllMapped(
        placeholderPattern,
        (match) => describe(match.group(1)!, answers) ?? '',
      );

  /// "a, b and c" / "أ، ب وج".
  String joinList(List<String> items) {
    if (items.length <= 1) return items.join();
    final (separator, lastSeparator) = switch (languageCode) {
      'ar' => ('، ', ' و'),
      _ => (', ', ' and '),
    };
    return '${items.take(items.length - 1).join(separator)}'
        '$lastSeparator${items.last}';
  }

  String? _label(List<ChoiceOption> options, String optionId) {
    for (final option in options) {
      if (option.id == optionId) return option.label.resolve(languageCode);
    }
    return null;
  }
}
