import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/core/design/widgets/language_toggle.dart';
import 'package:traininpink_onboarding/core/design/widgets/primary_button.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/l10n/language_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:video_player/video_player.dart';

const welcomeImage = AssetImage('assets/images/welcome.jpg');
const _welcomeVideo = 'assets/video/welcome.mp4';

/// First impression: a slow, muted, looping Pilates clip, one promise, one
/// button.
///
/// The clip fades in over the canvas once its first frame is ready. With
/// reduced motion, or if the video can't play, a still photo stands in.
/// It only plays while the welcome screen is on top, and it mixes with
/// other audio, so opening the app never pauses her music.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({required this.onOpenInspector, super.key});

  final VoidCallback onOpenInspector;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  VideoPlayerController? _video;
  var _videoReady = false;
  var _videoFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _intro.value = 1;
    } else if (_intro.isDismissed) {
      unawaited(_intro.forward());
    }
    if (!reduceMotion && _video == null && !_videoFailed) _startVideo();
    _syncPlayback();
  }

  void _startVideo() {
    final video = VideoPlayerController.asset(
      _welcomeVideo,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _video = video;
    video
        .initialize()
        .then(
          (_) async {
            if (!mounted) return;
            await video.setLooping(true);
            await video.setVolume(0);
            _syncPlayback();
            if (mounted) setState(() => _videoReady = true);
          },
          onError: (Object _) {
            if (mounted) setState(() => _videoFailed = true);
          },
        )
        .ignore();
  }

  /// Plays only while this screen is on top and motion is welcome.
  void _syncPlayback() {
    final video = _video;
    if (video == null || !video.value.isInitialized) return;
    final onTop = ModalRoute.isCurrentOf(context) ?? true;
    if (onTop && !MediaQuery.disableAnimationsOf(context)) {
      video.play().ignore();
    } else {
      video.pause().ignore();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _video?.dispose().ignore();
    super.dispose();
  }

  /// Fades and lifts one line of the intro in, in order.
  Widget _reveal(int order, Widget child) {
    final start = 0.15 + order * 0.08;
    final progress = _intro.drive(
      CurveTween(
        curve: Interval(
          start,
          math.min(start + 0.45, 1),
          curve: AppMotion.emphasized,
        ),
      ),
    );
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) => Opacity(
        opacity: progress.value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - progress.value)),
          child: child,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final language = ref.watch(languageProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // A slow settle, like the camera finding its focus.
          AnimatedBuilder(
            animation: _intro,
            builder: (context, child) => Transform.scale(
              scale: 1.08 - 0.08 * Curves.easeOutCubic.transform(_intro.value),
              child: child,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_videoFailed || MediaQuery.disableAnimationsOf(context))
                  const Image(
                    image: welcomeImage,
                    fit: BoxFit.cover,
                    alignment: Alignment(-0.15, 0.4),
                  ),
                if (_video case final video? when _videoReady)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: AppMotion.slow,
                    builder: (context, opacity, child) =>
                        Opacity(opacity: opacity, child: child),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox.fromSize(
                        size: video.value.size,
                        child: VideoPlayer(video),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.36, 0.58, 0.78, 1],
                colors: [
                  AppColors.background,
                  Color(0xEBFFF7F7),
                  Color(0x00FFF7F7),
                  Color(0x00FFF7F7),
                  Color(0xF2FFF7F7),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _reveal(
                    0,
                    Row(
                      children: [
                        GestureDetector(
                          onLongPress: widget.onOpenInspector,
                          child: Text(
                            'traininpink',
                            style: text.titleLarge!.copyWith(
                              fontFamily: 'Poppins',
                              color: AppColors.primary,
                              fontSize: 22,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ),
                        const Spacer(),
                        LanguageToggle(
                          translucent: true,
                          selected: language,
                          languages: const {'en': 'EN', 'ar': 'ع'},
                          onSelected: ref
                              .read(languageProvider.notifier)
                              .select,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _reveal(
                    1,
                    Text(
                      l10n.welcomeEyebrow,
                      style: text.labelMedium!.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _reveal(2, Text(l10n.welcomeTitle, style: text.displaySmall)),
                  const SizedBox(height: 12),
                  _reveal(
                    3,
                    Text(
                      l10n.welcomeBody,
                      style: text.bodyLarge!.copyWith(color: AppColors.ink),
                    ),
                  ),
                  const Spacer(),
                  _reveal(
                    4,
                    PrimaryButton(
                      label: l10n.welcomeCta,
                      onPressed: ref
                          .read(onboardingControllerProvider.notifier)
                          .start,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _reveal(
                    5,
                    Text(
                      l10n.welcomeFootnote,
                      textAlign: TextAlign.center,
                      style: text.labelMedium!.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
