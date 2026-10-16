import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/l10n/language_controller.dart';
import 'package:traininpink_onboarding/core/ui/app_assets.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';
import 'package:traininpink_onboarding/core/ui/widgets/language_toggle.dart';
import 'package:traininpink_onboarding/core/ui/widgets/primary_button.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:video_player/video_player.dart';

/// The welcome clip, muted, looping and ready to play. Lives only while the
/// screen shows it. If it can't load, the screen keeps its still photo, so
/// a failure is final rather than retried.
final FutureProvider<VideoPlayerController> _welcomeVideoProvider =
    FutureProvider.autoDispose<VideoPlayerController>(
      (ref) async {
        final video = VideoPlayerController.asset(
          AppAssets.welcomeVideo,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        ref.onDispose(() => video.dispose().ignore());
        await video.initialize();
        await video.setLooping(true);
        await video.setVolume(0);
        return video;
      },
      retry: (_, _) => null,
    );

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _intro.value = 1;
    } else if (_intro.isDismissed) {
      unawaited(_intro.forward());
    }
    _syncPlayback();
  }

  /// Plays only while this screen is on top and motion is welcome.
  void _syncPlayback() {
    // Never start the clip just to pause it (e.g. under Reduce Motion).
    if (!ref.exists(_welcomeVideoProvider)) return;
    final video = ref.read(_welcomeVideoProvider).value;
    if (video == null) return;
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
    // The clip only loads when motion is welcome; Reduce Motion keeps the
    // still photo.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final video = reduceMotion
        ? const AsyncValue<VideoPlayerController>.loading()
        : ref.watch(_welcomeVideoProvider);
    if (!reduceMotion) {
      ref.listen(_welcomeVideoProvider, (_, next) {
        if (next.hasValue) _syncPlayback();
      });
    }

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
                if (reduceMotion || video.hasError)
                  const Image(
                    image: AppAssets.welcome,
                    fit: BoxFit.cover,
                    alignment: Alignment(-0.15, 0.4),
                  ),
                if (video.value case final video?)
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
