import 'package:flutter/material.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';

/// The photo above a question, named by the step's `image` in the config.
///
/// It settles into place with its page: a slow zoom out driven by the
/// route animation, so it moves with the slide rather than on its own
/// clock. Images are decoded at display size and pre-cached at launch,
/// so a step never pops its photo in late.
class StepHero extends StatelessWidget {
  const StepHero({
    required this.image,
    this.badge,
    this.focus = Alignment.center,
    super.key,
  });

  final Alignment focus;

  final String image;

  /// Overlaps the photo's bottom edge, e.g. an info step's icon.
  final Widget? badge;

  static const _decodeWidth = 1080;

  static ImageProvider providerFor(String image) => ResizeImage(
    AssetImage('assets/images/steps/$image'),
    width: _decodeWidth,
  );

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.sizeOf(context).height * 0.22).clamp(
      150.0,
      210.0,
    );
    final route = ModalRoute.of(context)?.animation;
    final animate = route != null && !MediaQuery.disableAnimationsOf(context);

    Widget photo = Image(
      image: providerFor(image),
      fit: BoxFit.cover,
      alignment: focus,
      height: height,
      width: double.infinity,
      gaplessPlayback: true,
      // If it was not pre-cached in time, fade it in rather than pop.
      frameBuilder: (context, child, frame, synchronous) => synchronous
          ? child
          : AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: AppMotion.medium,
              child: child,
            ),
    );
    if (animate) {
      photo = AnimatedBuilder(
        animation: route,
        builder: (context, child) => Transform.scale(
          scale: 1.12 - 0.12 * AppMotion.emphasized.transform(route.value),
          child: child,
        ),
        child: photo,
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: badge == null ? 0 : 28),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(height: height, child: photo),
          ),
          if (badge case final badge?)
            PositionedDirectional(start: 18, bottom: -28, child: badge),
        ],
      ),
    );
  }
}
