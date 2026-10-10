import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/models/app_models.dart';
import '../../core/models/app_settings.dart';
import '../../core/utils/helpers.dart';

class AchievementsPage extends StatelessWidget {
  final List<Deck> decks;
  final AppSettings settings;
  const AchievementsPage({super.key, required this.decks, required this.settings});

  String s(BuildContext c, String k) => AppStrings.t(c, k);

  @override
  Widget build(BuildContext context) {
    final cards = decks.expand((d) => d.cards).toList();
    final total = cards.length;
    final reviews = cards.fold<int>(0, (sum, c) => sum + c.reviews);
    final favorites = cards.where((c) => c.favorite).length;
    final due = decks.fold<int>(0, (sum, d) => sum + dueCount(d));
    final boxes = decks.fold<int>(0, (sum, d) => sum + d.boxes.length);
    final badgeData = <_Badge>[
      _Badge('First Steps', 'Create your first flashcard', Icons.rocket_launch_outlined, total, 1),
      _Badge('Card Builder', 'Build a collection of 25 cards', Icons.style_outlined, total, 25),
      _Badge('Reviewer', 'Complete 50 reviews', Icons.school_outlined, reviews, 50),
      _Badge('Dedicated', 'Complete 200 reviews', Icons.local_fire_department_outlined, reviews, 200),
      _Badge('Collector', 'Favorite 10 cards', Icons.star_outline, favorites, 10),
      _Badge('Deck Master', 'Create 5 learning decks', Icons.layers_outlined, decks.length, 5),
      _Badge('Box Explorer', 'Use 10 Leitner boxes', Icons.grid_view_rounded, boxes, 10),
      _Badge('Centurion', 'Reach 1000 total reviews', Icons.workspace_premium_outlined, reviews, 1000),
    ];
    final unlocked = badgeData.where((b) => b.done).length;
    final target = max(1, settings.dailyGoal);
    final challengeDone = min(due, target);
    final day = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final challenge = <String>[
      'Review $target cards today',
      'Favorite 3 cards you want to revisit',
      'Complete 10 Good ratings',
      'Create 2 new cards',
    ][day % 4];

    return Scaffold(
      appBar: AppBar(title: Text(s(context, 'extra'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _HeroCard(title: 'Achievement Center', subtitle: 'Turn every study session into progress.', value: '$unlocked/${badgeData.length}'),
          const SizedBox(height: 12),
          _SectionCard(title: "Today's Challenge", icon: Icons.bolt_outlined, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(challenge, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: challengeDone / target),
            const SizedBox(height: 8),
            Text('$challengeDone / $target', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ])),
          const SizedBox(height: 12),
          _SectionCard(title: 'Your Progress', icon: Icons.insights_outlined, child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: [
              _Metric('Cards', '$total', Icons.style_outlined),
              _Metric('Reviews', '$reviews', Icons.school_outlined),
              _Metric('Favorites', '$favorites', Icons.star_outline),
              _Metric('Due', '$due', Icons.today_outlined),
            ],
          )),
          const SizedBox(height: 12),
          _SectionCard(title: 'Badges', icon: Icons.workspace_premium_outlined, child: Column(children: [for (final badge in badgeData) _BadgeTile(badge: badge)])),
        ],
      ),
    );
  }
}

class _Badge {
  final String title;
  final String subtitle;
  final IconData icon;
  final int value;
  final int target;
  const _Badge(this.title, this.subtitle, this.icon, this.value, this.target);
  bool get done => value >= target;
  double get progress => (value / target).clamp(0.0, 1.0).toDouble();
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  const _HeroCard({required this.title, required this.subtitle, required this.value});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.zero, ),
      child: Row(children: [
        Container(width: 54, height: 54, color: Colors.white.withValues(alpha: .16), alignment: Alignment.center, child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: .9)))])),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.child});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.zero, border: Border.all(color: scheme.outlineVariant), ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: scheme.primary), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))]), const Divider(height: 20), child]),
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _Metric(this.title, this.value, this.icon);
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .55), borderRadius: BorderRadius.zero), child: Row(children: [Icon(icon), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text(title, overflow: TextOverflow.ellipsis)]))]));
}

class _BadgeTile extends StatelessWidget {
  final _Badge badge;
  const _BadgeTile({required this.badge});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withValues(alpha: .45), borderRadius: BorderRadius.zero), child: Row(children: [Container(width: 42, height: 42, color: badge.done ? scheme.primary : scheme.surface, alignment: Alignment.center, child: Icon(badge.done ? Icons.check : badge.icon, color: badge.done ? scheme.onPrimary : scheme.primary)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(badge.title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text(badge.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurfaceVariant)), const SizedBox(height: 7), LinearProgressIndicator(value: badge.progress, minHeight: 6)])), const SizedBox(width: 10), Text('${min(badge.value, badge.target)}/${badge.target}', style: const TextStyle(fontWeight: FontWeight.w800))])));
  }
}
