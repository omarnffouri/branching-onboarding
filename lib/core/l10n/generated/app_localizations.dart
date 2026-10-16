import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Label for this language in the language toggle.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get languageNameShort;

  /// No description provided for @welcomeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Lymphatic drainage Pilates'**
  String get welcomeEyebrow;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Feel lighter, stronger and more like you.'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Pilates built around your body, in minutes a day.'**
  String get welcomeBody;

  /// No description provided for @welcomeCta.
  ///
  /// In en, this message translates to:
  /// **'Build my plan'**
  String get welcomeCta;

  /// No description provided for @welcomeFootnote.
  ///
  /// In en, this message translates to:
  /// **'First, a few quick questions'**
  String get welcomeFootnote;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @progressSemantics.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String progressSemantics(int current, int total);

  /// No description provided for @multiSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Pick at least one} =1{1 selected} other{{count} selected}}'**
  String multiSelectedCount(int count);

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like an email address yet.'**
  String get emailInvalid;

  /// No description provided for @emailSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Did you mean {email}?'**
  String emailSuggestion(String email);

  /// No description provided for @emailUseSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Use it'**
  String get emailUseSuggestion;

  /// No description provided for @resumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String resumeTitle(String name);

  /// No description provided for @resumeTitleNoName.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get resumeTitleNoName;

  /// No description provided for @resumeBody.
  ///
  /// In en, this message translates to:
  /// **'Your answers are saved. Let\'s pick up where you left off.'**
  String get resumeBody;

  /// No description provided for @buildingTitle.
  ///
  /// In en, this message translates to:
  /// **'Building your plan'**
  String get buildingTitle;

  /// No description provided for @buildingReady.
  ///
  /// In en, this message translates to:
  /// **'Your plan is ready'**
  String get buildingReady;

  /// No description provided for @planEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Your personal plan'**
  String get planEyebrow;

  /// No description provided for @planHighlightsTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s inside'**
  String get planHighlightsTitle;

  /// No description provided for @planAnswersTitle.
  ///
  /// In en, this message translates to:
  /// **'Built from your answers'**
  String get planAnswersTitle;

  /// No description provided for @planAnswersHint.
  ///
  /// In en, this message translates to:
  /// **'Tap an answer to change it. Your plan updates instantly.'**
  String get planAnswersHint;

  /// No description provided for @planCta.
  ///
  /// In en, this message translates to:
  /// **'Start my plan'**
  String get planCta;

  /// No description provided for @planEditSemantics.
  ///
  /// In en, this message translates to:
  /// **'Change {label}'**
  String planEditSemantics(String label);

  /// No description provided for @currencyAmount.
  ///
  /// In en, this message translates to:
  /// **'{currency} {amount}'**
  String currencyAmount(String currency, String amount);

  /// No description provided for @currencyAed.
  ///
  /// In en, this message translates to:
  /// **'AED'**
  String get currencyAed;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Your plan is waiting, {name}'**
  String paywallTitle(String name);

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you\'d like to start. Cancel anytime.'**
  String get paywallSubtitle;

  /// No description provided for @paywallPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{price}/month'**
  String paywallPerMonth(String price);

  /// No description provided for @paywallBilledMonthly.
  ///
  /// In en, this message translates to:
  /// **'Billed monthly'**
  String get paywallBilledMonthly;

  /// No description provided for @paywallBilledYearly.
  ///
  /// In en, this message translates to:
  /// **'{price} billed yearly'**
  String paywallBilledYearly(String price);

  /// No description provided for @paywallBilledEveryMonths.
  ///
  /// In en, this message translates to:
  /// **'{price} every {months} months'**
  String paywallBilledEveryMonths(String price, int months);

  /// No description provided for @paywallSave.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String paywallSave(int percent);

  /// No description provided for @paywallTrialDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1-day free trial} other{{days}-day free trial}}'**
  String paywallTrialDays(int days);

  /// No description provided for @paywallCtaTrial.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Start my free day} other{Start my {days}-day free trial}}'**
  String paywallCtaTrial(int days);

  /// No description provided for @paywallCtaSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe for {price}'**
  String paywallCtaSubscribe(String price);

  /// No description provided for @paywallTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'How your free trial works'**
  String get paywallTimelineTitle;

  /// No description provided for @paywallTimelineToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get paywallTimelineToday;

  /// No description provided for @paywallTimelineTodayBody.
  ///
  /// In en, this message translates to:
  /// **'Your full plan unlocks. Start your first session.'**
  String get paywallTimelineTodayBody;

  /// No description provided for @paywallTimelineDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String paywallTimelineDay(int day);

  /// No description provided for @paywallTimelineReminderBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll remind you before your trial ends.'**
  String get paywallTimelineReminderBody;

  /// No description provided for @paywallTimelineBillingBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re billed {price}. Cancel before and you pay nothing.'**
  String paywallTimelineBillingBody(String price);

  /// No description provided for @paywallFinePrint.
  ///
  /// In en, this message translates to:
  /// **'Demo only: nothing is charged and no store account is needed.'**
  String get paywallFinePrint;

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Traininpink, {name}'**
  String successTitle(String name);

  /// No description provided for @successTrialBody.
  ///
  /// In en, this message translates to:
  /// **'Your free trial is on until {date}. Your first session is ready whenever you are.'**
  String successTrialBody(String date);

  /// No description provided for @successBody.
  ///
  /// In en, this message translates to:
  /// **'Your {plan} membership is active. Your first session is ready whenever you are.'**
  String successBody(String plan);

  /// No description provided for @successRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart the demo'**
  String get successRestart;

  /// No description provided for @memberCardMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get memberCardMember;

  /// No description provided for @memberCardActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get memberCardActive;

  /// No description provided for @memberCardName.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get memberCardName;

  /// Comma-separated first names typed as an animated placeholder.
  ///
  /// In en, this message translates to:
  /// **'Layla,Noura,Sara,Mariam'**
  String get nameExamples;

  /// No description provided for @tapeHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the tape'**
  String get tapeHint;

  /// No description provided for @skipQuestion.
  ///
  /// In en, this message translates to:
  /// **'I\'m not sure, skip'**
  String get skipQuestion;

  /// No description provided for @weekEyebrow.
  ///
  /// In en, this message translates to:
  /// **'FIND YOUR RHYTHM'**
  String get weekEyebrow;

  /// No description provided for @weekLimit.
  ///
  /// In en, this message translates to:
  /// **'Let\'s start with {max} sessions. You can add more later.'**
  String weekLimit(int max);

  /// No description provided for @rhythmSessions.
  ///
  /// In en, this message translates to:
  /// **'sessions a week'**
  String get rhythmSessions;

  /// No description provided for @rhythmSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe to find your pace'**
  String get rhythmSwipe;

  /// No description provided for @rhythmCta.
  ///
  /// In en, this message translates to:
  /// **'This feels right'**
  String get rhythmCta;

  /// No description provided for @rhythmLess.
  ///
  /// In en, this message translates to:
  /// **'Fewer sessions'**
  String get rhythmLess;

  /// No description provided for @rhythmMore.
  ///
  /// In en, this message translates to:
  /// **'More sessions'**
  String get rhythmMore;

  /// No description provided for @bodyFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get bodyFront;

  /// No description provided for @bodyBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get bodyBack;

  /// No description provided for @rhythmValue.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions a week'**
  String rhythmValue(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
