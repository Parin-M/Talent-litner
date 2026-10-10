import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final bool rtl;
  const AppLanguage(this.code, this.name, this.nativeName, {this.rtl = false});
}

class AppSettings extends ChangeNotifier {
  static const languages = <AppLanguage>[
    AppLanguage('fa', 'Persian', 'فارسی', rtl: true), AppLanguage('en', 'English', 'English'), AppLanguage('de', 'German', 'Deutsch'),
    AppLanguage('de-CH', 'Swiss German', 'Deutsch (Schweiz)'), AppLanguage('de-AT', 'Austrian German', 'Deutsch (Österreich)'), AppLanguage('nl', 'Dutch', 'Nederlands'),
    AppLanguage('es', 'Spanish', 'Español'), AppLanguage('pt', 'Portuguese', 'Português'), AppLanguage('fr', 'French', 'Français'), AppLanguage('da', 'Danish', 'Dansk'),
    AppLanguage('no', 'Norwegian', 'Norsk'), AppLanguage('fi', 'Finnish', 'Suomi'), AppLanguage('sv', 'Swedish', 'Svenska'), AppLanguage('is', 'Icelandic', 'Íslenska'),
    AppLanguage('el', 'Greek', 'Ελληνικά'), AppLanguage('ar', 'Arabic', 'العربية', rtl: true), AppLanguage('he', 'Hebrew', 'עברית', rtl: true), AppLanguage('ja', 'Japanese', '日本語'),
    AppLanguage('ko', 'Korean', '한국어'), AppLanguage('it', 'Italian', 'Italiano'), AppLanguage('tr', 'Turkish', 'Türkçe'),
  ];

  static const musicTrackIds = <String>{'lofi_night', 'rainy_focus', 'deep_focus'};
  static const themeCount = 50;
  static const appearanceModes = <String>{'light', 'dark', 'aero', 'amoled'};

  int themeIndex = 0;
  String appearanceMode = 'aero';
  String languageCode = 'fa';
  bool animations = true, haptics = true, autoReveal = false, showProgress = true, showTimer = true, glass = true;
  bool showXp = true, confirmExit = true, compactSettings = false;
  double glassOpacity = .62;
  int dailyGoal = 20;
  bool musicEnabled = false;
  String musicTrack = 'lofi_night';
  double musicVolume = .35;

  int xp = 0;
  int streak = 0;
  String? lastStudyDay;
  String? lastRewardDay;
  List<String> reviewDays = [];

  AppLanguage get language => languages.firstWhere((x) => x.code == languageCode, orElse: () => languages.first);
  Locale get locale {
    final p = languageCode.split('-');
    return Locale.fromSubtags(languageCode: p.first, countryCode: p.length > 1 ? p[1] : null);
  }

  int get level => 1 + (xp ~/ 250);
  int get levelXp => xp % 250;
  bool get dailyRewardAvailable => lastRewardDay != _dayKey(DateTime.now());

  String _dayKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  int get weekReviews {
    final now = _day(DateTime.now());
    final start = now.subtract(Duration(days: now.weekday - 1));
    return reviewDays.where((key) {
      final d = DateTime.tryParse(key);
      return d != null && !_day(d).isBefore(start) && !_day(d).isAfter(now);
    }).length;
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    themeIndex = (p.getInt('theme_index') ?? 0).clamp(0, themeCount - 1).toInt();
    appearanceMode = p.getString('appearance_mode') ?? 'aero';
    if (!appearanceModes.contains(appearanceMode)) appearanceMode = 'aero';
    languageCode = p.getString('language_code') ?? 'fa';
    if (!languages.any((x) => x.code == languageCode)) languageCode = 'fa';
    animations = p.getBool('animations') ?? true;
    haptics = p.getBool('haptics') ?? true;
    autoReveal = p.getBool('auto_reveal') ?? false;
    showProgress = p.getBool('show_progress') ?? true;
    showTimer = p.getBool('show_timer') ?? true;
    glass = p.getBool('glass') ?? true;
    showXp = p.getBool('show_xp') ?? true;
    confirmExit = p.getBool('confirm_exit') ?? true;
    compactSettings = p.getBool('compact_settings') ?? false;
    glassOpacity = p.getDouble('glass_opacity') ?? .62;
    dailyGoal = p.getInt('daily_goal') ?? 20;
    musicEnabled = p.getBool('music_enabled') ?? false;
    musicTrack = p.getString('music_track') ?? 'lofi_night';
    if (!musicTrackIds.contains(musicTrack)) musicTrack = 'lofi_night';
    musicVolume = p.getDouble('music_volume') ?? .35;
    xp = maxInt(0, p.getInt('xp') ?? 0);
    streak = maxInt(0, p.getInt('streak') ?? 0);
    lastStudyDay = p.getString('last_study_day');
    lastRewardDay = p.getString('last_reward_day');
    reviewDays = p.getStringList('review_days') ?? <String>[];
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    if (!languages.any((x) => x.code == value)) return;
    languageCode = value;
    await (await SharedPreferences.getInstance()).setString('language_code', value);
    notifyListeners();
  }

  Future<void> setTheme(int value) async {
    themeIndex = value.clamp(0, themeCount - 1).toInt();
    await (await SharedPreferences.getInstance()).setInt('theme_index', themeIndex);
    notifyListeners();
  }

  Future<void> setAppearanceMode(String value) async {
    if (!appearanceModes.contains(value)) return;
    appearanceMode = value;
    await (await SharedPreferences.getInstance()).setString('appearance_mode', value);
    notifyListeners();
  }

  Future<void> setBool(String key, bool value) async {
    switch (key) {
      case 'animations': animations = value; break;
      case 'haptics': haptics = value; break;
      case 'auto_reveal': autoReveal = value; break;
      case 'show_progress': showProgress = value; break;
      case 'show_timer': showTimer = value; break;
      case 'glass': glass = value; break;
      case 'music_enabled': musicEnabled = value; break;
      case 'show_xp': showXp = value; break;
      case 'confirm_exit': confirmExit = value; break;
      case 'compact_settings': compactSettings = value; break;
    }
    await (await SharedPreferences.getInstance()).setBool(key, value);
    notifyListeners();
  }

  Future<void> setGlassOpacity(double v) async {
    glassOpacity = v.clamp(.30, .90).toDouble();
    await (await SharedPreferences.getInstance()).setDouble('glass_opacity', glassOpacity);
    notifyListeners();
  }

  Future<void> setDailyGoal(int v) async {
    dailyGoal = v.clamp(5, 100).toInt();
    await (await SharedPreferences.getInstance()).setInt('daily_goal', dailyGoal);
    notifyListeners();
  }

  Future<void> setMusicTrack(String v) async {
    if (!musicTrackIds.contains(v)) return;
    musicTrack = v;
    await (await SharedPreferences.getInstance()).setString('music_track', v);
    notifyListeners();
  }

  Future<void> setMusicVolume(double v) async {
    musicVolume = v.clamp(0, 1).toDouble();
    await (await SharedPreferences.getInstance()).setDouble('music_volume', musicVolume);
    notifyListeners();
  }

  Future<void> recordReview() async {
    final now = DateTime.now();
    final key = _dayKey(now);
    final yesterday = _dayKey(now.subtract(const Duration(days: 1)));
    xp += 12;
    if (lastStudyDay == key) {
      // Same-day reviews do not extend the streak twice.
    } else if (lastStudyDay == yesterday) {
      streak += 1;
    } else {
      streak = 1;
    }
    lastStudyDay = key;
    reviewDays = [...reviewDays, key];
    if (reviewDays.length > 300) reviewDays = reviewDays.sublist(reviewDays.length - 300);
    final p = await SharedPreferences.getInstance();
    await p.setInt('xp', xp);
    await p.setInt('streak', streak);
    await p.setString('last_study_day', key);
    await p.setStringList('review_days', reviewDays);
    notifyListeners();
  }

  Future<bool> claimDailyReward() async {
    if (!dailyRewardAvailable) return false;
    final today = _dayKey(DateTime.now());
    lastRewardDay = today;
    xp += 50 + minInt(streak * 5, 100);
    final p = await SharedPreferences.getInstance();
    await p.setString('last_reward_day', today);
    await p.setInt('xp', xp);
    notifyListeners();
    return true;
  }
}

int maxInt(int a, int b) => a > b ? a : b;
int minInt(int a, int b) => a < b ? a : b;
