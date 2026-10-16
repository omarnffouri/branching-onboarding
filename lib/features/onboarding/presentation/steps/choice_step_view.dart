import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/core/design/widgets/choice_card.dart';
import 'package:traininpink_onboarding/core/design/widgets/entrance.dart';
import 'package:traininpink_onboarding/core/design/widgets/primary_button.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/l10n/language_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/controllers/choice_step_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_state.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/step_layout.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/body_map.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/widgets/step_hero.dart';

/// Single choice moves on by itself a beat after she taps, like the
/// Traininpink app. Multi choice waits for Continue.
///
/// The logic lives in ChoiceStepController; this keeps only what belongs
/// to the screen: the short delay before moving on, and whether to show
/// Continue for an answer she already gave.
class ChoiceStepView extends ConsumerStatefulWidget {
  const ChoiceStepView({required this.step, super.key});

  final ChoiceStep step;

  @override
  ConsumerState<ChoiceStepView> createState() => _ChoiceStepViewState();
}

class _ChoiceStepViewState extends ConsumerState<ChoiceStepView> {
  Timer? _advance;
  late bool _showContinue = _isAnswered(
    ref.read(onboardingControllerProvider),
  );
  ProviderSubscription<OnboardingState>? _subscription;

  ChoiceStep get _step => widget.step;

  ChoiceStepController get _page =>
      ref.read(choiceStepControllerProvider(_step.id).notifier);

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual(onboardingControllerProvider, _onFlow);
  }

  @override
  void dispose() {
    _advance?.cancel();
    _subscription?.close();
    super.dispose();
  }

  bool _isAnswered(OnboardingState state) =>
      state.resolution.isAnswered(_step.id);

  bool _isCurrent(OnboardingState? state) =>
      state?.stage == OnboardingStage.questions &&
      state?.currentStepId == _step.id;

  /// This page stays alive behind later pages: cancel the pending advance
  /// when it's left, and offer Continue when she comes back to an answer.
  void _onFlow(OnboardingState? previous, OnboardingState next) {
    final current = _isCurrent(next);
    if (!current) _advance?.cancel();
    if (current && !_isCurrent(previous) && _isAnswered(next)) {
      setState(() => _showContinue = true);
    }
  }

  void _select(ChoiceOption option) {
    if (!_page.select(option)) return;
    if (_step is SingleChoiceStep) {
      _advance?.cancel();
      _advance = Timer(
        MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppMotion.selectionBeat,
        _continue,
      );
    }
  }

  void _continue() {
    _advance?.cancel();
    _page.continueStep();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageProvider);
    final formatter = ref.watch(answerFormatterProvider);
    final answers = ref.watch(
      onboardingControllerProvider.select((state) => state.answers),
    );
    final page = ref.watch(choiceStepControllerProvider(_step.id));

    return StepLayout(
      hero: switch (_step.image) {
        final image? when !page.usesBodyMap => StepHero(
          image: image,
          focus: Alignment(_step.imageFocus.x, _step.imageFocus.y),
        ),
        _ => null,
      },
      title: formatter.fill(_step.title, answers),
      subtitle: _step.subtitle?.resolve(language),
      footer: page.isMulti || _showContinue
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (page.isMulti)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AnimatedSwitcher(
                      duration: AppMotion.fast,
                      child: Text(
                        l10n.multiSelectedCount(page.selectedIds.length),
                        key: ValueKey(page.selectedIds.length),
                        style: Theme.of(context).textTheme.labelMedium!
                            .copyWith(color: AppColors.inkMuted),
                      ),
                    ),
                  ),
                PrimaryButton(
                  label: l10n.continueButton,
                  onPressed: page.canContinue ? _continue : null,
                ),
              ],
            )
          : null,
      children: [
        if (page.usesBodyMap)
          Entrance(
            index: StepLayout.firstContentIndex,
            child: BodyMap(
              options: page.options,
              selected: page.selectedIds,
              labelOf: (option) => option.label.resolve(language),
              height: math.min(340, MediaQuery.sizeOf(context).height * 0.38),
              onToggle: _select,
            ),
          )
        else
          for (final (i, option) in page.options.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Entrance(
                index: StepLayout.firstContentIndex + i,
                child: ChoiceCard(
                  label: option.label.resolve(language),
                  description: option.description?.resolve(language),
                  selected: page.isSelected(option),
                  multiSelect: page.isMulti,
                  onTap: () => _select(option),
                ),
              ),
            ),
      ],
    );
  }
}
