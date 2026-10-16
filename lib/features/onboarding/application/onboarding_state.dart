import 'package:meta/meta.dart';
import 'package:traininpink_onboarding/features/onboarding/application/step_group.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/answer.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_engine.dart';

enum OnboardingStage { welcome, questions, building, plan, paywall, subscribed }

@immutable
final class Subscription {
  const Subscription({required this.planId, required this.subscribedAt});

  final String planId;
  final DateTime subscribedAt;

  Map<String, Object?> toJson() => {
    'planId': planId,
    'subscribedAt': subscribedAt.toIso8601String(),
  };

  static Subscription? fromJson(Object? json) => switch (json) {
    {'planId': final String planId, 'subscribedAt': final String at} =>
      Subscription(
        planId: planId,
        subscribedAt: DateTime.tryParse(at) ?? DateTime.now(),
      ),
    _ => null,
  };
}

/// Everything the onboarding UI renders from. Owned by `OnboardingController`;
/// widgets read it and send intents back, they never mutate it.
@immutable
final class OnboardingState {
  const OnboardingState({
    required this.stage,
    required this.resolution,
    required this.selectedPlanId,
    this.currentStepId,
    this.editingFromPlan = false,
    this.subscription,
    this.resumed = false,
  });

  final OnboardingStage stage;

  /// Her path and the answers on it, derived by `FlowEngine`.
  final FlowResolution resolution;

  /// The question on screen while [stage] is [OnboardingStage.questions].
  final String? currentStepId;

  /// She jumped back from the plan to change an answer. Continuing then skips
  /// what she already answered and returns to the plan.
  final bool editingFromPlan;

  final String selectedPlanId;
  final Subscription? subscription;

  /// Restored from a previous session; the UI greets her back once.
  final bool resumed;

  Answers get answers => resolution.answers;
  List<FlowStep> get path => resolution.path;

  int get currentIndex =>
      currentStepId == null ? -1 : resolution.indexOf(currentStepId!);

  List<StepGroup> get pageGroups => StepGroup.fromPath(path);

  int get currentPageIndex =>
      pageGroups.indexWhere((group) => group.contains(currentStepId ?? ''));

  /// 0..1 across the questions. The last question does not read as 100%:
  /// the plan reveal is what completes it.
  double get progress => switch (stage) {
    OnboardingStage.welcome => 0,
    OnboardingStage.questions =>
      (currentPageIndex + 1) / (pageGroups.length + 1),
    _ => 1,
  };

  OnboardingState copyWith({
    OnboardingStage? stage,
    FlowResolution? resolution,
    String? currentStepId,
    bool? editingFromPlan,
    String? selectedPlanId,
    Subscription? subscription,
    bool? resumed,
  }) => OnboardingState(
    stage: stage ?? this.stage,
    resolution: resolution ?? this.resolution,
    currentStepId: currentStepId ?? this.currentStepId,
    editingFromPlan: editingFromPlan ?? this.editingFromPlan,
    selectedPlanId: selectedPlanId ?? this.selectedPlanId,
    subscription: subscription ?? this.subscription,
    resumed: resumed ?? this.resumed,
  );

  Map<String, Object?> toJson(FlowConfig config) => {
    'configVersion': config.version,
    'stage': stage.name,
    'currentStepId': currentStepId,
    'editingFromPlan': editingFromPlan,
    'answers': {
      for (final MapEntry(:key, :value) in answers.entries) key: value.toJson(),
    },
    'selectedPlanId': selectedPlanId,
    'subscription': ?subscription?.toJson(),
  };

  /// Rebuilds saved progress against the *current* config. Anything that no
  /// longer fits (a removed step, a renamed option, a newer config version)
  /// is dropped rather than trusted. Returns null if nothing usable is left.
  static OnboardingState? fromJson(
    Map<String, Object?> json,
    FlowConfig config,
    FlowEngine engine,
  ) {
    if (json['configVersion'] != config.version) return null;

    final savedStage = OnboardingStage.values.asNameMap()[json['stage']];
    final rawAnswers = json['answers'];
    if (savedStage == null || rawAnswers is! Map<String, Object?>) return null;

    final resolution = engine.resolve({
      for (final MapEntry(:key, :value) in rawAnswers.entries)
        key: ?config.stepById(key)?.answerFromJson(value),
    });
    final subscription = Subscription.fromJson(json['subscription']);

    var stage = switch (savedStage) {
      // The building animation is a moment, not a place to resume into.
      OnboardingStage.building => OnboardingStage.plan,
      OnboardingStage.subscribed when subscription == null =>
        OnboardingStage.paywall,
      _ => savedStage,
    };

    final savedStepId = json['currentStepId'];
    var currentStepId =
        savedStepId is String && resolution.contains(savedStepId)
        ? savedStepId
        : (resolution.firstUnanswered ?? resolution.path.last).id;

    // The plan needs every answer. If the config gained a question since she
    // last opened the app, send her to it rather than show a broken plan.
    final isPastQuestions =
        stage != OnboardingStage.welcome && stage != OnboardingStage.questions;
    if (isPastQuestions && !resolution.isComplete) {
      stage = OnboardingStage.questions;
      currentStepId = resolution.firstUnanswered!.id;
    }
    // A changed question type can invalidate an answer before the saved
    // cursor. Revisit it before allowing an incomplete plan to be built.
    final unanswered = resolution.firstUnanswered;
    if (stage == OnboardingStage.questions &&
        unanswered != null &&
        resolution.indexOf(unanswered.id) < resolution.indexOf(currentStepId)) {
      currentStepId = unanswered.id;
    }

    final savedPlanId = json['selectedPlanId'];
    currentStepId = StepGroup.containing(
      resolution.path,
      currentStepId,
    ).first.id;
    return OnboardingState(
      stage: stage,
      resolution: resolution,
      currentStepId: currentStepId,
      editingFromPlan:
          stage == OnboardingStage.questions && json['editingFromPlan'] == true,
      selectedPlanId:
          savedPlanId is String &&
              config.paywall.plans.any((plan) => plan.id == savedPlanId)
          ? savedPlanId
          : config.paywall.defaultPlanId,
      subscription: subscription,
      resumed:
          stage != OnboardingStage.welcome &&
          stage != OnboardingStage.subscribed,
    );
  }
}
