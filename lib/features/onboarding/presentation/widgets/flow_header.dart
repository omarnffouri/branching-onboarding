import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';
import 'package:traininpink_onboarding/core/ui/widgets/flow_progress_bar.dart';
import 'package:traininpink_onboarding/core/ui/widgets/pressable.dart';

/// Back, progress and language, pinned above the questions.
///
/// It lives above the page navigator rather than inside each page, so it
/// stays still while questions slide underneath and the progress bar can
/// glide between steps instead of being carried off-screen.
class FlowHeader extends StatelessWidget {
  const FlowHeader({
    required this.progress,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    required this.otherLanguageLabel,
    required this.onToggleLanguage,
    required this.onOpenInspector,
    this.solid = true,
    super.key,
  });

  static const height = 60.0;

  /// Space a question page leaves at its top for the header.
  static double extentOf(BuildContext context) =>
      MediaQuery.paddingOf(context).top + height;

  final double progress;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;
  final String otherLanguageLabel;
  final VoidCallback onToggleLanguage;
  final VoidCallback onOpenInspector;

  /// Off over screens with their own backdrop, so it doesn't band across it.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: solid ? 1 : 0,
            duration: AppMotion.medium,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.82, 1],
                  colors: [AppColors.background, Color(0x00FFF7F7)],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(
            top: MediaQuery.paddingOf(context).top,
            start: 10,
            end: AppSpacing.page - 4,
          ),
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: l10n.backButton,
                  excludeSemantics: true,
                  child: Pressable(
                    onTap: onBack,
                    haptic: PressHaptic.none,
                    pressedScale: 0.9,
                    child: SizedBox.square(
                      dimension: 44,
                      child: Center(
                        // Over a photo it gets the same white disc as the
                        // language button, so it never gets lost.
                        child: AnimatedContainer(
                          duration: AppMotion.medium,
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: solid
                                ? Colors.transparent
                                : AppColors.surface.withValues(alpha: 0.9),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Semantics(
                    label: l10n.progressSemantics(currentStep, totalSteps),
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // Hidden door to the flow inspector, see README.
                      onLongPress: onOpenInspector,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: FlowProgressBar(value: progress),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Pressable(
                  onTap: onToggleLanguage,
                  pressedScale: 0.9,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      otherLanguageLabel,
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: AppColors.primary,
                        fontFamily: otherLanguageLabel == 'ع'
                            ? 'IBMPlexSansArabic'
                            : 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
