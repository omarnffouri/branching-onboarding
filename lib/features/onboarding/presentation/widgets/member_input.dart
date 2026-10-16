import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/typing_examples.dart';

/// Her name or email, no box: the text is the interface. A rose line
/// grows under it as she types, and while it's empty, examples type
/// and erase themselves to show what goes here.
class MemberInput extends StatelessWidget {
  const MemberInput({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.direction,
    required this.kind,
    required this.showError,
    required this.label,
    required this.examples,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final TextDirection? direction;
  final TextInputKind kind;
  final bool showError;
  final String? label;
  final List<String> examples;

  @override
  Widget build(BuildContext context) {
    final isEmail = kind == TextInputKind.email;
    final style = Theme.of(
      context,
    ).textTheme.headlineMedium!.copyWith(fontSize: isEmail ? 24 : 34);
    final value = controller.text;

    return Directionality(
      textDirection: direction ?? Directionality.of(context),
      child: LayoutBuilder(
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
                  if (value.isEmpty && examples.isNotEmpty)
                    Positioned.fill(
                      child: ExcludeSemantics(
                        child: IgnorePointer(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TypingExamples(
                              examples: examples,
                              style: style.copyWith(
                                color: AppColors.primarySoft,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Semantics(
                    label: label,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: onChanged,
                      onSubmitted: (_) => onSubmitted(),
                      textInputAction: TextInputAction.done,
                      keyboardType: isEmail
                          ? TextInputType.emailAddress
                          : TextInputType.name,
                      textCapitalization: isEmail
                          ? TextCapitalization.none
                          : TextCapitalization.words,
                      autocorrect: false,
                      enableSuggestions: !isEmail,
                      autofillHints: [
                        if (isEmail)
                          AutofillHints.email
                        else
                          AutofillHints.givenName,
                      ],
                      maxLength: kind.maxLength,
                      textDirection: direction,
                      style: style,
                      cursorColor: AppColors.primary,
                      cursorWidth: 2.5,
                      cursorHeight: isEmail ? 28 : 36,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                      ),
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
                      color: showError ? AppColors.error : AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
