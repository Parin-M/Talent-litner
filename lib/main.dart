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

class _ParinLitnerAppState extends State<ParinLitnerApp> with WidgetsBindingObserver {
  final storage = StorageService();
  final backup = BackupService();
  final settings = AppSettings();
  List<Deck> decks = [];
  List<QuizDefinition> quizzes = [];
  bool loading = true;
  String? loadError;
  String _widgetLanguageCode = 'fa';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _widgetLanguageCode = settings.languageCode;
    settings.addListener(_handleSettingsChanged);
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(storage.flush());
    }
  }

  void _handleSettingsChanged() {
    if (_widgetLanguageCode == settings.languageCode) return;
    _widgetLanguageCode = settings.languageCode;
    unawaited(QuickReviewWidgetService.sync(decks: decks, languageCode: settings.languageCode));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    settings.removeListener(_handleSettingsChanged);
    settings.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() { loading = true; loadError = null; });
    try {
      await settings.load();
      final savedData = await storage.loadAll();
      final data = savedData.decks;
      final savedQuizzes = savedData.quizzes;
      final hasSavedDecks = await storage.hasSavedDecks();

      // Only seed demo content on a genuinely fresh install. An explicitly saved
      // empty deck list means the user intentionally removed all decks.
      if (data.isEmpty && !hasSavedDecks) {
        data.add(Deck(id: 'demo', name: 'شروع سریع', description: 'کارت‌های نمونه'));
        data[0].cards.addAll([
          FlashCard(id: uid(), front: 'Leitner چیست؟', back: 'یک روش مرور فاصله‌دار برای انتقال کارت‌ها بین خانه‌ها.'),
          FlashCard(id: uid(), front: 'Flutter چیست؟', back: 'فریم‌ورک ساخت رابط کاربری چندسکویی با Dart.'),
        ]);
      }
      if (!mounted) return;
      setState(() {
        decks = data;
        quizzes = savedQuizzes;
        loading = false;
        loadError = null;
      });
      unawaited(QuickReviewWidgetService.sync(decks: data, languageCode: settings.languageCode));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loadError = error.toString();
        loading = false;
      });
    }
  }

  Future<void> _save() async {
    // Child pages mutate the shared model and refresh their own route. Persist here
    // without rebuilding MaterialApp for every card edit or review rating.
    try {
      await storage.saveAll(decks, quizzes);
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
    } catch (error, stackTrace) {
      debugPrint('Backup export failed: $error\\n$stackTrace');
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
      if (mode == null || !mounted) return;

      // Build the replacement/merged state separately. Persist the complete
      // app snapshot in one write before replacing the live in-memory lists.
      final previousDecks = decks;
      final previousQuizzes = quizzes;
      final nextDecks = mode
          ? List<Deck>.from(incoming.decks)
          : <Deck>[
              ...previousDecks,
              ...incoming.decks.map((deck) => Deck(
                    id: uid(),
                    name: deck.name,
                    description: deck.description,
                    colorHex: deck.colorHex,
                    cards: List<FlashCard>.from(deck.cards),
                    boxes: List<LeitnerBox>.from(deck.boxes),
                  )),
            ];
      final nextQuizzes = mode
          ? List<QuizDefinition>.from(incoming.quizzes)
          : <QuizDefinition>[
              ...previousQuizzes,
              ...incoming.quizzes.map((quiz) => quiz.copyWith(
                    id: uid(),
                    questions: List<QuizQuestion>.from(quiz.questions),
                  )),
            ];

      try {
        await storage.normalizeImages(nextDecks, nextQuizzes);
        await storage.saveAll(nextDecks, nextQuizzes);
      } catch (_) {
        // Restore the previous atomic snapshot if persistence reports failure.
        try {
          await storage.saveAll(previousDecks, previousQuizzes);
        } catch (_) {
          // Keep the original in-memory state and surface the persistence error.
        }
        rethrow;
      }

      if (!mounted) return;
      setState(() {
        decks = nextDecks;
        quizzes = nextQuizzes;
        loadError = null;
        loading = false;
      });
      await QuickReviewWidgetService.sync(decks: decks, languageCode: settings.languageCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restored successfully.')),
        );
      }
    } on FormatException catch (error, stackTrace) {
      debugPrint('Backup import rejected: ${error.message}\\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.t(context, 'backup_invalid')} ${error.message}')),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Backup import failed: $error\\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.t(context, 'backup_error'))),
        );
      }
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
      home: loading ? const Scaffold(body: Center(child: CircularProgressIndicator())) : loadError != null ? _StorageRecoveryPage(error: loadError!, onRetry: _load, onRestoreBackup: _import) : HomePage(decks: decks, quizzes: quizzes, onChanged: _save, onImport: _import, onExport: _export, settings: settings),
    ),
  );
}


class _StorageRecoveryPage extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final Future<void> Function() onRestoreBackup;

  const _StorageRecoveryPage({required this.error, required this.onRetry, required this.onRestoreBackup});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Talent Litner')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 56, color: scheme.error),
              const SizedBox(height: 16),
              const Text(
                'Saved data could not be loaded',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your existing data has not been reset or overwritten. Restart the app or restore a backup after checking the saved file.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SelectableText(error, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 20),
              FilledButton.icon(onPressed: onRestoreBackup, icon: const Icon(Icons.settings_backup_restore), label: const Text('Restore from backup')),
              const SizedBox(height: 8),
              TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}
