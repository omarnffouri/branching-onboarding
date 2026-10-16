import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:traininpink_onboarding/app.dart';
import 'package:traininpink_onboarding/features/onboarding/application/providers.dart';
import 'package:traininpink_onboarding/features/onboarding/data/config_loader.dart';
import 'package:traininpink_onboarding/features/onboarding/data/onboarding_store.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Western digits in Arabic dates, matching prices and the rest of the UI.
  DateFormat.useNativeDigitsByDefaultFor('ar', false);

  // Both load in milliseconds before the first frame, behind the native
  // splash, so no screen ever has to render a loading state.
  final FlowConfig config;
  try {
    config = await loadOnboardingConfig(rootBundle);
  } on Object catch (error) {
    runApp(ConfigErrorApp(error: error));
    return;
  }
  final store = await SharedPreferencesOnboardingStore.create();

  runApp(
    ProviderScope(
      overrides: [
        flowConfigProvider.overrideWithValue(config),
        onboardingStoreProvider.overrideWithValue(store),
      ],
      child: const TraininpinkApp(),
    ),
  );
}
