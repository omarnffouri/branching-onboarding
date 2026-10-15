import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_analytics.dart';
import 'package:traininpink_onboarding/features/onboarding/application/onboarding_state.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
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
  late OnboardingAnalytics _analytics;

  @override
  OnboardingState build() {
    _config = ref.watch(flowConfigProvider);
    _engine = FlowEngine(_config);
    _store = ref.watch(onboardingStoreProvider);
    _analytics = ref.watch(onboardingAnalyticsProvider);

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

  void continueFrom(String stepId) {
    if (!_isOnStep(stepId)) return;
    var resolution = state.resolution;
    if (_config.stepById(stepId) is InfoStep) {
      resolution = _engine.resolve({
        ...state.answers,
        stepId: const Acknowledged(),
      });
    }
    if (!resolution.isAnswered(stepId)) return;
    _analytics('step_completed', {
      'step': stepId,
      'index': resolution.indexOf(stepId),
    });

    final next = state.editingFromPlan
        ? resolution.firstUnansweredAfter(stepId)
        : resolution.stepAfter(stepId);
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
    final previous = state.resolution.stepBefore(stepId);
    if (previous == null) {
      _set(state.copyWith(stage: OnboardingStage.welcome));
    } else {
      _set(state.copyWith(currentStepId: previous.id));
    }
  }

  // -- Plan and paywall ------------------------------------------------------

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
        currentStepId: stepId,
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
        currentStepId: state.path.last.id,
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
    _set(
      state.copyWith(
        stage: OnboardingStage.questions,
        resolution: resolution,
        currentStepId: step.id,
      ),
    );
    _analytics('step_viewed', {
      'step': step.id,
      'index': resolution.indexOf(step.id),
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
