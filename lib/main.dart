import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/models/app_models.dart';
import 'core/models/app_settings.dart';
import 'core/services/storage_service.dart';
import 'core/services/backup_service.dart';
import 'core/services/quick_review_widget_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/helpers.dart';
import 'core/i18n/app_strings.dart';
import 'features/home/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ParinLitnerApp());
}

class ParinLitnerApp extends StatefulWidget {
  const ParinLitnerApp({super.key});
  @override State<ParinLitnerApp> createState() => _ParinLitnerAppState();
}

class _ParinLitnerAppState extends State<ParinLitnerApp> {
  final storage = StorageService();
  final backup = BackupService();
  final settings = AppSettings();
  List<Deck> decks = [];
  List<QuizDefinition> quizzes = [];
  bool loading = true;
  String _widgetLanguageCode = 'fa';

  @override
  void initState() {
    super.initState();
    _widgetLanguageCode = settings.languageCode;
    settings.addListener(_handleSettingsChanged);
    _load();
  }

  void _handleSettingsChanged() {
    if (_widgetLanguageCode == settings.languageCode) return;
    _widgetLanguageCode = settings.languageCode;
    unawaited(QuickReviewWidgetService.sync(decks: decks, languageCode: settings.languageCode));
  }

  @override
  void dispose() {
    settings.removeListener(_handleSettingsChanged);
    settings.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try { await settings.load(); } catch (_) {}
    List<Deck> data;
    try { data = await storage.load(); } catch (_) { data = []; }
    List<QuizDefinition> savedQuizzes;
    try { savedQuizzes = await storage.loadQuizzes(); } catch (_) { savedQuizzes = []; }
    if (data.isEmpty) {
      data = [Deck(id: 'demo', name: 'شروع سریع', description: 'کارت‌های نمونه')];
      data[0].cards.addAll([
        FlashCard(id: uid(), front: 'Leitner چیست؟', back: 'یک روش مرور فاصله‌دار برای انتقال کارت‌ها بین خانه‌ها.'),
        FlashCard(id: uid(), front: 'Flutter چیست؟', back: 'فریم‌ورک ساخت رابط کاربری چندسکویی با Dart.'),
      ]);
    }
    if (mounted) setState(() { decks = data; quizzes = savedQuizzes; loading = false; });
    unawaited(QuickReviewWidgetService.sync(decks: data, languageCode: settings.languageCode));
  }

  Future<void> _save() async {
    // Child pages mutate the shared model and refresh their own route. Persist here
    // without rebuilding MaterialApp for every card edit or review rating.
    try {
      await storage.save(decks);
      await storage.saveQuizzes(quizzes);
      await QuickReviewWidgetService.sync(decks: decks, languageCode: settings.languageCode);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t(context, 'backup_error'))),
      );
    }
  }
  Future<void> _export() async {
    try {
      final saved = await backup.exportBackup(decks, quizzes: quizzes);
      if (!mounted) return;
      final key = saved ? 'backup_saved' : 'backup_cancelled';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.t(context, key))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.t(context, 'backup_error'))));
    }
  }

  Future<void> _import() async {
    try {
      final incoming = await backup.importBackup();
      if (incoming == null || !mounted) return;
      final stats = AppStrings.t(context, 'backup_stats')
          .replaceAll('{decks}', incoming.decks.length.toString())
          .replaceAll('{cards}', incoming.cardCount.toString())
          .replaceAll('{tests}', incoming.quizzes.length.toString())
          .replaceAll('{images}', incoming.imageCount.toString());
      final exportedAt = incoming.exportedAt == null ? '' : '\n\nExported: ${incoming.exportedAt!.toLocal()}';
      final mode = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(AppStrings.t(context, 'import')),
          content: Text('$stats$exportedAt\n\n' + AppStrings.t(context, 'backup_restore_hint')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(AppStrings.t(context, 'merge'))),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(AppStrings.t(context, 'replace'))),
          ],
        ),
      );
      if (mode == null) return;
      if (mode) {
        decks = incoming.decks;
        quizzes = incoming.quizzes;
      } else {
        decks.addAll(incoming.decks.map((d) => Deck(id: uid(), name: d.name, description: d.description, colorHex: d.colorHex, cards: d.cards, boxes: d.boxes)));
        quizzes.addAll(incoming.quizzes.map((quiz) => quiz.copyWith(id: uid())));
      }
      await _save();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.t(context, 'backup_invalid'))));
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: settings,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Talent Litner',
      locale: settings.locale,
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [AppStrings.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      theme: AppTheme.build(settings.themeIndex, mode: settings.appearanceMode, glass: settings.glass, glassOpacity: settings.glassOpacity),
      builder: (context, child) => Directionality(textDirection: settings.language.rtl ? TextDirection.rtl : TextDirection.ltr, child: child ?? const SizedBox.shrink()),
      home: loading ? const Scaffold(body: Center(child: CircularProgressIndicator())) : HomePage(decks: decks, quizzes: quizzes, onChanged: _save, onImport: _import, onExport: _export, settings: settings),
    ),
  );
}
