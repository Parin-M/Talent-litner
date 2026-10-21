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
    'merge':'Merge','replace':'Replace','export':'Export','import':'Import','pdf_export':'Export PDF','pdf_export_title':'Export deck to PDF','pdf_options_hint':'Choose the layout, page format and card details to include.','pdf_layout':'Layout','pdf_layout_flashcards':'Printable flashcards','pdf_layout_worksheet':'Study worksheet','pdf_layout_quiz':'Quiz sheet with answer key','pdf_page_size':'Page size','pdf_size_a4':'A4','pdf_size_a5':'A5','pdf_size_letter':'Letter','pdf_cards_per_page':'Cards per page','pdf_landscape':'Landscape orientation','pdf_include_answers':'Include answers','pdf_include_images':'Include card images','pdf_include_tags':'Include tags','pdf_include_box':'Include Leitner box details','pdf_include_difficulty':'Include difficulty and favorite status','pdf_page_numbers':'Page numbers','pdf_sort':'Card order','pdf_sort_original':'Original order','pdf_sort_favorites':'Favorites first','pdf_sort_due':'Due date (oldest first)','pdf_only_matching':'Export only search matches','pdf_share':'Create and share PDF','pdf_print_save':'Print / Save PDF','pdf_generating':'Preparing PDF…','pdf_export_error':'Could not create the PDF. Check your internet connection and try again.','pdf_page':'Page','pdf_question':'Question','pdf_answer':'Answer','pdf_answer_key':'Answer key','pdf_image_card':'Image card','add_box':'Add box','box_name':'Box name','delete_box':'Delete box?','delete_box_confirm':'Cards in this box will move to the first box.',
    'create':'Create','close':'Close','focus_mode':'Focus Mode','focus_title':'Deep Focus','focus_sub':'Stay focused with a distraction-free timer','start_focus':'Start focus','pause':'Pause','reset':'Reset',
    'focus_done':'Focus session complete!','focus_minutes':'minutes','focus_music':'Play focus music','select_duration':'Session length','minutes_15':'15 min','minutes_25':'25 min','minutes_45':'45 min',
    'about':'About','about_creator':'Created by Parin Mashalchian','about_creator_desc':'This software was created by Parin Mashalchian.','about_ai':'ChatGPT also helped with its creation, development, and refinement.',
    'about_github':'GitHub Repository','about_repo_desc':'Open the Talent Litner project on GitHub','about_open_error':'Could not open GitHub repository.','about_love':'Made with love on planet Earth. 🌍❤️',
    'power_center_title':'Power Center','pc_create_cards':'Create some cards first.','pc_daily_reward':'Daily Reward','pc_reward_ready':'Your reward is ready!','pc_reward_tomorrow':'Come back tomorrow for another reward.','pc_up_to_xp':'Up to +{xp} XP','pc_claim':'Claim','pc_claimed':'Daily reward claimed! +XP','pc_already':'Daily reward already claimed today.','pc_weekly_challenge':'Weekly Challenge','pc_complete_40':'Complete 40 reviews this week','pc_streak_calendar':'Streak Calendar','pc_smart_difficulty':'Smart Difficulty','pc_level_rewards':'Level Rewards','pc_your_power':'Your Learning Power','pc_day_streak':'day streak','pc_level':'Level','pc_started':'Getting Started','pc_consistent':'Consistent Learner','pc_focus_master':'Focus Master','pc_pro':'Parin Pro','pc_medium':'Medium','pc_new':'New','ac_tagline':'Turn every study session into progress.','ac_challenge':'Today\'s Challenge','ac_review_daily':'Review {count} cards today','ac_favorite_three':'Favorite 3 cards you want to revisit','ac_good_ten':'Complete 10 Good ratings','ac_create_two':'Create 2 new cards','ac_progress':'Your Progress','ac_badges':'Badges','ac_first_steps':'First Steps','ac_first_steps_desc':'Create your first flashcard','ac_card_builder':'Card Builder','ac_card_builder_desc':'Build a collection of 25 cards','ac_reviewer':'Reviewer','ac_reviewer_desc':'Complete 50 reviews','ac_dedicated':'Dedicated','ac_dedicated_desc':'Complete 200 reviews','ac_collector':'Collector','ac_collector_desc':'Favorite 10 cards','ac_deck_master':'Deck Master','ac_deck_master_desc':'Create 5 learning decks','ac_box_explorer':'Box Explorer','ac_box_explorer_desc':'Use 10 Leitner boxes','ac_centurion':'Centurion','ac_centurion_desc':'Reach 1000 total reviews','ac_unlocked':'Unlocked','ac_in_progress':'In progress','auto_reveal_delay':'Reveal answer after','seconds':'seconds','focus_custom_minutes':'Custom duration (minutes)','focus_custom_range':'Enter 1–180 minutes','focus_custom_invalid':'Enter a whole number from 1 to 180.','apply':'Apply','card_difficulty':'Card difficulty','knew':'I knew this card','didnt_know':'I didn\'t know this card','zoom_image':'Zoom image',    'study_preferences':'Study preferences','show_xp':'Show XP feedback','show_xp_sub':'Display XP earned after each review','confirm_exit':'Confirm before leaving study','confirm_exit_sub':'Ask before closing an active study session',
    'compact_settings':'Compact settings','compact_settings_sub':'Use tighter spacing in Settings','achievement_center':'Achievement Center','achievement_center_sub':'Badges, daily challenges and progress',
    'smart_mix':'Smart Study Mix','smart_mix_sub':'A future-ready home for smart review modes','smart_mix_available':'Smart Study Mix is available in Power Center',
    'quick_review':"Quick review",
    'quick_review_sub':"Review cards quickly, including from the home-screen widget",
    'quick_review_empty':"There are no cards to review yet.",
    'quick_show_answer':"Reveal answer", 'quick_hide_answer':"Hide answer", 'pc_tile_subtitle':"Rewards, streaks and study progress",
    'quick_widget_hint':"To add the widget, long-press an empty area of the Android home screen.",
    'test_builder':"Test builder",
    'test_builder_sub':"Create multiple-choice tests, take them, and review your score.",
    'tests':"tests",
    'new_test':"New test",
    'edit_test':"Edit test",
    'test_title':"Test title",
    'test_title_hint':"e.g. Biology — Chapter 1",
    'test_description':"Description (optional)",
    'test_questions':"Questions",
    'test_add_question':"Add question",
    'test_question':"Question text",
    'test_question_hint':"Write a multiple-choice question",
    'test_options':"Options",'quiz_question_image':'Question image (optional)','quiz_answer_image':'Answer image (optional)','choose_image':'Choose image','remove_image':'Remove image','quiz_image_too_large':'Choose an image smaller than 12 MB.','quiz_image_pick_error':'Could not load that image.','quiz_image_invalid':'Image could not be displayed.',
    'test_option':"Option",
    'test_add_option':"Add option",
    'test_remove_option':"Remove option",
    'test_correct_answer':"Select the correct option",
    'test_explanation':"Explanation (optional)",
    'test_actions':"Test actions",
    'test_take':"Take test",
    'test_delete':"Delete test?",
    'test_delete_confirm':"This test and all of its questions will be deleted.",
    'test_no_tests':"You have not created a test yet.",
    'test_no_questions':"This test has no questions.",
    'test_need_title':"Enter a title for the test.",
    'test_need_question':"Add at least one question to the test.",
    'test_need_prompt':"Enter the question text.",
    'test_empty_option':"Fill in every option before saving.",
    'test_min_options':"Every question needs at least two options.",
    'test_max_options':"Up to 20 options are supported per question.",
    'test_previous':"Previous",
    'test_next':"Next",
    'test_finish':"Finish test",
    'test_result':"Test result",
    'test_your_answer':"Your answer",
    'test_unanswered':"Unanswered",
    'test_restart':"Try again",
    'test_backup_note':"Tests, correct answers, and explanations are included in the .plbackup file. Transfer the file to another device and import it.",
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
    'about':'درباره برنامه','about_creator':'ساخته‌شده توسط پرین مشعلچیان','about_creator_desc':'این نرم‌افزار توسط پرین مشعلچیان (Parin Mashalchian) ساخته شده است.','about_ai':'ChatGPT نیز در ساخت، توسعه و بهبود آن کمک کرده است.',
    'about_github':'مخزن GitHub','about_repo_desc':'پروژه Talent Litner را در GitHub باز کنید','about_open_error':'باز کردن مخزن GitHub ممکن نشد.','about_love':'این نرم‌افزار با عشق در کره زمین ساخته شده است. 🌍❤️',
    'power_center_title':'مرکز قدرت','pc_create_cards':'ابتدا چند کارت بسازید.','pc_daily_reward':'پاداش روزانه','pc_reward_ready':'پاداش شما آماده است!','pc_reward_tomorrow':'برای دریافت پاداش بعدی فردا برگردید.','pc_up_to_xp':'تا +{xp} XP','pc_claim':'دریافت','pc_claimed':'پاداش روزانه دریافت شد! +XP','pc_already':'پاداش امروز قبلاً دریافت شده است.','pc_weekly_challenge':'چالش هفتگی','pc_complete_40':'این هفته ۴۰ مرور انجام دهید','pc_streak_calendar':'تقویم استمرار','pc_smart_difficulty':'سطح دشواری کارت‌ها','pc_level_rewards':'پاداش سطح‌ها','pc_your_power':'قدرت یادگیری شما','pc_day_streak':'روز استمرار','pc_level':'سطح','pc_started':'شروع یادگیری','pc_consistent':'یادگیرنده پیوسته','pc_focus_master':'استاد تمرکز','pc_pro':'حرفه‌ای پارین','pc_medium':'متوسط','pc_new':'جدید','ac_tagline':'هر جلسهٔ مطالعه را به پیشرفت تبدیل کنید.','ac_challenge':'چالش امروز','ac_review_daily':'امروز {count} کارت را مرور کنید','ac_favorite_three':'۳ کارت را برای مرور دوباره محبوب کنید','ac_good_ten':'۱۰ بار گزینهٔ بلد بودم را انتخاب کنید','ac_create_two':'۲ کارت جدید بسازید','ac_progress':'پیشرفت شما','ac_badges':'نشان‌ها','ac_first_steps':'گام‌های نخست','ac_first_steps_desc':'اولین فلش‌کارت خود را بسازید','ac_card_builder':'سازندهٔ کارت','ac_card_builder_desc':'مجموعه‌ای شامل ۲۵ کارت بسازید','ac_reviewer':'مرورگر','ac_reviewer_desc':'۵۰ مرور انجام دهید','ac_dedicated':'پشتکار','ac_dedicated_desc':'۲۰۰ مرور انجام دهید','ac_collector':'کلکسیونر','ac_collector_desc':'۱۰ کارت را محبوب کنید','ac_deck_master':'استاد دسته‌ها','ac_deck_master_desc':'۵ دستهٔ یادگیری بسازید','ac_box_explorer':'کاوشگر خانه‌ها','ac_box_explorer_desc':'از ۱۰ خانهٔ لایتنر استفاده کنید','ac_centurion':'هزارمرور','ac_centurion_desc':'به ۱۰۰۰ مرور برسید','ac_unlocked':'باز شده','ac_in_progress':'در حال پیشرفت','auto_reveal_delay':'نمایش پاسخ پس از','seconds':'ثانیه','focus_custom_minutes':'مدت دلخواه (دقیقه)','focus_custom_range':'عددی بین ۱ تا ۱۸۰ وارد کنید','focus_custom_invalid':'یک عدد صحیح بین ۱ تا ۱۸۰ وارد کنید.','apply':'اعمال','card_difficulty':'سختی کارت','knew':'این کارت را بلد بودم','didnt_know':'این کارت را بلد نبودم','zoom_image':'بزرگ‌نمایی تصویر',    'study_preferences':'تنظیمات مطالعه','show_xp':'نمایش XP','show_xp_sub':'مقدار XP دریافت‌شده بعد از هر مرور نمایش داده شود','confirm_exit':'تأیید قبل از خروج از مطالعه','confirm_exit_sub':'قبل از بستن جلسه فعال مطالعه تأیید بگیرید',
    'compact_settings':'تنظیمات فشرده','compact_settings_sub':'فاصله‌های کمتر در صفحه تنظیمات','achievement_center':'مرکز دستاوردها','achievement_center_sub':'نشان‌ها، چالش‌های روزانه و پیشرفت','smart_mix':'مرور هوشمند','smart_mix_sub':'مرور هوشمند و اولویت‌بندی کارت‌ها','smart_mix_available':'مرور هوشمند در Power Center در دسترس است',
    'quick_review':"مرور سریع",
    'quick_review_sub':"مرور کوتاه کارت‌ها؛ همراه با ویجت صفحه اصلی",
    'quick_review_empty':"هنوز کارتی برای مرور ندارید.",
    'quick_show_answer':"نمایش پاسخ", 'quick_hide_answer':"پنهان کردن پاسخ", 'pc_tile_subtitle':"پاداش‌ها، استمرار و پیشرفت مطالعه",
    'quick_widget_hint':"برای افزودن ویجت، صفحه اصلی اندروید را لمس طولانی کنید.",
    'test_builder':"آزمون‌ساز",
    'test_builder_sub':"آزمون چندگزینه‌ای بسازید، اجرا کنید و نتیجه را ببینید.",
    'tests':"آزمون",
    'new_test':"آزمون جدید",
    'edit_test':"ویرایش آزمون",
    'test_title':"عنوان آزمون",
    'test_title_hint':"مثلاً زیست‌شناسی فصل اول",
    'test_description':"توضیحات (اختیاری)",
    'test_questions':"پرسش‌ها",
    'test_add_question':"افزودن پرسش",
    'test_question':"متن پرسش",
    'test_question_hint':"سؤال چندگزینه‌ای را وارد کنید",
    'test_options':"گزینه‌ها",'quiz_question_image':'تصویر سؤال (اختیاری)','quiz_answer_image':'تصویر پاسخ (اختیاری)','choose_image':'انتخاب تصویر','remove_image':'حذف تصویر','quiz_image_too_large':'تصویری کوچک‌تر از ۱۲ مگابایت انتخاب کنید.','quiz_image_pick_error':'بارگذاری تصویر ممکن نشد.','quiz_image_invalid':'نمایش تصویر ممکن نیست.',
    'test_option':"گزینه",
    'test_add_option':"افزودن گزینه",
    'test_remove_option':"حذف گزینه",
    'test_correct_answer':"گزینه صحیح را انتخاب کنید",
    'test_explanation':"توضیح پاسخ (اختیاری)",
    'test_actions':"عملیات آزمون",
    'test_take':"شروع آزمون",
    'test_delete':"حذف آزمون؟",
    'test_delete_confirm':"این آزمون و پرسش‌های آن حذف می‌شود.",
    'test_no_tests':"هنوز آزمونی نساخته‌اید.",
    'test_no_questions':"این آزمون پرسشی ندارد.",
    'test_need_title':"برای آزمون یک عنوان وارد کنید.",
    'test_need_question':"حداقل یک پرسش به آزمون اضافه کنید.",
    'test_need_prompt':"متن پرسش را وارد کنید.",
    'test_empty_option':"متن همه گزینه‌ها را کامل کنید.",
    'test_min_options':"هر پرسش باید دست‌کم دو گزینه داشته باشد.",
    'test_max_options':"حداکثر ۲۰ گزینه برای هر پرسش پشتیبانی می‌شود.",
    'test_previous':"قبلی",
    'test_next':"بعدی",
    'test_finish':"پایان آزمون",
    'test_result':"نتیجه آزمون",
    'test_your_answer':"پاسخ شما",
    'test_unanswered':"بدون پاسخ",
    'test_restart':"آزمون دوباره",
    'test_backup_note':"آزمون‌ها همراه با پاسخ صحیح و توضیحات در فایل پشتیبان .plbackup ذخیره می‌شوند؛ فایل را به دستگاه دیگر منتقل و وارد کنید.",
  };

  static const _maps = <String, Map<String,String>>{'en':_en,'fa':_fa};
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();
  @override bool isSupported(Locale locale) => AppStrings.supportedLocales.any((x) => x.languageCode == locale.languageCode);
  @override Future<AppStrings> load(Locale locale) async => AppStrings(locale);
  @override bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}
