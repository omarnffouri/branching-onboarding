import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/design/app_assets.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/core/design/widgets/entrance.dart';
import 'package:traininpink_onboarding/core/design/widgets/flow_background.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/flow_points.dart';

/// An info step with a photo, laid out like a magazine page: the photo
/// covers the top of the screen with no frame and fades into the flowing
/// background; the title sits on that fade and the steps follow.
class ImmersiveInfo extends StatelessWidget {
  const ImmersiveInfo({
    required this.image,
    required this.focus,
    required this.icon,
    required this.title,
    required this.points,
    required this.button,
    this.subtitle,
    this.body,
    super.key,
  });

  final String image;
  final Alignment focus;
  final String? icon;
  final String title;
  final String? subtitle;
  final String? body;
  final List<FlowPoint> points;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final route = ModalRoute.of(context)?.animation;
    final animate = route != null && !MediaQuery.disableAnimationsOf(context);
    final photoHeight = MediaQuery.sizeOf(context).height * 0.55;

    Widget photo = Image(
      image: AppAssets.step(image),
      fit: BoxFit.cover,
      alignment: focus,
      gaplessPlayback: true,
    );
    if (animate) {
      final eased = route.drive(CurveTween(curve: AppMotion.emphasized));
      photo = AnimatedBuilder(
        animation: eased,
        builder: (context, child) =>
            Transform.scale(scale: 1.1 - 0.1 * eased.value, child: child),
        child: photo,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FlowBackground(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: photoHeight,
            // Fades out at the bottom into the flowing background, and a
            // little at the top so the header stays legible.
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.3, 0.5, 0.86],
                colors: [
                  Color(0x80FFFFFF),
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
              ).createShader(bounds),
              child: ClipRect(child: photo),
            ),
          ),
          SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      photoHeight * 0.8,
                      AppSpacing.page,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Entrance(
                          index: 0,
                          child: Text(title, style: text.headlineMedium),
                        ),
                        if (subtitle case final subtitle?) ...[
                          const SizedBox(height: 8),
                          Entrance(
                            index: 1,
                            child: Text(subtitle, style: text.bodyLarge),
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (points.isNotEmpty)
                          FlowPoints(points: points, firstIndex: 2)
                        else if (body case final body?)
                          Entrance(
                            index: 2,
                            child: Text(
                              body,
                              style: text.bodyLarge!.copyWith(
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.sm,
                    AppSpacing.page,
                    AppSpacing.md,
                  ),
                  child: button,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
