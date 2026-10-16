import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/design/focus_after_transition.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/core/design/widgets/entrance.dart';
import 'package:traininpink_onboarding/core/design/widgets/pressable.dart';
import 'package:traininpink_onboarding/core/design/widgets/primary_button.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/l10n/language_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/controllers/text_step_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/step_layout.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/member_card.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/member_input.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/shake.dart';

/// Free text: her name, or her email.
///
/// The email error appears only once she tries to continue, never while
/// she is still typing, and then clears the moment the address is valid.
/// A likely typo (`gmial.com`) gets a one-tap fix: the cheapest way to stop
/// losing members at the email step.
class TextStepView extends ConsumerStatefulWidget {
  const TextStepView({required this.step, super.key});

  final TextInputStep step;

  @override
  ConsumerState<TextStepView> createState() => _TextStepViewState();
}

class _TextStepViewState extends ConsumerState<TextStepView>
    with FocusAfterTransition {
  // The logic lives in TextStepController; this keeps only the screen's
  // own things: the text box, focus, and the shake on a rejected Continue.
  late final _text = TextEditingController(
    text: ref.read(textStepControllerProvider(widget.step.id)).input,
  );
  final _focus = FocusNode();
  var _shakes = 0;

  TextStepController get _page =>
      ref.read(textStepControllerProvider(widget.step.id).notifier);

  bool get _isEmail => widget.step.kind == TextInputKind.email;

  @override
  FocusNode get transitionFocusNode => _focus;

  @override
  bool get shouldFocusAfterTransition => _text.text.isEmpty;

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_page.submit()) return;
    // Rejected: a firm nudge and a shake, while the page shows why.
    HapticFeedback.mediumImpact().ignore();
    setState(() => _shakes++);
  }

  void _applySuggestion(String suggestion) {
    _text
      ..text = suggestion
      ..selection = TextSelection.collapsed(offset: suggestion.length);
    _page.changed(suggestion);
    HapticFeedback.selectionClick().ignore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageProvider);
    final formatter = ref.watch(answerFormatterProvider);
    final answers = ref.watch(
      onboardingControllerProvider.select((state) => state.answers),
    );
    final step = widget.step;
    final page = ref.watch(textStepControllerProvider(step.id));
    final status = page.status;
    final value = page.input;

    return StepLayout(
      title: formatter.fill(step.title, answers),
      subtitle: step.subtitle?.resolve(language),
      footer: PrimaryButton(
        label: l10n.continueButton,
        onPressed: status.canContinue ? _submit : null,
      ),
      children: [
        Entrance(
          index: StepLayout.firstContentIndex,
          child: MemberCard(
            name: _isEmail ? formatter.describe('name', answers) ?? '' : value,
            email: _isEmail ? value : formatter.describe('email', answers),
          ),
        ),
        const SizedBox(height: 28),
        Entrance(
          index: StepLayout.firstContentIndex + 1,
          child: Shake(
            shakes: _shakes,
            child: AutofillGroup(
              child: MemberInput(
                controller: _text,
                focusNode: _focus,
                onChanged: _page.changed,
                onSubmitted: _submit,
                direction: status.direction,
                kind: step.kind,
                showError: status.showError,
                label: step.placeholder?.resolve(language),
                examples: _isEmail
                    ? [
                        if (step.placeholder case final hint?)
                          hint.resolve(language),
                      ]
                    : l10n.nameExamples.split(','),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          alignment: AlignmentDirectional.topStart,
          child: AnimatedSwitcher(
            duration: AppMotion.medium,
            child: switch ((status.showError, status.suggestion)) {
              (_, final suggestion?) => _SuggestionChip(
                key: ValueKey(suggestion),
                text: l10n.emailSuggestion(suggestion),
                action: l10n.emailUseSuggestion,
                onTap: () => _applySuggestion(suggestion),
              ),
              (true, null) => _ErrorLine(
                key: const ValueKey('error'),
                text: l10n.emailInvalid,
              ),
              _ => const SizedBox(width: double.infinity),
            },
          ),
        ),
      ],
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(top: 10, start: 4),
    child: Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 18,
          color: AppColors.error,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: AppColors.error),
          ),
        ),
      ],
    ),
  );
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.text,
    required this.action,
    required this.onTap,
    super.key,
  });

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.blush,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_fix_high_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: theme.bodyMedium!.copyWith(color: AppColors.ink),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  action,
                  style: theme.labelMedium!.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
