import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/models/app_models.dart';
import '../../core/models/app_settings.dart';
import '../study/study_page.dart';

class PowerCenterPage extends StatefulWidget {
  final List<Deck> decks;
  final AppSettings settings;
  final VoidCallback onChanged;

  const PowerCenterPage({
    super.key,
    required this.decks,
    required this.settings,
    required this.onChanged,
  });

  @override
  State<PowerCenterPage> createState() => _PowerCenterPageState();
}

class _PowerCenterPageState extends State<PowerCenterPage> {
  int _mixSize = 20;
  String s(BuildContext context, String key) => AppStrings.t(context, key);

  List<FlashCard> _smartMix(Deck deck) {
    final now = DateTime.now();
    final cards = List<FlashCard>.from(deck.cards);

    cards.sort((a, b) {
      int score(FlashCard card) {
        var value = 0;
        if (!card.dueAt.isAfter(now)) value += 1000;
        value += card.lapses * 80;
        value += max(0, 5 - card.boxIndex) * 20;
        value += min(card.reviews, 10);
        return value;
      }

      return score(b).compareTo(score(a));
    });

    return cards.take(min(_mixSize, cards.length)).toList();
  }

  String _difficulty(FlashCard card) {
    switch (card.difficulty) {
      case 'hard': return 'Hard';
      case 'medium': return 'Medium';
      case 'easy': return 'Easy';
      default:
        if (card.lapses >= 3 || (card.reviews >= 4 && card.boxIndex <= 1)) return 'Hard';
        if (card.reviews <= 1) return 'New';
        if (card.boxIndex >= 3 && card.lapses == 0) return 'Easy';
        return 'Medium';
    }
  }

  Future<void> _startSmartMix() async {
    if (widget.decks.isEmpty) return;

    final sortedDecks = List<Deck>.from(widget.decks)
      ..sort((a, b) => b.cards.length.compareTo(a.cards.length));
    final deck = sortedDecks.first;
    final selected = _smartMix(deck);

    if (selected.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s(context, 'pc_create_cards'))),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudyPage(
          deck: deck,
          settings: widget.settings,
          onChanged: widget.onChanged,
          studyCards: selected,
        ),
      ),
    );

    if (mounted) setState(() {});
  }

  Future<void> _claimReward() async {
    final ok = await widget.settings.claimDailyReward();
    if (!mounted) return;

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? s(context, 'pc_claimed')
              : s(context, 'pc_already'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.settings,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final cards = widget.decks.expand((deck) => deck.cards).toList();
        final hard = cards.where((card) => _difficulty(card) == 'Hard').length;
        final medium =
            cards.where((card) => _difficulty(card) == 'Medium').length;
        final fresh = cards.where((card) => _difficulty(card) == 'New').length;
        final easy = cards.where((card) => _difficulty(card) == 'Easy').length;

        final today = DateTime.now();
        final last28 = List.generate(28, (index) {
          final day = DateTime(today.year, today.month, today.day).subtract(
            Duration(days: 27 - index),
          );
          final key =
              '${day.year.toString().padLeft(4, '0')}-'
              '${day.month.toString().padLeft(2, '0')}-'
              '${day.day.toString().padLeft(2, '0')}';
          return widget.settings.reviewDays.contains(key);
        });

        final reward = 50 +
            (widget.settings.streak * 5).clamp(0, 100).toInt();

        return Scaffold(
          appBar: AppBar(title: Text(s(context, 'power_center_title'))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
            children: [
              _HeroCard(
                title: s(context, 'pc_your_power'),
                levelLabel: s(context, 'pc_level'),
                streakLabel: s(context, 'pc_day_streak'),
                level: widget.settings.level,
                xp: widget.settings.xp,
                streak: widget.settings.streak,
                levelProgress: widget.settings.levelXp / 250,
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.auto_awesome,
                title: s(context, 'smart_mix'),
                subtitle: s(context, 'smart_mix_sub'),
                trailing: DropdownButton<int>(
                  value: _mixSize,
                  underline: const SizedBox.shrink(),
                  items: const [10, 20, 30]
                      .map(
                        (size) => DropdownMenuItem<int>(
                          value: size,
                          child: Text('$size'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _mixSize = value ?? 20);
                  },
                ),
                onTap: _startSmartMix,
              ),
              const SizedBox(height: 12),
              _Section(
                title: s(context, 'pc_daily_reward'),
                icon: Icons.card_giftcard_outlined,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.settings.dailyRewardAvailable
                                ? s(context, 'pc_reward_ready')
                                : s(context, 'pc_reward_tomorrow'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s(context, 'pc_up_to_xp').replaceAll('{xp}', '$reward'),
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: widget.settings.dailyRewardAvailable
                          ? _claimReward
                          : null,
                      icon: const Icon(Icons.redeem_outlined),
                      label: Text(s(context, 'pc_claim')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: s(context, 'pc_weekly_challenge'),
                icon: Icons.bolt_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      s(context, 'pc_complete_40'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: (widget.settings.weekReviews / 40)
                          .clamp(0.0, 1.0)
                          .toDouble(),
                      minHeight: 9,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${min(widget.settings.weekReviews, 40)} / 40 ${s(context, 'ac_reviews')}',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: s(context, 'pc_streak_calendar'),
                icon: Icons.calendar_month_outlined,
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final done in last28) _DayDot(done: done),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: s(context, 'pc_smart_difficulty'),
                icon: Icons.psychology_outlined,
                child: Column(
                  children: [
                    _DifficultyRow(s(context, 'hard'), hard, scheme.error),
                    _DifficultyRow(s(context, 'pc_medium'), medium, scheme.tertiary),
                    _DifficultyRow(s(context, 'pc_new'), fresh, scheme.primary),
                    _DifficultyRow(s(context, 'easy'), easy, scheme.secondary),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: s(context, 'pc_level_rewards'),
                icon: Icons.workspace_premium_outlined,
                child: Column(
                  children: [
                    _RewardRow(
                      1,
                      s(context, 'pc_started'),
                      widget.settings.level >= 1,
                    ),
                    _RewardRow(
                      3,
                      s(context, 'pc_consistent'),
                      widget.settings.level >= 3,
                    ),
                    _RewardRow(
                      5,
                      s(context, 'pc_focus_master'),
                      widget.settings.level >= 5,
                    ),
                    _RewardRow(
                      10,
                      s(context, 'pc_pro'),
                      widget.settings.level >= 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String levelLabel;
  final String streakLabel;
  final int level;
  final int xp;
  final int streak;
  final double levelProgress;

  const _HeroCard({
    required this.title,
    required this.levelLabel,
    required this.streakLabel,
    required this.level,
    required this.xp,
    required this.streak,
    required this.levelProgress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$levelLabel $level',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: levelProgress,
            minHeight: 9,
            backgroundColor: Colors.white24,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            '$xp XP  •  $streak $streakLabel',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(width: 46, height: 46, color: Theme.of(context).colorScheme.primaryContainer, alignment: Alignment.center, child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer)),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
              const SizedBox(width: 5),
              const Icon(Icons.play_circle_outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final bool done;

  const _DayDot({required this.done});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: done
            ? scheme.primary
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.zero,
      ),
      child: done ? const Icon(Icons.check, size: 16) : null,
    );
  }
}

class _DifficultyRow extends StatelessWidget {
  final String name;
  final int count;
  final Color color;

  const _DifficultyRow(this.name, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: count == 0
                  ? 0
                  : (count / (count + 12)).clamp(0.0, 1.0).toDouble(),
              minHeight: 7,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final int level;
  final String title;
  final bool done;

  const _RewardRow(this.level, this.title, this.done);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        color: Theme.of(context).colorScheme.primaryContainer,
        alignment: Alignment.center,
        child: Icon(done ? Icons.check : Icons.lock_outline, color: Theme.of(context).colorScheme.onPrimaryContainer),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      trailing: Text('${AppStrings.t(context, 'pc_level')} $level'),
    );
  }
}
