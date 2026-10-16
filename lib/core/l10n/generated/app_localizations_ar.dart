// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get languageNameShort => 'ع';

  @override
  String get welcomeEyebrow => 'بيلاتس التصريف الليمفاوي';

  @override
  String get welcomeTitle => 'اشعري بالخفّة والقوة، وكوني أنتِ أكثر.';

  @override
  String get welcomeBody => 'بيلاتس مصمّم حول جسمكِ، في دقائق كل يوم.';

  @override
  String get welcomeCta => 'صمّمي خطتي';

  @override
  String get welcomeFootnote => 'أولاً، بضعة أسئلة سريعة';

  @override
  String get continueButton => 'متابعة';

  @override
  String get backButton => 'رجوع';

  @override
  String get closeButton => 'إغلاق';

  @override
  String progressSemantics(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String multiSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم اختيار $count',
      many: 'تم اختيار $count',
      few: 'تم اختيار $count',
      two: 'تم اختيار اثنتين',
      one: 'تم اختيار واحدة',
      zero: 'اختاري واحدة على الأقل',
    );
    return '$_temp0';
  }

  @override
  String get emailInvalid => 'لا يبدو هذا بريداً إلكترونياً صحيحاً بعد.';

  @override
  String emailSuggestion(String email) {
    return 'هل تقصدين $email؟';
  }

  @override
  String get emailUseSuggestion => 'استخدميه';

  @override
  String resumeTitle(String name) {
    return 'أهلاً بعودتكِ يا $name';
  }

  @override
  String get resumeTitleNoName => 'أهلاً بعودتكِ';

  @override
  String get resumeBody => 'إجاباتكِ محفوظة. لنكمل من حيث توقّفتِ.';

  @override
  String get buildingTitle => 'نصمّم خطتكِ';

  @override
  String get buildingReady => 'خطتكِ جاهزة';

  @override
  String get planEyebrow => 'خطتكِ الشخصية';

  @override
  String get planHighlightsTitle => 'ما تتضمّنه خطتكِ';

  @override
  String get planAnswersTitle => 'مبنية على إجاباتكِ';

  @override
  String get planAnswersHint =>
      'اضغطي على أي إجابة لتغييرها، وستتحدّث خطتكِ فوراً.';

  @override
  String get planCta => 'ابدئي خطتي';

  @override
  String planEditSemantics(String label) {
    return 'تغيير $label';
  }

  @override
  String currencyAmount(String currency, String amount) {
    return '$amount $currency';
  }

  @override
  String get currencyAed => 'د.إ';

  @override
  String paywallTitle(String name) {
    return 'خطتكِ بانتظاركِ يا $name';
  }

  @override
  String get paywallSubtitle =>
      'اختاري طريقة البدء التي تناسبكِ. يمكنكِ الإلغاء في أي وقت.';

  @override
  String paywallPerMonth(String price) {
    return '$price شهرياً';
  }

  @override
  String get paywallBilledMonthly => 'تُدفع شهرياً';

  @override
  String paywallBilledYearly(String price) {
    return '$price تُدفع سنوياً';
  }

  @override
  String paywallBilledEveryMonths(String price, int months) {
    return '$price كل $months أشهر';
  }

  @override
  String paywallSave(int percent) {
    return 'وفّري $percent٪';
  }

  @override
  String paywallTrialDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'تجربة مجانية لمدة $days يوماً',
      few: 'تجربة مجانية لمدة $days أيام',
      two: 'تجربة مجانية ليومين',
      one: 'تجربة مجانية ليوم واحد',
    );
    return '$_temp0';
  }

  @override
  String paywallCtaTrial(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'ابدئي تجربتكِ المجانية لمدة $days يوماً',
      few: 'ابدئي تجربتكِ المجانية لمدة $days أيام',
      two: 'ابدئي تجربتكِ المجانية ليومين',
      one: 'ابدئي يومكِ المجاني',
    );
    return '$_temp0';
  }

  @override
  String paywallCtaSubscribe(String price) {
    return 'اشتركي مقابل $price';
  }

  @override
  String get paywallTimelineTitle => 'كيف تعمل تجربتكِ المجانية';

  @override
  String get paywallTimelineToday => 'اليوم';

  @override
  String get paywallTimelineTodayBody =>
      'تُفتح خطتكِ كاملة. ابدئي جلستكِ الأولى.';

  @override
  String paywallTimelineDay(int day) {
    return 'اليوم $day';
  }

  @override
  String get paywallTimelineReminderBody => 'سنذكّركِ قبل انتهاء التجربة.';

  @override
  String paywallTimelineBillingBody(String price) {
    return 'تُدفع $price. ألغي قبل ذلك ولن تدفعي شيئاً.';
  }

  @override
  String get paywallFinePrint =>
      'عرض تجريبي فقط: لن يُخصم أي مبلغ ولا حاجة لحساب في المتجر.';

  @override
  String successTitle(String name) {
    return 'أهلاً بكِ في Traininpink يا $name';
  }

  @override
  String successTrialBody(String date) {
    return 'تجربتكِ المجانية مستمرة حتى $date. جلستكِ الأولى جاهزة متى ما كنتِ مستعدة.';
  }

  @override
  String successBody(String plan) {
    return 'اشتراككِ $plan مفعّل. جلستكِ الأولى جاهزة متى ما كنتِ مستعدة.';
  }

  @override
  String get successRestart => 'إعادة العرض التجريبي';

  @override
  String get memberCardMember => 'عضوة';

  @override
  String get memberCardActive => 'مفعّلة';

  @override
  String get memberCardName => 'الاسم';

  @override
  String get nameExamples => 'ليلى,نورة,سارة,مريم';

  @override
  String get tapeHint => 'اسحبي الشريط';

  @override
  String get weekEyebrow => 'اكتشفي إيقاعكِ';

  @override
  String weekLimit(int max) {
    return 'لنبدأ بـ $max جلسات. يمكنكِ إضافة المزيد لاحقاً.';
  }

  @override
  String get rhythmSessions => 'جلسات في الأسبوع';

  @override
  String get rhythmSwipe => 'اسحبي لتختاري إيقاعكِ';

  @override
  String get rhythmCta => 'هذا يناسبني';

  @override
  String get rhythmLess => 'جلسات أقل';

  @override
  String get rhythmMore => 'جلسات أكثر';

  @override
  String rhythmValue(int count) {
    return '$count جلسات في الأسبوع';
  }
}
