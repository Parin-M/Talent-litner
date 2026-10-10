import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/models/app_models.dart';
import '../../core/models/app_settings.dart';
import '../../core/utils/helpers.dart';
import '../../shared/widgets/animated_glass_card.dart';
import '../decks/deck_page.dart';
import '../focus/focus_page.dart';
import '../power/power_center_page.dart';
import '../settings/settings_page.dart';

class HomePage extends StatefulWidget {
  final List<Deck> decks;
  final VoidCallback onChanged;
  final Future<void> Function() onImport;
  final Future<void> Function() onExport;
  final AppSettings settings;

  const HomePage({
    super.key,
    required this.decks,
    required this.onChanged,
    required this.onImport,
    required this.onExport,
    required this.settings,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _deckQuery = '';
  bool _sortByDue = false;

  String s(BuildContext context, String key) => AppStrings.t(context, key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final decks = widget.decks;
    final total = decks.fold<int>(0, (sum, deck) => sum + deck.cards.length);
    final due = decks.fold<int>(0, (sum, deck) => sum + dueCount(deck));
    final goal = widget.settings.dailyGoal.clamp(1, 100);
    final progress = (due / goal).clamp(0.0, 1.0).toDouble();
    final filteredDecks = decks
        .where((deck) => _deckQuery.trim().isEmpty ||
            '${deck.name} ${deck.description}'.toLowerCase().contains(_deckQuery.trim().toLowerCase()))
        .toList()
      ..sort((a, b) => _sortByDue
          ? dueCount(b).compareTo(dueCount(a))
          : a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parin Litner'),
        actions: [
          IconButton(
            onPressed: widget.onImport,
            tooltip: s(context, 'import'),
            icon: const Icon(Icons.file_download_outlined),
          ),
          IconButton(
            onPressed: widget.onExport,
            tooltip: s(context, 'export'),
            icon: const Icon(Icons.file_upload_outlined),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SettingsPage(
                settings: widget.settings,
                onImport: widget.onImport,
                onExport: widget.onExport,
                decks: decks,
              ),
            )),
            tooltip: s(context, 'settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          widget.onChanged();
          await Future<void>.delayed(const Duration(milliseconds: 1));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: scheme.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    due > 0 ? s(context, 'cards_ready') : s(context, 'ready'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$due',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 52,
                      height: 1.05,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.zero,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: scheme.onPrimary.withValues(alpha: .25),
                      color: scheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    '$due / $goal   •   $total ${s(context, 'cards_count')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onPrimary.withValues(alpha: .9)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MetroStat(
                    title: s(context, 'cards'),
                    value: '$total',
                    icon: Icons.style_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetroStat(
                    title: s(context, 'today'),
                    value: '$due',
                    icon: Icons.today_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _MetroAction(
              title: s(context, 'focus_mode'),
              subtitle: s(context, 'focus_sub'),
              icon: Icons.self_improvement_outlined,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FocusPage(settings: widget.settings),
              )),
            ),
            const SizedBox(height: 10),
            _MetroAction(
              title: 'Power Center',
              subtitle: 'Smart Mix • XP • Streaks • Rewards',
              icon: Icons.auto_awesome_outlined,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PowerCenterPage(
                  decks: decks,
                  settings: widget.settings,
                  onChanged: widget.onChanged,
                ),
              )),
            ),
            const SizedBox(height: 25),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                Text(
                  s(context, 'decks'),
                  style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w300),
                ),
                FilledButton.icon(
                  onPressed: _newDeck,
                  icon: const Icon(Icons.add),
                  label: Text(
                    s(context, 'new_deck'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (value) => setState(() => _deckQuery = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: s(context, 'search'),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<bool>(
                  value: _sortByDue,
                  isDense: true,
                  icon: const Icon(Icons.sort),
                  onChanged: (value) => setState(() => _sortByDue = value ?? false),
                  items: [
                    DropdownMenuItem(value: false, child: Text(s(context, 'decks'))),
                    DropdownMenuItem(value: true, child: Text(s(context, 'cards_ready'))),
                  ],
                ),
              ),
            ),
            if (filteredDecks.isEmpty)
              _MetroEmpty(
                message: decks.isEmpty ? s(context, 'no_cards') : s(context, 'search'),
              ),
            for (final deck in filteredDecks) ...[
              const SizedBox(height: 8),
              _MetroDeckTile(
                deck: deck,
                subtitle: '${deck.cards.length} ${s(context, 'cards_count')}  •  ${dueCount(deck)} ${s(context, 'ready_count')}',
                color: _color(deck.colorHex, scheme.primary),
                onTap: () async {
                  final result = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => DeckPage(
                        deck: deck,
                        settings: widget.settings,
                        onChanged: widget.onChanged,
                      ),
                    ),
                  );
                  if (!mounted) return;
                  if (result == 'deleted') {
                    decks.removeWhere((item) => item.id == deck.id);
                    widget.onChanged();
                    setState(() {});
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _color(String raw, Color fallback) {
    try {
      final value = raw.replaceFirst('#', '').trim();
      return Color(int.parse(value.length == 6 ? 'FF$value' : value, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _newDeck() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s(context, 'new_deck')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(labelText: s(context, 'new_deck_hint')),
          onSubmitted: (value) {
            final trimmed = value.trim();
            if (trimmed.isNotEmpty) Navigator.pop(dialogContext, trimmed);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s(context, 'cancel')),
          ),
          FilledButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              if (trimmed.isNotEmpty) Navigator.pop(dialogContext, trimmed);
            },
            child: Text(s(context, 'build')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || name == null || name.isEmpty) return;
    final deck = Deck(id: uid(), name: name);
    setState(() {
      widget.decks.add(deck);
      _deckQuery = '';
      _sortByDue = false;
    });
    widget.onChanged();
  }
}

class _MetroStat extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetroStat({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedGlassCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            color: scheme.primary,
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
                ),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetroAction extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MetroAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedGlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            color: scheme.primary,
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: scheme.primary),
        ],
      ),
    );
  }
}

class _MetroDeckTile extends StatelessWidget {
  final Deck deck;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MetroDeckTile({
    required this.deck,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedGlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            color: color,
            alignment: Alignment.center,
            child: const Icon(Icons.layers_outlined, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  deck.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                if (deck.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    deck.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, color: scheme.primary),
        ],
      ),
    );
  }
}

class _MetroEmpty extends StatelessWidget {
  final String message;
  const _MetroEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(22),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}
