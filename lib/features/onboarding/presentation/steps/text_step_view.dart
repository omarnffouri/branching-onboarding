import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show Bidi;
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/core/design/widgets/entrance.dart';
import 'package:traininpink_onboarding/core/design/widgets/pressable.dart';
import 'package:traininpink_onboarding/core/design/widgets/primary_button.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/l10n/language_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/email_address.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/member_card.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/step_layout.dart';

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

class _TextStepViewState extends ConsumerState<TextStepView> {
  late final _text = TextEditingController(text: _savedText());
  final _focus = FocusNode();
  var _showError = false;
  var _shakes = 0;
  Animation<double>? _routeAnimation;

  bool get _isEmail => widget.step.kind == TextInputKind.email;

  OnboardingController get _controller =>
      ref.read(onboardingControllerProvider.notifier);

  String _savedText() =>
      switch (ref.read(onboardingControllerProvider).answers[widget.step.id]) {
        TextAnswer(:final value) => value,
        _ => '',
      };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Raise the keyboard once the page has finished sliding in: focusing
    // mid-transition makes the page and the keyboard fight for the frame.
    if (_routeAnimation == null) {
      final animation = ModalRoute.of(context)?.animation;
      _routeAnimation = animation;
      if (animation == null || animation.isCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _focusIfNeeded());
      } else {
        animation.addStatusListener(_onRouteStatus);
      }
    }
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status.isCompleted) {
      _routeAnimation?.removeStatusListener(_onRouteStatus);
      _focusIfNeeded();
    }
  }

  void _focusIfNeeded() {
    if (mounted && _text.text.isEmpty) _focus.requestFocus();
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // What is in the field is the truth: an invalid value clears the saved
    // answer instead of leaving a stale valid one behind.
    _controller.answer(widget.step.id, TextAnswer(value.trim()));
    setState(() {
      if (_showError && widget.step.kind.accepts(value)) _showError = false;
    });
  }

  void _submit() {
    final value = _text.text.trim();
    if (widget.step.kind.accepts(value)) {
      _controller
        ..answer(widget.step.id, TextAnswer(value))
        ..continueFrom(widget.step.id);
      return;
    }
    HapticFeedback.mediumImpact().ignore();
    setState(() {
      _showError = true;
      _shakes++;
    });
  }

  void _applySuggestion(String suggestion) {
    _text
      ..text = suggestion
      ..selection = TextSelection.collapsed(offset: suggestion.length);
    _onChanged(suggestion);
    HapticFeedback.selectionClick().ignore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final language = ref.watch(languageProvider);
    final formatter = ref.watch(answerFormatterProvider);
    final answers = ref.watch(
      onboardingControllerProvider.select((state) => state.answers),
    );
    final step = widget.step;
    final value = _text.text;
    final suggestion = _isEmail ? EmailAddress.suggestCorrection(value) : null;

    // Emails are always left to right; a name follows the script she types.
    final direction = _isEmail
        ? TextDirection.ltr
        : value.isNotEmpty && Bidi.detectRtlDirectionality(value)
        ? TextDirection.rtl
        : null;

    final borderColor = _showError ? AppColors.error : AppColors.border;
    OutlineInputBorder border(Color color, {double width = 1.5}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: BorderSide(color: color, width: width),
        );

    if (!_isEmail) {
      return StepLayout(
        title: formatter.fill(step.title, answers),
        subtitle: step.subtitle?.resolve(language),
        footer: PrimaryButton(
          label: l10n.continueButton,
          onPressed: value.trim().isEmpty ? null : _submit,
        ),
        children: [
          Entrance(
            index: StepLayout.firstContentIndex,
            child: MemberCard(name: value),
          ),
          const SizedBox(height: 28),
          Entrance(
            index: StepLayout.firstContentIndex + 1,
            child: _NameInput(
              controller: _text,
              focusNode: _focus,
              onChanged: _onChanged,
              onSubmitted: _submit,
              direction: direction,
              maxLength: step.kind.maxLength,
              examples: l10n.nameExamples.split(','),
            ),
          ),
        ],
      );
    }

    return StepLayout(
      title: formatter.fill(step.title, answers),
      subtitle: step.subtitle?.resolve(language),
      footer: PrimaryButton(
        label: l10n.continueButton,
        onPressed: value.trim().isEmpty ? null : _submit,
      ),
      children: [
        Entrance(
          index: StepLayout.firstContentIndex,
          child: _Shake(
            shakes: _shakes,
            child: AutofillGroup(
              child: TextField(
                controller: _text,
                focusNode: _focus,
                onChanged: _onChanged,
                onSubmitted: (_) => _submit(),
                textInputAction: TextInputAction.done,
                keyboardType: _isEmail
                    ? TextInputType.emailAddress
                    : TextInputType.name,
                textCapitalization: _isEmail
                    ? TextCapitalization.none
                    : TextCapitalization.words,
                autocorrect: false,
                enableSuggestions: !_isEmail,
                autofillHints: [
                  if (_isEmail)
                    AutofillHints.email
                  else
                    AutofillHints.givenName,
                ],
                maxLength: step.kind.maxLength,
                textDirection: direction,
                style: theme.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: step.placeholder?.resolve(language),
                  hintStyle: theme.textTheme.titleLarge!.copyWith(
                    color: AppColors.primarySoft,
                    fontWeight: FontWeight.w400,
                  ),
                  hintTextDirection: _isEmail ? TextDirection.ltr : null,
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  enabledBorder: border(borderColor),
                  focusedBorder: border(
                    _showError ? AppColors.error : AppColors.primary,
                    width: 1.8,
                  ),
                ),
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
            child: switch ((_showError, suggestion)) {
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

/// A short horizontal shake each time [shakes] increases.
class _Shake extends StatelessWidget {
  const _Shake({required this.shakes, required this.child});

  final int shakes;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (shakes == 0 || MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(shakes),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (context, t, child) => Transform.translate(
        offset: Offset(math.sin(t * math.pi * 4) * 8 * (1 - t), 0),
        child: child,
      ),
      child: child,
    );
  }
}

/// Her name in large type, no box: the text is the interface. A rose line
/// grows under it as she types, and while it's empty, example names type
/// and erase themselves to show what goes here.
class _NameInput extends StatelessWidget {
  const _NameInput({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.direction,
    required this.maxLength,
    required this.examples,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final TextDirection? direction;
  final int maxLength;
  final List<String> examples;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.headlineMedium!.copyWith(fontSize: 34);
    final value = controller.text;

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: value, style: style),
          textDirection: direction ?? Directionality.of(context),
          maxLines: 1,
        )..layout();
        final lineWidth = value.isEmpty
            ? 48.0
            : (painter.width + 12).clamp(48.0, constraints.maxWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                if (value.isEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _TypingExamples(
                          names: examples,
                          style: style.copyWith(color: AppColors.primarySoft),
                        ),
                      ),
                    ),
                  ),
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  onSubmitted: (_) => onSubmitted(),
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.givenName],
                  maxLength: maxLength,
                  textDirection: direction,
                  style: style,
                  cursorColor: AppColors.primary,
                  cursorWidth: 2.5,
                  cursorHeight: 36,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    isCollapsed: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                Container(height: 1.5, color: AppColors.border),
                AnimatedContainer(
                  duration: AppMotion.medium,
                  curve: AppMotion.emphasized,
                  width: lineWidth,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Types an example name, pauses, erases it, and moves to the next.
/// Still (just the first name) under reduced motion.
class _TypingExamples extends StatefulWidget {
  const _TypingExamples({required this.names, required this.style});

  final List<String> names;
  final TextStyle style;

  @override
  State<_TypingExamples> createState() => _TypingExamplesState();
}

class _TypingExamplesState extends State<_TypingExamples> {
  Timer? _timer;
  var _name = 0;
  var _shown = 0;
  var _erasing = false;
  var _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    if (!_still && _timer == null) _schedule(const Duration(milliseconds: 500));
  }

  void _schedule(Duration delay) => _timer = Timer(delay, _tick);

  void _tick() {
    if (!mounted) return;
    final length = widget.names[_name].characters.length;
    setState(() {
      if (!_erasing && _shown < length) {
        _shown++;
      } else if (!_erasing) {
        _erasing = true;
      } else if (_shown > 0) {
        _shown--;
      } else {
        _erasing = false;
        _name = (_name + 1) % widget.names.length;
      }
    });
    _schedule(switch ((_erasing, _shown)) {
      (false, final shown) when shown == length => const Duration(
        milliseconds: 1400,
      ),
      (false, _) => const Duration(milliseconds: 110),
      (true, 0) => const Duration(milliseconds: 350),
      (true, _) => const Duration(milliseconds: 45),
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.names[_name].characters;
    return Text(
      _still ? name.toString() : name.take(_shown).toString(),
      style: widget.style,
      maxLines: 1,
    );
  }
}
