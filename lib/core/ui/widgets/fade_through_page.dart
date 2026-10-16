import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';

/// For moments rather than steps (building the plan, the plan, the welcome
/// back after subscribing): a soft fade and settle instead of a slide.
class FadeThroughPage<T> extends Page<T> {
  const FadeThroughPage({
    required this.child,
    super.key,
    super.name,
    super.canPop,
    super.onPopInvoked,
  });

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => PageRouteBuilder<T>(
    settings: this,
    transitionDuration: AppMotion.slow,
    reverseTransitionDuration: AppMotion.medium,
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = animation.drive(CurveTween(curve: AppMotion.emphasized));
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: curved.drive(Tween(begin: 0.97, end: 1)),
          child: child,
        ),
      );
    },
  );
}
