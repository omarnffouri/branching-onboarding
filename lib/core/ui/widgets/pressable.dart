import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';

enum PressHaptic { none, selection, light, medium }

/// Gives anything a physical press: it sinks slightly under her finger and
/// answers with a haptic tap. Disabled when [onTap] is null.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.haptic = PressHaptic.selection,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final PressHaptic haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  // The press is an animation, not state: it scales the child without
  // rebuilding it.
  late final _press = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
  );
  late final Animation<double> _scale = _press.drive(
    Tween<double>(
      begin: 1,
      end: widget.pressedScale,
    ).chain(CurveTween(curve: AppMotion.standard)),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (pressed) {
      _press.forward().ignore();
    } else {
      _press.reverse().ignore();
    }
  }

  void _handleTap() {
    switch (widget.haptic) {
      case PressHaptic.none:
        break;
      case PressHaptic.selection:
        HapticFeedback.selectionClick().ignore();
      case PressHaptic.light:
        HapticFeedback.lightImpact().ignore();
      case PressHaptic.medium:
        HapticFeedback.mediumImpact().ignore();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTap: enabled ? _handleTap : null,
      onLongPress: widget.onLongPress,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
