import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/models/app_models.dart';
import 'core/models/app_settings.dart';
import 'core/services/storage_service.dart';
import 'core/services/backup_service.dart';
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
  bool loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { await settings.load(); } catch (_) {}
    List<Deck> data;
    try { data = await storage.load(); } catch (_) { data = []; }
    if (data.isEmpty) {
      data = [Deck(id: 'demo', name: 'شروع سریع', description: 'کارت‌های نمونه')];
      data[0].cards.addAll([
        FlashCard(id: uid(), front: 'Leitner چیست؟', back: 'یک روش مرور فاصله‌دار برای انتقال کارت‌ها بین خانه‌ها.'),
        FlashCard(id: uid(), front: 'Flutter چیست؟', back: 'فریم‌ورک ساخت رابط کاربری چندسکویی با Dart.'),
      ]);
    }
    if (mounted) setState(() { decks = data; loading = false; });
  }

  Future<void> _save() async {
    // The deck/card objects are shared with child routes. Rebuild the root immediately
    // so changes made there are visible as soon as the route closes, without restarting.
    if (mounted) setState(() {});
    try {
      await storage.save(decks);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t(context, 'backup_error'))),
      );
    }
  }
  Future<void> _export() async {
    try {
      final saved = await backup.exportDecks(decks);
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
      final incoming = await backup.importDecks();
      if (incoming == null || !mounted) return;
      final mode = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(AppStrings.t(context, 'import')),
          content: Text('${incoming.length} ${AppStrings.t(context, 'decks')}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppStrings.t(context, 'merge'))),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(AppStrings.t(context, 'replace'))),
          ],
        ),
      );
      if (mode == null) return;
      if (mode) { decks = incoming; } else { decks.addAll(incoming.map((d) => Deck(id: uid(), name: d.name, description: d.description, colorHex: d.colorHex, cards: d.cards, boxes: d.boxes))); }
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
      title: 'Parin Litner',
      locale: settings.locale,
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [AppStrings.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      theme: AppTheme.build(settings.themeIndex, mode: settings.appearanceMode, glass: settings.glass, glassOpacity: settings.glassOpacity),
      builder: (context, child) => Directionality(textDirection: settings.language.rtl ? TextDirection.rtl : TextDirection.ltr, child: child ?? const SizedBox.shrink()),
      home: loading ? const Scaffold(body: Center(child: CircularProgressIndicator())) : HomePage(decks: decks, onChanged: _save, onImport: _import, onExport: _export, settings: settings),
    ),
  );
}
