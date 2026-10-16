import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';

/// Fades a cream veil in behind the status bar once [child] scrolls past
/// [showAfter], so text never collides with the clock and battery, while a
/// full-bleed header photo still owns the top edge at rest.
class StatusBarScrim extends StatefulWidget {
  const StatusBarScrim({
    required this.showAfter,
    required this.child,
    super.key,
  });

  /// Scroll offset at which the veil is fully visible.
  final double showAfter;
  final Widget child;

  @override
  State<StatusBarScrim> createState() => _StatusBarScrimState();
}

class _StatusBarScrimState extends State<StatusBarScrim> {
  static const _fadeDistance = 48.0;

  /// Only the veil repaints as she scrolls; the page itself never rebuilds.
  final ValueNotifier<double> _opacity = ValueNotifier(0);

  @override
  void dispose() {
    _opacity.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    final opacity =
        ((notification.metrics.pixels - widget.showAfter + _fadeDistance) /
                _fadeDistance)
            .clamp(0.0, 1.0);
    _opacity.value = opacity;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: top + 20,
            child: IgnorePointer(child: _Veil(opacity: _opacity)),
          ),
        ],
      ),
    );
  }
}

/// The cream gradient, redrawn whenever its opacity changes.
class _Veil extends AnimatedWidget {
  const _Veil({required ValueNotifier<double> opacity})
    : super(listenable: opacity);

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: (listenable as ValueNotifier<double>).value,
    child: const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.7, 1],
          colors: [AppColors.background, Color(0x00FFF7F7)],
        ),
      ),
    ),
  );
}
