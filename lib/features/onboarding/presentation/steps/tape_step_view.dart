import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/l10n/language_controller.dart';
import 'package:traininpink_onboarding/core/ui/app_assets.dart';
import 'package:traininpink_onboarding/core/ui/tokens.dart';
import 'package:traininpink_onboarding/core/ui/widgets/entrance.dart';
import 'package:traininpink_onboarding/core/ui/widgets/pressable.dart';
import 'package:traininpink_onboarding/core/ui/widgets/primary_button.dart';
import 'package:traininpink_onboarding/features/onboarding/application/controllers/tape_step_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/flow_header.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/measuring_tape.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/waist_torso.dart';

/// A number answered by measuring: a tape wraps around her waist in the
/// photo, and she drags it to the right mark.
///
/// The tape is drawn as if wrapped around a cylinder, so marks shrink and
/// fade as they turn away at the sides. It glides with her finger, snaps
/// to whole numbers when she lets go, and ticks with a haptic on each one.
class TapeStepView extends ConsumerStatefulWidget {
  const TapeStepView({required this.step, super.key});

  final NumberStep step;

  @override
  ConsumerState<TapeStepView> createState() => _TapeStepViewState();
}

/// The logic lives in TapeStepController; this keeps only the screen's
/// motion: where the tape sits while she drags, the snap to a whole number,
/// and a haptic tick on each one.
class _TapeStepViewState extends ConsumerState<TapeStepView>
    with SingleTickerProviderStateMixin {
  /// Pixels of tape per unit (per cm), shared with the painter.
  static const _spacing = 18.0;

  late final AnimationController _snap;

  NumberStep get _step => widget.step;

  TapeStepController get _page =>
      ref.read(tapeStepControllerProvider(widget.step.id).notifier);

  @override
  void initState() {
    super.initState();
    // Created up front, not lazily: a page she never drags must not create
    // its animation for the first time while being disposed.
    _snap = AnimationController.unbounded(vsync: this)
      ..addListener(() => _page.moveTo(_snap.value));
  }

  @override
  void dispose() {
    _snap.dispose();
    super.dispose();
  }

  void _onDrag(DragUpdateDetails details) {
    _snap.stop();
    final direction = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    // Dragging left reveals higher numbers, like pulling a real tape.
    _page.dragBy(-direction * details.delta.dx / _spacing);
  }

  void _onDragEnd(DragEndDetails details) {
    final instant = MediaQuery.disableAnimationsOf(context);
    final from = ref.read(tapeStepControllerProvider(widget.step.id)).position;
    final target = _page.settle(instant: instant);
    if (instant) return;
    _snap
      ..value = from
      ..animateTo(
        target,
        duration: AppMotion.medium,
        curve: AppMotion.emphasized,
      ).ignore();
  }

  void _skip() {
    _snap.stop();
    _page.skip();
  }

  @override
  Widget build(BuildContext context) {
    final step = _step;
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final language = ref.watch(languageProvider);
    final formatter = ref.watch(answerFormatterProvider);
    final answers = ref.watch(
      onboardingControllerProvider.select((state) => state.answers),
    );
    final page = ref.watch(tapeStepControllerProvider(step.id));
    final unit = step.unit.resolve(language);
    final size = MediaQuery.sizeOf(context);

    final waistY = size.height * step.measureAt;

    final answerTop =
        (size.height - MediaQuery.paddingOf(context).bottom - 200) /
        size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Semantics(
        slider: true,
        label: formatter.fill(step.title, answers),
        value: '${page.shown} $unit',
        increasedValue: '${page.shown + 1} $unit',
        decreasedValue: '${page.shown - 1} $unit',
        onIncrease: () => _page.nudge(1),
        onDecrease: () => _page.nudge(-1),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: _onDrag,
          onHorizontalDragEnd: _onDragEnd,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // A photo if the config names one, otherwise our own
              // sculpted torso, drawn in the palette.
              if (step.image case final image?)
                Image(
                  image: AppAssets.step(image),
                  fit: BoxFit.cover,
                  alignment: Alignment(step.imageFocus.x, step.imageFocus.y),
                )
              else
                WaistTorso(waistY: waistY),
              // Light veils keep text readable on the photo. The lower one
              // starts just under the measured line and fades the body out
              // completely, so only the waist stays in focus.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [
                      0,
                      0.3,
                      0.4,
                      step.measureAt + 0.07,
                      step.measureAt + 0.16,
                      answerTop,
                      1,
                    ],
                    colors: const [
                      Color(0xF2FFF7F7),
                      Color(0xB3FFF7F7),
                      Color(0x00FFF7F7),
                      Color(0x00FFF7F7),
                      Color(0xD4FFF7F7),
                      AppColors.background,
                      AppColors.background,
                    ],
                  ),
                ),
              ),
              Entrance(
                index: 2,
                child: MeasuringTape(
                  value: page.position,
                  min: step.min,
                  max: step.max,
                  spacing: _spacing,
                  centerY: waistY,
                  // Wraps the torso at the waist when we draw it.
                  radius: switch ((step.image, step.measureWidth)) {
                    (null, _) => size.width * WaistTorso.waistHalfWidth + 6,
                    (_, final width?) => size.width * width / 2,
                    _ => size.width * 0.52,
                  },
                ),
              ),
              // The answer sits at the bottom, where the body fades out.
              Positioned(
                bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
                left: AppSpacing.page,
                right: AppSpacing.page,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Entrance(
                      index: 3,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${page.shown}',
                                style: text.displaySmall!.copyWith(
                                  fontFamily: 'Poppins',
                                  fontSize: 56,
                                  color: AppColors.primary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(unit, style: text.titleLarge),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.swipe_rounded,
                                size: 18,
                                color: AppColors.inkMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(l10n.tapeHint, style: text.bodyMedium),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (step.optional)
                      Semantics(
                        button: true,
                        label: l10n.skipQuestion,
                        onTap: _skip,
                        excludeSemantics: true,
                        child: Pressable(
                          onTap: _skip,
                          haptic: PressHaptic.none,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44),
                            child: Center(
                              child: Text(
                                l10n.skipQuestion,
                                style: text.labelMedium!.copyWith(
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: l10n.continueButton,
                      onPressed: _page.submit,
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    FlowHeader.extentOf(context) + 16,
                    AppSpacing.page,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Entrance(
                        index: 0,
                        child: Text(
                          formatter.fill(step.title, answers),
                          style: text.headlineMedium,
                        ),
                      ),
                      if (step.subtitle case final subtitle?) ...[
                        const SizedBox(height: 10),
                        Entrance(
                          index: 1,
                          child: Text(
                            subtitle.resolve(language),
                            style: text.bodyLarge!.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
