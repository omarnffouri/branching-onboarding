import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';

/// "Welcome back, Layla": shown once when she reopens the app mid-flow, so
/// landing on question five feels intentional rather than confusing.
class ResumeBanner extends StatefulWidget {
  const ResumeBanner({
    required this.name,
    required this.onDismissed,
    super.key,
  });

  final String? name;
  final VoidCallback onDismissed;

  @override
  State<ResumeBanner> createState() => _ResumeBannerState();
}

class _ResumeBannerState extends State<ResumeBanner>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
    reverseDuration: AppMotion.medium,
  );
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    // Let the first frame settle so the banner arrives, rather than appears.
    _autoDismiss = Timer(const Duration(milliseconds: 450), () {
      HapticFeedback.lightImpact().ignore();
      unawaited(_controller.forward());
      _autoDismiss = Timer(const Duration(milliseconds: 3600), _dismiss);
    });
  }

  Future<void> _dismiss() async {
    _autoDismiss?.cancel();
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final name = widget.name;
    final curved = _controller.drive(CurveTween(curve: AppMotion.emphasized));

    return SlideTransition(
      position: curved.drive(
        Tween(begin: const Offset(0, -0.4), end: Offset.zero),
      ),
      child: FadeTransition(
        opacity: curved,
        child: GestureDetector(
          onTap: _dismiss,
          onVerticalDragEnd: (_) => _dismiss(),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              boxShadow: AppShadows.raised,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.blush,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bookmark_added_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name == null || name.isEmpty
                            ? l10n.resumeTitleNoName
                            : l10n.resumeTitle(name),
                        style: text.titleMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(l10n.resumeBody, style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
