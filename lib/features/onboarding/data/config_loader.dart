import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/config_validator.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

const onboardingConfigAsset = 'assets/config/onboarding.json';

/// Loads and validates the bundled config. Throws `ConfigFormatException` or
/// `InvalidConfigException` with every problem listed, so a bad edit is
/// obvious the first time the app runs.
Future<FlowConfig> loadOnboardingConfig(AssetBundle bundle) async {
  final raw = await bundle.loadString(onboardingConfigAsset);
  final config = FlowConfig.fromJson(jsonDecode(raw));
  ConfigValidator.ensureValid(config);
  return config;
}
