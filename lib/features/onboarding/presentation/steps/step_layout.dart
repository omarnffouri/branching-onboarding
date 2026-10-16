import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';
import 'package:traininpink_onboarding/core/ui/widgets/entrance.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/flow_header.dart';

/// The shape every question shares: title, subtitle, content, and the call
/// to action pinned at the bottom.
///
/// The scaffold resizes for the keyboard, so the CTA rides above it and the
/// content scrolls; the field being typed in is never covered.
class StepLayout extends StatelessWidget {
  const StepLayout({
    required this.title,
    required this.children,
    this.subtitle,
    this.footer,
    this.leading,
    this.hero,
    this.backdrop,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// Shown above the title, e.g. the icon on an info step.
  final Widget? leading;

  /// A photo above everything else, see `StepHero`.
  final Widget? hero;
  final List<Widget> children;
  final Widget? footer;

  /// Painted behind everything, e.g. the flow background on info steps.
  final Widget? backdrop;

  /// Entrance index for the first child, after the title and subtitle.
  static const firstContentIndex = 2;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          if (backdrop case final backdrop?) Positioned.fill(child: backdrop),
          SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.page,
                      FlowHeader.extentOf(context) + 16,
                      AppSpacing.page,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hero case final hero?) ...[
                          Entrance(index: 0, lift: 10, child: hero),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        if (leading case final leading?) ...[
                          Entrance(index: 0, child: leading),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        Entrance(
                          index: 0,
                          child: Text(title, style: text.headlineMedium),
                        ),
                        if (subtitle case final subtitle?) ...[
                          const SizedBox(height: 10),
                          Entrance(
                            index: 1,
                            child: Text(subtitle, style: text.bodyLarge),
                          ),
                        ],
                        const SizedBox(height: 28),
                        ...children,
                      ],
                    ),
                  ),
                ),
                if (footer case final footer?)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.sm,
                      AppSpacing.page,
                      AppSpacing.md,
                    ),
                    child: footer,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
