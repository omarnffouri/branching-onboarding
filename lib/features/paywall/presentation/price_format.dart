import 'package:intl/intl.dart';
import 'package:traininpink_onboarding/core/l10n/generated/app_localizations.dart';

/// "AED 29.08" / "29.08 د.إ". Whole amounts drop the decimals ("AED 349").
///
/// Digits stay Western in Arabic too, as they do across Gulf apps and on
/// the prices members see in the App Store.
String formatPrice(AppLocalizations l10n, String currency, double amount) {
  final isWhole = amount == amount.roundToDouble();
  final number = NumberFormat.decimalPatternDigits(
    locale: 'en',
    decimalDigits: isWhole ? 0 : 2,
  ).format(amount);
  final symbol = switch (currency) {
    'AED' => l10n.currencyAed,
    _ => currency,
  };
  return l10n.currencyAmount(symbol, number);
}
