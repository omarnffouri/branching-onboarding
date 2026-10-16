import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sends a funnel event to analytics (README, question 2).
///
/// Logged locally for now so events can be watched while running the app,
/// and captured in tests to check the funnel is instrumented.
typedef Analytics =
    void Function(String event, Map<String, Object?> properties);

void logAnalyticsEvent(String event, Map<String, Object?> properties) =>
    developer.log('$event $properties', name: 'app.analytics');

/// App-wide, so any feature can log; swap in a real backend here.
final analyticsProvider = Provider<Analytics>((ref) => logAnalyticsEvent);
