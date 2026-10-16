// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageNameShort => 'EN';

  @override
  String get welcomeEyebrow => 'Lymphatic drainage Pilates';

  @override
  String get welcomeTitle => 'Feel lighter, stronger and more like you.';

  @override
  String get welcomeBody => 'Pilates built around your body, in minutes a day.';

  @override
  String get welcomeCta => 'Build my plan';

  @override
  String get welcomeFootnote => 'First, a few quick questions';

  @override
  String get continueButton => 'Continue';

  @override
  String get backButton => 'Back';

  @override
  String get closeButton => 'Close';

  @override
  String progressSemantics(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String multiSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
      zero: 'Pick at least one',
    );
    return '$_temp0';
  }

  @override
  String get emailInvalid => 'That doesn\'t look like an email address yet.';

  @override
  String emailSuggestion(String email) {
    return 'Did you mean $email?';
  }

  @override
  String get emailUseSuggestion => 'Use it';

  @override
  String resumeTitle(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get resumeTitleNoName => 'Welcome back';

  @override
  String get resumeBody =>
      'Your answers are saved. Let\'s pick up where you left off.';

  @override
  String get buildingTitle => 'Building your plan';

  @override
  String get buildingReady => 'Your plan is ready';

  @override
  String get planEyebrow => 'Your personal plan';

  @override
  String get planHighlightsTitle => 'What\'s inside';

  @override
  String get planAnswersTitle => 'Built from your answers';

  @override
  String get planAnswersHint =>
      'Tap an answer to change it. Your plan updates instantly.';

  @override
  String get planCta => 'Start my plan';

  @override
  String planEditSemantics(String label) {
    return 'Change $label';
  }

  @override
  String currencyAmount(String currency, String amount) {
    return '$currency $amount';
  }

  @override
  String get currencyAed => 'AED';

  @override
  String paywallTitle(String name) {
    return 'Your plan is waiting, $name';
  }

  @override
  String get paywallSubtitle =>
      'Choose how you\'d like to start. Cancel anytime.';

  @override
  String paywallPerMonth(String price) {
    return '$price/month';
  }

  @override
  String get paywallBilledMonthly => 'Billed monthly';

  @override
  String paywallBilledYearly(String price) {
    return '$price billed yearly';
  }

  @override
  String paywallBilledEveryMonths(String price, int months) {
    return '$price every $months months';
  }

  @override
  String paywallSave(int percent) {
    return 'Save $percent%';
  }

  @override
  String paywallTrialDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days-day free trial',
      one: '1-day free trial',
    );
    return '$_temp0';
  }

  @override
  String paywallCtaTrial(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Start my $days-day free trial',
      one: 'Start my free day',
    );
    return '$_temp0';
  }

  @override
  String paywallCtaSubscribe(String price) {
    return 'Subscribe for $price';
  }

  @override
  String get paywallTimelineTitle => 'How your free trial works';

  @override
  String get paywallTimelineToday => 'Today';

  @override
  String get paywallTimelineTodayBody =>
      'Your full plan unlocks. Start your first session.';

  @override
  String paywallTimelineDay(int day) {
    return 'Day $day';
  }

  @override
  String get paywallTimelineReminderBody =>
      'We\'ll remind you before your trial ends.';

  @override
  String paywallTimelineBillingBody(String price) {
    return 'You\'re billed $price. Cancel before and you pay nothing.';
  }

  @override
  String get paywallFinePrint =>
      'Demo only: nothing is charged and no store account is needed.';

  @override
  String successTitle(String name) {
    return 'Welcome to Traininpink, $name';
  }

  @override
  String successTrialBody(String date) {
    return 'Your free trial is on until $date. Your first session is ready whenever you are.';
  }

  @override
  String successBody(String plan) {
    return 'Your $plan membership is active. Your first session is ready whenever you are.';
  }

  @override
  String get successRestart => 'Restart the demo';

  @override
  String get memberCardMember => 'Member';

  @override
  String get memberCardActive => 'Active';

  @override
  String get memberCardName => 'NAME';

  @override
  String get nameExamples => 'Layla,Noura,Sara,Mariam';

  @override
  String get tapeHint => 'Drag the tape';

  @override
  String get skipQuestion => 'I\'m not sure, skip';

  @override
  String get weekEyebrow => 'FIND YOUR RHYTHM';

  @override
  String weekLimit(int max) {
    return 'Let\'s start with $max sessions. You can add more later.';
  }

  @override
  String get rhythmSessions => 'sessions a week';

  @override
  String get rhythmSwipe => 'Swipe to find your pace';

  @override
  String get rhythmCta => 'This feels right';

  @override
  String get rhythmLess => 'Fewer sessions';

  @override
  String get rhythmMore => 'More sessions';

  @override
  String get bodyFront => 'Front';

  @override
  String get bodyBack => 'Back';

  @override
  String rhythmValue(int count) {
    return '$count sessions a week';
  }
}
