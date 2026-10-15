import 'dart:developer' as developer;

/// Sends a funnel event to analytics (README, question 2).
///
/// Logged locally for now so events can be watched while running the app,
/// and captured in tests to check the funnel is instrumented.
typedef OnboardingAnalytics =
    void Function(String event, Map<String, Object?> properties);

void logAnalyticsEvent(String event, Map<String, Object?> properties) =>
    developer.log('$event $properties', name: 'onboarding.analytics');
