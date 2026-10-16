import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/analytics/analytics.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_state.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/application/step_group.dart';
import 'package:traininpink_onboarding/features/onboarding/data/onboarding_store.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_engine.dart';

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

/// The single owner of onboarding state.
///
/// Every intent says where it came from (the step on screen, or the stage)
/// and is ignored if that is no longer true. So a double tap, or a tap on a
/// page that is still animating away, can never skip a step or go back twice.
/// No timers, no "isNavigating" flags.
///
/// Every change is saved immediately, so closing the app at any point
/// resumes exactly there.
class OnboardingController extends Notifier<OnboardingState> {
  late FlowConfig _config;
  late FlowEngine _engine;
  late OnboardingStore _store;
  late Analytics _analytics;

  @override
  OnboardingState build() {
    _config = ref.watch(flowConfigProvider);
    _engine = FlowEngine(_config);
    _store = ref.watch(onboardingStoreProvider);
    _analytics = ref.watch(analyticsProvider);

    final saved = _store.readProgress();
    final restored = saved == null
        ? null
        : OnboardingState.fromJson(saved, _config, _engine);
    if (restored == null) return _initialState();

    _analytics('onboarding_resumed', {
      'stage': restored.stage.name,
      'step': restored.currentStepId,
    });
    return restored;
  }

  OnboardingState _initialState() => OnboardingState(
    stage: OnboardingStage.welcome,
    resolution: _engine.resolve(const {}),
    selectedPlanId: _config.paywall.defaultPlanId,
  );

  // -- Questions -------------------------------------------------------------

  void start() {
    if (state.stage != OnboardingStage.welcome) return;
    final step = state.resolution.firstUnanswered ?? state.path.first;
    _analytics('onboarding_started', const {});
    _moveTo(step, state.resolution);
  }

  /// Records her answer to the step on screen without moving on. Single
  /// choice moves on a beat later, so she sees her choice land first.
  void answer(String stepId, Answer answer) {
    if (!_isOnStep(stepId)) return;
    _set(
      state.copyWith(
        resolution: _engine.resolve({...state.answers, stepId: answer}),
      ),
    );
  }

  /// Rejected choices must not start a delayed navigation in the presentation.
  bool selectChoice(String stepId, String optionId) {
    if (!_isOnStep(stepId)) return false;
    final step = _config.stepById(stepId);
    if (step is! ChoiceStep ||
        !step
            .visibleOptions(state.answers)
            .any((option) => option.id == optionId)) {
      return false;
    }
    switch (step) {
      case SingleChoiceStep():
        answer(stepId, ChoiceAnswer(optionId));
      case MultiChoiceStep():
        final selected = {
          if (state.answers[stepId] case MultiChoiceAnswer(:final optionIds))
            ...optionIds,
        };
        if (!selected.remove(optionId)) selected.add(optionId);
        answer(stepId, MultiChoiceAnswer(selected));
    }
    return true;
  }

  /// A skipped measurement has no saved value, so the tape previews initial.
  int measurementValueFor(NumberStep step) => switch (state.answers[step.id]) {
    NumberAnswer(:final value) => value,
    _ => step.initial,
  };

  /// The tape owns fractional motion; only settled whole values are saved.
  void recordMeasurement(String stepId, int value) {
    if (_config.stepById(stepId) is! NumberStep) return;
    answer(stepId, NumberAnswer(value));
  }

  void submitMeasurement(String stepId, int value) {
    if (_config.stepById(stepId) is! NumberStep) return;
    recordMeasurement(stepId, value);
    continueFrom(stepId);
  }

  /// Required questions must keep their answer even if a skip intent arrives.
  void skipStep(String stepId) {
    if (_config.stepById(stepId)?.optional != true) return;
    answer(stepId, const SkippedAnswer());
    continueFrom(stepId);
  }

  /// Both controls save together, so a changed routine sanitizes stale days
  /// in the same resolution. Hidden or departed pages cannot submit answers.
  void answerGroup(String pageStepId, Answers answers) {
    if (!_isOnStep(pageStepId)) return;
    final group = StepGroup.containing(state.path, pageStepId);
    if (answers.keys.any((id) => !group.contains(id))) return;
    _set(
      state.copyWith(
        resolution: _engine.resolve({...state.answers, ...answers}),
      ),
    );
  }

  /// Saves [value] for the step on screen and moves on, if the answer is
  /// valid there.
  ///
  /// Returns false only when the answer itself is rejected, so the screen
  /// can explain why. A stale call (a second tap on a page already left)
  /// returns true: there is nothing for her to fix.
  bool submit(String stepId, Answer value) {
    if (!_isOnStep(stepId)) return true;
    answer(stepId, value);
    if (!state.resolution.isAnswered(stepId)) return false;
    continueFrom(stepId);
    return true;
  }

  void continueFrom(String stepId) {
    if (!_isOnStep(stepId)) return;
    continueGroup(stepId);
  }

  /// A single guarded transition completes every question on this page.
  void continueGroup(String pageStepId) {
    if (!_isOnStep(pageStepId)) return;
    final group = StepGroup.containing(state.path, pageStepId);
    final resolution = _engine.resolve({
      ...state.answers,
      for (final step in group.steps)
        if (step is InfoStep) step.id: const Acknowledged(),
    });
    if (group.steps.any((step) => !resolution.isAnswered(step.id))) return;
    for (final step in group.steps) {
      _analytics('step_completed', {
        'step': step.id,
        'index': resolution.indexOf(step.id),
      });
    }

    final next = state.editingFromPlan
        ? resolution.firstUnansweredAfter(group.last.id)
        : resolution.stepAfter(group.last.id);
    if (next != null) {
      _moveTo(next, resolution);
    } else if (state.editingFromPlan) {
      _set(
        state.copyWith(
          resolution: resolution,
          stage: OnboardingStage.plan,
          editingFromPlan: false,
        ),
      );
      _analytics('plan_viewed', {'after_edit': true});
    } else {
      _set(
        state.copyWith(resolution: resolution, stage: OnboardingStage.building),
      );
    }
  }

  /// Back from a question. Her answer stays, so coming forward again shows it.
  void backFromStep(String stepId) {
    if (!_isOnStep(stepId)) return;
    _analytics('step_back', {'step': stepId});
    final group = StepGroup.containing(state.path, stepId);
    final previous = state.resolution.stepBefore(group.first.id);
    if (previous == null) {
      _set(state.copyWith(stage: OnboardingStage.welcome));
    } else {
      _set(
        state.copyWith(
          currentStepId: StepGroup.containing(state.path, previous.id).first.id,
        ),
      );
    }
  }

  // -- Plan and paywall ------------------------------------------------------

  /// The "building your plan" fill reached 100%: a firm tap, then the plan
  /// after a short beat so she sees "ready".
  void planBuilt() {
    if (state.stage != OnboardingStage.building) return;
    HapticFeedback.mediumImpact().ignore();
    Timer(const Duration(milliseconds: 750), () {
      if (ref.mounted) finishBuilding();
    });
  }

  void finishBuilding() {
    if (state.stage != OnboardingStage.building) return;
    _set(state.copyWith(stage: OnboardingStage.plan));
    _analytics('plan_viewed', const {});
  }

  /// She tapped an answer on her plan to change it.
  void editFromPlan(String stepId) {
    if (state.stage != OnboardingStage.plan) return;
    final step = _config.stepById(stepId);
    if (step == null || !state.resolution.contains(stepId)) return;
    _analytics('plan_edit', {'step': stepId});
    _set(
      state.copyWith(
        stage: OnboardingStage.questions,
        currentStepId: StepGroup.containing(state.path, stepId).first.id,
        editingFromPlan: true,
      ),
    );
  }

  /// Back from the plan returns to her last question.
  void backFromPlan() {
    if (state.stage != OnboardingStage.plan) return;
    _set(
      state.copyWith(
        stage: OnboardingStage.questions,
        currentStepId: state.pageGroups.last.first.id,
        editingFromPlan: false,
      ),
    );
  }

  void openPaywall() {
    if (state.stage != OnboardingStage.plan) return;
    _set(state.copyWith(stage: OnboardingStage.paywall));
    _analytics('paywall_viewed', {'default_plan': state.selectedPlanId});
  }

  void closePaywall() {
    if (state.stage != OnboardingStage.paywall) return;
    _set(state.copyWith(stage: OnboardingStage.plan));
    _analytics('paywall_closed', {'plan': state.selectedPlanId});
  }

  void selectPlan(String planId) {
    if (state.stage != OnboardingStage.paywall ||
        state.selectedPlanId == planId ||
        !_config.paywall.plans.any((plan) => plan.id == planId)) {
      return;
    }
    _set(state.copyWith(selectedPlanId: planId));
    _analytics('plan_selected', {'plan': planId});
  }

  /// Nothing is really purchased: subscribing records her choice.
  void subscribe() {
    if (state.stage != OnboardingStage.paywall) return;
    _set(
      state.copyWith(
        stage: OnboardingStage.subscribed,
        subscription: Subscription(
          planId: state.selectedPlanId,
          subscribedAt: DateTime.now(),
        ),
      ),
    );
    _analytics('subscribed', {'plan': state.selectedPlanId});
  }

  // -- Session ---------------------------------------------------------------

  void dismissResumeGreeting() {
    if (state.resumed) state = state.copyWith(resumed: false);
  }

  Future<void> restart() async {
    await _store.clearProgress();
    state = _initialState();
    _analytics('onboarding_restarted', const {});
  }

  // -- Internals -------------------------------------------------------------

  bool _isOnStep(String stepId) =>
      state.stage == OnboardingStage.questions && state.currentStepId == stepId;

  void _moveTo(FlowStep step, FlowResolution resolution) {
    final pageStep = StepGroup.containing(resolution.path, step.id).first;
    _set(
      state.copyWith(
        stage: OnboardingStage.questions,
        resolution: resolution,
        currentStepId: pageStep.id,
      ),
    );
    _analytics('step_viewed', {
      'step': pageStep.id,
      'index': resolution.indexOf(pageStep.id),
      'path_length': resolution.path.length,
    });
  }

  void _set(OnboardingState next) {
    state = next;
    unawaited(
      _store.writeProgress(next.toJson(_config)).catchError((Object error) {
        // Losing a save is worth a log line, never a crash mid-onboarding.
        developer.log('Could not save progress: $error', name: 'onboarding');
      }),
    );
  }
}
