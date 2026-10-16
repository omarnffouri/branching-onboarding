import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traininpink_onboarding/core/design/app_theme.dart';
import 'package:traininpink_onboarding/core/design/tokens.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';
import 'package:traininpink_onboarding/core/l10n/language_controller.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/onboarding_flow.dart';

class TraininpinkApp extends ConsumerWidget {
  const TraininpinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    return MaterialApp(
      title: 'Traininpink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.forLanguage(language),
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // Respect larger text settings, up to the point the layouts were
      // designed and tested for.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: child!,
      ),
      home: const OnboardingFlow(),
    );
  }
}

/// Shown instead of the app when the bundled config is invalid, listing
/// every problem so whoever edited the JSON can fix it in one pass.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.forLanguage('en'),
    home: Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            const Icon(Icons.rule_rounded, color: AppColors.error, size: 40),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'The onboarding config needs a fix',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            SelectableText(
              '$error',
              style: const TextStyle(fontFamily: 'Poppins', height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );
}
