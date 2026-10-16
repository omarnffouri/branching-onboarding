import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/core/design/widgets/flow_background.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/l10n/language_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/plan_summary.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';

/// The beat between her last answer and her plan.
///
/// A liquid fill rises as the plan "assembles" (flow, again) while her own
/// answers tick off one by one, so the wait reads as work being done for
/// her and the plan that follows feels earned rather than generic. Short
/// and still with reduced motion.
class BuildingPlanScreen extends ConsumerStatefulWidget {
  const BuildingPlanScreen({super.key});

  @override
  ConsumerState<BuildingPlanScreen> createState() => _BuildingPlanScreenState();
}

class _BuildingPlanScreenState extends ConsumerState<BuildingPlanScreen>
    with TickerProviderStateMixin {
  late final _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..addStatusListener(_onStatus);
  late final _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  var _ready = false;
  Timer? _finish;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_progress.isDismissed) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _progress.duration = const Duration(milliseconds: 600);
      } else {
        unawaited(_wave.repeat());
      }
      unawaited(_progress.forward());
    }
  }

  void _onStatus(AnimationStatus status) {
    if (!status.isCompleted) return;
    HapticFeedback.mediumImpact().ignore();
    setState(() => _ready = true);
    _finish = Timer(
      const Duration(milliseconds: 750),
      ref.read(onboardingControllerProvider.notifier).finishBuilding,
    );
  }

  @override
  void dispose() {
    _finish?.cancel();
    _progress.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final summary = PlanSummary.build(
      ref.watch(flowConfigProvider),
      ref.watch(onboardingControllerProvider).resolution,
      ref.watch(languageProvider),
    );
    final items = [
      for (final stat in summary.stats) stat.text,
      for (final highlight in summary.highlights) highlight.title,
    ].take(5).toList();
    final eased = _progress.drive(CurveTween(curve: Curves.easeInOutCubic));

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: FlowBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: AnimatedBuilder(
                animation: eased,
                builder: (context, _) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: _LiquidOrb(
                        progress: eased.value,
                        wave: _wave,
                        label: '${(eased.value * 100).round()}%',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AnimatedSwitcher(
                      duration: AppMotion.medium,
                      child: Text(
                        _ready ? l10n.buildingReady : l10n.buildingTitle,
                        key: ValueKey(_ready),
                        style: text.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 28),
                    for (final (i, item) in items.indexed)
                      _ChecklistRow(
                        key: ValueKey(item),
                        text: item,
                        // Each line lands at its share of the progress.
                        reveal: ((eased.value * (items.length + 1)) - i).clamp(
                          0.0,
                          1.0,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.text, required this.reveal, super.key});

  final String text;

  /// 0 hidden, 1 shown and checked.
  final double reveal;

  @override
  Widget build(BuildContext context) {
    final shown = AppMotion.emphasized.transform(reveal);
    return Opacity(
      opacity: shown,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - shown)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: AppMotion.medium,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: reveal >= 1 ? AppColors.success : AppColors.track,
                ),
                child: AnimatedScale(
                  duration: AppMotion.medium,
                  curve: AppMotion.emphasized,
                  scale: reveal >= 1 ? 1 : 0,
                  child: const Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  text,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A circle filling with liquid: two offset waves (the back one paler)
/// rise with [progress]. The label is drawn twice, rose above the water and
/// white beneath it, so it stays readable as the level passes through it.
class _LiquidOrb extends StatelessWidget {
  const _LiquidOrb({
    required this.progress,
    required this.wave,
    required this.label,
  });

  final double progress;
  final Animation<double> wave;
  final String label;

  static const _size = 176.0;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.displaySmall!.copyWith(
      fontFamily: 'Poppins',
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget labelIn(Color color) => Center(
      child: Text(label, style: style.copyWith(color: color)),
    );

    return SizedBox.square(
      dimension: _size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: AppShadows.raised,
        ),
        child: ClipOval(
          child: AnimatedBuilder(
            animation: wave,
            builder: (context, _) => Stack(
              fit: StackFit.expand,
              children: [
                labelIn(AppColors.primary),
                ClipPath(
                  clipper: _WaveClipper(progress, wave.value + 0.35),
                  child: ColoredBox(
                    color: AppColors.primarySoft.withValues(alpha: 0.55),
                  ),
                ),
                ClipPath(
                  clipper: _WaveClipper(progress, wave.value),
                  child: ColoredBox(
                    color: AppColors.primary,
                    child: labelIn(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  const _WaveClipper(this.level, this.phase);

  /// 0 empty, 1 full.
  final double level;

  /// 0..1, one full wave cycle.
  final double phase;

  @override
  Path getClip(Size size) {
    // Calm at empty and full, liveliest half way.
    final amplitude = 7 * math.sin(level * math.pi);
    final surface = size.height * (1 - level);
    final path = Path()..moveTo(0, size.height);
    for (var x = 0.0; x <= size.width; x += 4) {
      final angle = (x / size.width + phase) * 2 * math.pi * 1.2;
      path.lineTo(x, surface + math.sin(angle) * amplitude);
    }
    return path
      ..lineTo(size.width, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) =>
      oldClipper.level != level || oldClipper.phase != phase;
}
