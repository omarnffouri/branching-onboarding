import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';
import 'package:traininpink_onboarding/core/ui/widgets/pressable.dart';

/// The EN | IT pill from the Traininpink welcome screen, as EN | ع.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({
    required this.languages,
    required this.selected,
    required this.onSelected,
    this.translucent = false,
    super.key,
  });

  /// Language code to its short label, in display order.
  final Map<String, String> languages;
  final String selected;
  final ValueChanged<String> onSelected;

  /// For sitting on top of a photo.
  final bool translucent;

  @override
  Widget build(BuildContext context) {
    final codes = languages.keys.toList();
    final selectedIndex = codes.indexOf(selected).clamp(0, codes.length - 1);
    final style = Theme.of(context).textTheme.labelMedium!;
    const segmentWidth = 44.0;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: translucent
            ? Colors.white.withValues(alpha: 0.78)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: SizedBox(
        width: segmentWidth * codes.length,
        height: 32,
        child: Stack(
          children: [
            AnimatedPositionedDirectional(
              duration: AppMotion.medium,
              curve: AppMotion.emphasized,
              start: segmentWidth * selectedIndex,
              top: 0,
              bottom: 0,
              width: segmentWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            Row(
              children: [
                for (final code in codes)
                  Semantics(
                    button: true,
                    selected: code == selected,
                    child: Pressable(
                      onTap: () => onSelected(code),
                      child: SizedBox(
                        width: segmentWidth,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: AppMotion.medium,
                            style: style.copyWith(
                              color: code == selected
                                  ? Colors.white
                                  : AppColors.ink,
                              // Each label in its own script's font.
                              fontFamily: code == 'ar'
                                  ? 'IBMPlexSansArabic'
                                  : 'Poppins',
                            ),
                            child: Text(languages[code]!),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
