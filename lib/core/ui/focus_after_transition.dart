import 'package:flutter/widgets.dart';

/// Raises the keyboard once the page has finished sliding in.
///
/// Focusing mid-transition makes the page and the keyboard fight for the
/// frame, so the field waits for its route's entrance animation. Purely a
/// widget concern: it needs the route, the focus node and the lifecycle.
mixin FocusAfterTransition<T extends StatefulWidget> on State<T> {
  /// The field to focus.
  FocusNode get transitionFocusNode;

  /// Whether to focus when the page arrives, e.g. only while it is empty.
  bool get shouldFocusAfterTransition => true;

  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeAnimation != null) return;
    final animation = ModalRoute.of(context)?.animation;
    _routeAnimation = animation;
    if (animation == null || animation.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focus());
    } else {
      animation.addStatusListener(_onRouteStatus);
    }
  }

  void _onRouteStatus(AnimationStatus status) {
    if (!status.isCompleted) return;
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _focus();
  }

  void _focus() {
    if (mounted && shouldFocusAfterTransition) {
      transitionFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    super.dispose();
  }
}
