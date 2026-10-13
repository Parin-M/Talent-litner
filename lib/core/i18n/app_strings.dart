import 'package:flutter/material.dart';
import 'language_overrides.dart';

class AppStrings {
  final Locale locale;
  const AppStrings(this.locale);

  static const delegate = _AppStringsDelegate();
  static const supportedLocales = <Locale>[
    Locale('fa'), Locale('en'), Locale('de'), Locale('de', 'CH'), Locale('de', 'AT'), Locale('nl'),
    Locale('es'), Locale('pt'), Locale('fr'), Locale('da'), Locale('no'), Locale('fi'), Locale('sv'),
    Locale('is'), Locale('el'), Locale('ar'), Locale('he'), Locale('ja'), Locale('ko'), Locale('it'), Locale('tr'),
  ];

  static const names = <String, String>{
    'fa':'فارسی','en':'English','de':'Deutsch','de-CH':'Deutsch (Schweiz)','de-AT':'Deutsch (Österreich)','nl':'Nederlands',
    'es':'Español','pt':'Português','fr':'Français','da':'Dansk','no':'Norsk','fi':'Suomi','sv':'Svenska','is':'Íslenska',
    'el':'Ελληνικά','ar':'العربية','he':'עברית','ja':'日本語','ko':'한국어','it':'Italiano','tr':'Türkçe',
  };

  static String t(BuildContext context, String key) => AppStrings(Localizations.localeOf(context)).text(key);

  String text(String key) {
    final code = locale.countryCode == null ? locale.languageCode : '${locale.languageCode}-${locale.countryCode}';
    final translated = LanguageOverrides.maps[code]?[key] ?? LanguageOverrides.maps[locale.languageCode]?[key];
    if (translated != null) return translated;
    return _maps[code]?[key] ?? _maps[locale.languageCode]?[key] ?? _en[key] ?? key;
  }

  static const _en = <String,String>{
    'home':'Home','settings':'Settings','language':'Language','ui_language':'Interface language','choose_language':'Choose the app language',
    'theme':'Color theme','appearance':'Appearance','visual_style':'Interface style','mode_light':'Light','mode_dark':'Dark','mode_aero':'Aero glass','mode_amoled':'AMOLED dark','glass':'Glass effect','glass_sub':'Light translucent glass','music':'Relaxing music','music_study':'Music while studying',
    'experience':'Study experience','animations':'Animations','haptics':'Haptic feedback','auto_reveal':'Auto reveal','progress':'Show progress','timer':'Timer','daily_goal':'Daily goal',
    'backup':'Backup','backup_saved':'Backup exported successfully (.plbackup).','backup_cancelled':'Backup export was cancelled.','backup_error':'Could not create the backup.','backup_invalid':'The selected backup is invalid or damaged.','extra':'More features','decks':'Learning decks','cards':'Cards','today':'Today','new_deck':'New deck','new_deck_hint':'Deck name','build':'Create',
    'new_card':'New card','edit_card':'Edit card','search':'Search cards…','study':'Study','study_type':'Study mode','rename':'Rename','delete':'Delete','save':'Save','cancel':'Cancel',
    'boxes':'Manage boxes','box':'Box','all':'All cards','favorite_only':'Favorites only','cards_ready':'Due today','no_review':'No cards to review in this mode.','no_cards':'No cards found',
    'cards_count':'cards','ready_count':'ready','save_card':'Save card','add_image':'Add image','change_image':'Change image','front_image':'Front image','back_image':'Back image',
    'card_front':'Front / Question','card_back':'Back / Answer','front_hint':'Write the question','back_hint':'Write the answer','tags':'Tags','tags_hint':'e.g. exam, English',
    'delete_card':'Delete card?','delete_card_confirm':'This card will be permanently deleted.','image_error':'Could not open this image.','image_unavailable':'Image unavailable',
    'again':'Again','hard':'Hard','good':'Good','easy':'Easy','music_btn':'Music','done':'Session complete!','great':'Great!','no_due':'No cards to review 🎉',
    'swipe':'Swipe to rate the card.','tap':'Tap the card to reveal the answer.','answer':'Answer','goal_done':'Daily goal complete! 🎉','ready':'Ready for a quick review?',
    'merge':'Merge','replace':'Replace','export':'Export','import':'Import','add_box':'Add box','box_name':'Box name','delete_box':'Delete box?','delete_box_confirm':'Cards in this box will move to the first box.',
    'create':'Create','close':'Close','focus_mode':'Focus Mode','focus_title':'Deep Focus','focus_sub':'Stay focused with a distraction-free timer','start_focus':'Start focus','pause':'Pause','reset':'Reset',
    'focus_done':'Focus session complete!','focus_minutes':'minutes','focus_music':'Play focus music','select_duration':'Session length','minutes_15':'15 min','minutes_25':'25 min','minutes_45':'45 min',
    'about':'About','about_creator':'Created by Parin.M','about_creator_desc':'This software was created by Parin.M (Parin.M).','about_ai':'ChatGPT also helped with its creation, development, and refinement.',
    'about_github':'GitHub Repository','about_repo_desc':'Open the Parin Litner project on GitHub','about_open_error':'Could not open GitHub repository.','about_love':'Made with love on planet Earth. 🌍❤️',
    'about_version_title':'App version','about_android_compat':'Compatible with Android 4.0 and newer',
    'smart_mix_filter':'Smart Mix Filter','filter_all':'All cards','filter_due':'Due for review','filter_hard':'Hard cards','filter_medium':'Medium cards','filter_easy':'Easy cards','pc_no_cards_for_filter':'No cards match this filter. Choose another filter.',
    'study_preferences':'Study preferences','show_xp':'Show XP feedback','show_xp_sub':'Display XP earned after each review','confirm_exit':'Confirm before leaving study','confirm_exit_sub':'Ask before closing an active study session',
    'compact_settings':'Compact settings','compact_settings_sub':'Use tighter spacing in Settings','achievement_center':'Achievement Center','achievement_center_sub':'Badges, daily challenges and progress',
    'smart_mix':'Smart Study Mix','smart_mix_sub':'A future-ready home for smart review modes','smart_mix_available':'Smart Study Mix is available in Power Center',
  };

  static const _fa = <String,String>{
    'home':'خانه','settings':'تنظیمات','language':'زبان','ui_language':'زبان رابط کاربری','choose_language':'زبان برنامه را انتخاب کنید','theme':'تم رنگی','appearance':'ظاهر برنامه','visual_style':'سبک ظاهری','mode_light':'حالت روشن','mode_dark':'حالت تاریک','mode_aero':'شیشه‌ای Aero','mode_amoled':'مشکی AMOLED','glass':'افکت شیشه‌ای','glass_sub':'ظاهر شفاف و شیشه‌ای سبک',
    'music':'موسیقی آرام‌بخش','music_study':'موسیقی هنگام مطالعه','experience':'تجربه مطالعه','animations':'انیمیشن‌ها','haptics':'بازخورد لرزشی','auto_reveal':'نمایش خودکار پاسخ','progress':'نمایش پیشرفت','timer':'زمان‌سنج','daily_goal':'هدف روزانه',
    'backup':'پشتیبان‌گیری','backup_saved':'فایل پشتیبان با موفقیت ذخیره شد.','backup_cancelled':'ذخیره پشتیبان لغو شد.','backup_error':'ساخت فایل پشتیبان ممکن نشد.','backup_invalid':'فایل پشتیبان نامعتبر یا آسیب‌دیده است.','extra':'قابلیت‌های بیشتر','decks':'دسته‌های یادگیری','cards':'کارت‌ها','today':'امروز','new_deck':'دسته جدید','new_deck_hint':'نام دسته','build':'ساختن','new_card':'کارت جدید','edit_card':'ویرایش کارت',
    'search':'جستجوی کارت…','study':'مرور','study_type':'نوع مرور','rename':'تغییر نام','delete':'حذف','save':'ذخیره','cancel':'لغو','boxes':'مدیریت خانه‌ها','box':'خانه','all':'همه کارت‌ها','favorite_only':'فقط محبوب‌ها','cards_ready':'کارت‌های آماده امروز',
    'no_review':'در این حالت کارتی برای مرور وجود ندارد.','no_cards':'کارتی پیدا نشد','cards_count':'کارت','ready_count':'آماده مرور','save_card':'ذخیره کارت','add_image':'افزودن عکس','change_image':'تغییر عکس','front_image':'تصویر روی کارت','back_image':'تصویر پشت کارت',
    'card_front':'روی کارت / سؤال','card_back':'پشت کارت / پاسخ','front_hint':'سؤال را بنویسید','back_hint':'پاسخ را بنویسید','tags':'برچسب‌ها','tags_hint':'مثلاً امتحان، زبان','delete_card':'حذف کارت؟',
    'delete_card_confirm':'این کارت برای همیشه حذف می‌شود.','image_error':'باز کردن تصویر ممکن نیست.','image_unavailable':'تصویر در دسترس نیست','again':'دوباره','hard':'سخت','good':'خوب','easy':'آسان','music_btn':'موسیقی','done':'جلسه تمام شد!',
    'great':'عالیه!','no_due':'کارتی برای مرور نیست 🎉','swipe':'برای امتیازدهی کارت را بکشید.','tap':'برای دیدن پاسخ، کارت را لمس کنید.','answer':'پاسخ','goal_done':'هدف امروز کامل شد! 🎉','ready':'آماده یک مرور کوتاه هستید؟',
    'merge':'ادغام','replace':'جایگزینی','export':'خروجی گرفتن','import':'وارد کردن','add_box':'افزودن خانه','box_name':'نام خانه','delete_box':'حذف خانه؟','delete_box_confirm':'کارت‌های این خانه به خانه اول منتقل می‌شوند.',
    'create':'ساختن','close':'بستن','focus_mode':'حالت تمرکز','focus_title':'تمرکز عمیق','focus_sub':'با زمان‌سنج بدون حواس‌پرتی متمرکز بمانید','start_focus':'شروع تمرکز','pause':'توقف','reset':'بازنشانی','focus_done':'جلسه تمرکز تمام شد!','focus_minutes':'دقیقه','focus_music':'پخش موسیقی تمرکز','select_duration':'مدت جلسه','minutes_15':'۱۵ دقیقه','minutes_25':'۲۵ دقیقه','minutes_45':'۴۵ دقیقه',
    'about':'درباره برنامه','about_creator':'ساخته‌شده توسط پرین.م (Parin.M)','about_creator_desc':'این برنامه توسط پرین.م (Parin.M) ساخته شده است.','about_ai':'ChatGPT نیز در ساخت، توسعه و بهبود آن کمک کرده است.',
    'about_github':'مخزن GitHub','about_repo_desc':'پروژه Parin Litner را در GitHub باز کنید','about_open_error':'باز کردن مخزن GitHub ممکن نشد.','about_love':'این نرم‌افزار با عشق در کره زمین ساخته شده است. 🌍❤️',
    'about_version_title':'نسخه برنامه','about_android_compat':'سازگار با اندروید ۴.۰ و بالاتر',
    'smart_mix_filter':'فیلتر ترکیب مرور هوشمند','filter_all':'همه کارت‌ها','filter_due':'موعد مرور','filter_hard':'کارت‌های سخت','filter_medium':'کارت‌های متوسط','filter_easy':'کارت‌های آسان','pc_no_cards_for_filter':'با این فیلتر کارتی پیدا نشد. فیلتر دیگری را انتخاب کنید.',
    'study_preferences':'تنظیمات مطالعه','show_xp':'نمایش XP','show_xp_sub':'مقدار XP دریافت‌شده بعد از هر مرور نمایش داده شود','confirm_exit':'تأیید قبل از خروج از مطالعه','confirm_exit_sub':'قبل از بستن جلسه فعال مطالعه تأیید بگیرید',
    'compact_settings':'تنظیمات فشرده','compact_settings_sub':'فاصله‌های کمتر در صفحه تنظیمات','achievement_center':'مرکز دستاوردها','achievement_center_sub':'نشان‌ها، چالش‌های روزانه و پیشرفت','smart_mix':'مرور هوشمند','smart_mix_sub':'مرور هوشمند و اولویت‌بندی کارت‌ها','smart_mix_available':'مرور هوشمند در Power Center در دسترس است',
  };

  static const _maps = <String, Map<String,String>>{'en':_en,'fa':_fa};
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();
  @override bool isSupported(Locale locale) => AppStrings.supportedLocales.any((x) => x.languageCode == locale.languageCode);
  @override Future<AppStrings> load(Locale locale) async => AppStrings(locale);
  @override bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}
