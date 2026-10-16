import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';

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

class _PressableState extends State<Pressable> {
  var _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
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
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: widget.child,
      ),
    );
  }
}
