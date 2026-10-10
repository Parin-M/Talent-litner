import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/models/app_models.dart';
import '../../core/models/app_settings.dart';
import '../../core/utils/helpers.dart';
import '../decks/deck_page.dart';
import '../focus/focus_page.dart';
import '../power/power_center_page.dart';
import '../settings/settings_page.dart';

class HomePage extends StatelessWidget {
  final List<Deck> decks;
  final VoidCallback onChanged;
  final Future<void> Function() onImport;
  final Future<void> Function() onExport;
  final AppSettings settings;
  const HomePage({super.key, required this.decks, required this.onChanged, required this.onImport, required this.onExport, required this.settings});

  String s(BuildContext c, String k) => AppStrings.t(c, k);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = decks.fold<int>(0, (sum, d) => sum + d.cards.length);
    final due = decks.fold<int>(0, (sum, d) => sum + dueCount(d));
    final goal = settings.dailyGoal.clamp(1, 100);
    final progress = (due / goal).clamp(0.0, 1.0).toDouble();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parin Litner'),
        actions: [
          IconButton(onPressed: onImport, tooltip: s(context, 'import'), icon: const Icon(Icons.file_download_outlined)),
          IconButton(onPressed: onExport, tooltip: s(context, 'export'), icon: const Icon(Icons.file_upload_outlined)),
          IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsPage(settings: settings, onImport: onImport, onExport: onExport))), tooltip: s(context, 'settings'), icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _newDeck(context), icon: const Icon(Icons.add), label: Text(s(context, 'new_deck'))),
      body: RefreshIndicator(
        onRefresh: () async { onChanged(); },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            _GlassPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [Expanded(child: Text(due > 0 ? s(context, 'cards_ready') : s(context, 'ready'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))), Icon(due > 0 ? Icons.school_outlined : Icons.check_circle_outline, color: scheme.primary)]),
              const SizedBox(height: 14),
              LinearProgressIndicator(value: progress, minHeight: 9),
              const SizedBox(height: 8),
              Text('$due / $goal   •   $total ${s(context, 'cards_count')}', style: TextStyle(color: scheme.onSurfaceVariant)),
            ])),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: _Stat(title: s(context, 'cards'), value: '$total', icon: Icons.style_outlined)), const SizedBox(width: 10), Expanded(child: _Stat(title: s(context, 'today'), value: '$due', icon: Icons.today_outlined))]),
            const SizedBox(height: 12),
            _GlassPanel(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FocusPage(settings: settings))), child: Row(children: [
              CircleAvatar(radius: 25, backgroundColor: scheme.primaryContainer, child: Icon(Icons.self_improvement_outlined, color: scheme.onPrimaryContainer)),
              const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(s(context, 'focus_mode'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(s(context, 'focus_sub'), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurfaceVariant))])), const Icon(Icons.chevron_right),
            ])),
            const SizedBox(height: 12),
            _GlassPanel(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PowerCenterPage(decks: decks, settings: settings, onChanged: onChanged))), child: Row(children: [
              CircleAvatar(radius: 25, backgroundColor: scheme.secondaryContainer, child: Icon(Icons.auto_awesome, color: scheme.onSecondaryContainer)),
              const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [const Text('Power Center', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text('Smart Mix • XP • Streaks • Rewards', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurfaceVariant))])), const Icon(Icons.chevron_right),
            ])),
            const SizedBox(height: 20),
            Text(s(context, 'decks'), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (decks.isEmpty) _GlassPanel(child: Center(child: Text(s(context, 'no_cards')))),
            for (final deck in List<Deck>.from(decks)) Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _GlassPanel(onTap: () async {
                final result = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => DeckPage(deck: deck, settings: settings, onChanged: onChanged)));
                if (result == 'deleted') { decks.removeWhere((d) => d.id == deck.id); onChanged(); }
              }, child: Row(children: [
                CircleAvatar(radius: 26, backgroundColor: _color(deck.colorHex, scheme.primary), child: const Icon(Icons.layers_outlined, color: Colors.white)),
                const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(deck.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text('${deck.cards.length} ${s(context, 'cards_count')}  •  ${dueCount(deck)} ${s(context, 'ready_count')}', style: TextStyle(color: scheme.onSurfaceVariant))])), const Icon(Icons.chevron_left),
              ])),
            ),
          ],
        ),
      ),
    );
  }

  Color _color(String raw, Color fallback) { try { final v = raw.replaceFirst('#', '').trim(); return Color(int.parse(v.length == 6 ? 'FF$v' : v, radix: 16)); } catch (_) { return fallback; } }

  Future<void> _newDeck(BuildContext context) async {
    final c = TextEditingController();
    final name = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(title: Text(s(context, 'new_deck')), content: TextField(controller: c, autofocus: true, decoration: InputDecoration(labelText: s(context, 'new_deck_hint'))), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(s(context, 'cancel'))), FilledButton(onPressed: () => Navigator.pop(dialogContext, c.text.trim()), child: Text(s(context, 'build')))]));
    c.dispose();
    if (name == null || name.isEmpty) return;
    decks.add(Deck(id: uid(), name: name));
    onChanged();
  }
}

class _Stat extends StatelessWidget {
  final String title; final String value; final IconData icon;
  const _Stat({required this.title, required this.value, required this.icon});
  @override Widget build(BuildContext context) => _GlassPanel(child: Row(children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))]))]));
}

class _GlassPanel extends StatelessWidget {
  final Widget child; final VoidCallback? onTap;
  const _GlassPanel({required this.child, this.onTap});
  @override Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final panelSurface = scheme.surface;
    final radius = BorderRadius.circular(12);
    final panel = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panelSurface.withValues(alpha: dark ? .98 : .90),
        gradient: LinearGradient(colors: [panelSurface.withValues(alpha: dark ? .98 : .90), scheme.primary.withValues(alpha: .045)]),
        borderRadius: radius,
        border: Border.all(color: scheme.outline.withValues(alpha: .20)),
        boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: dark ? .06 : .08), blurRadius: 18, offset: const Offset(0, 5))],
      ),
      child: child,
    );
    if (onTap == null) return panel;
    return Material(color: Colors.transparent, child: InkWell(borderRadius: radius, onTap: onTap, child: panel));
  }
}
