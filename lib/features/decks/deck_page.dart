import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/models/app_models.dart';
import '../../core/models/app_settings.dart';
import '../../core/utils/helpers.dart';
import '../../shared/widgets/animated_glass_card.dart';
import '../cards/card_editor.dart';
import '../study/study_page.dart';

class DeckPage extends StatefulWidget {
  final Deck deck;
  final AppSettings settings;
  final VoidCallback onChanged;

  const DeckPage({
    super.key,
    required this.deck,
    required this.settings,
    required this.onChanged,
  });

  @override
  State<DeckPage> createState() => _DeckPageState();
}

class _DeckPageState extends State<DeckPage> {
  String query = '';

  String s(String key) => AppStrings.t(context, key);

  @override
  Widget build(BuildContext context) {
    final deck = widget.deck;
    final q = query.trim().toLowerCase();
    final cards = deck.cards
        .where((card) => q.isEmpty ||
            '${card.front} ${card.back} ${card.tags}'.toLowerCase().contains(q))
        .toList(growable: false);
    final now = DateTime.now();
    final due = deck.cards.where((card) => !card.dueAt.isAfter(now)).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          deck.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(onPressed: _renameDeck, icon: const Icon(Icons.edit_outlined), tooltip: s('rename')),
          IconButton(onPressed: _manageBoxes, icon: const Icon(Icons.layers_outlined), tooltip: s('boxes')),
          IconButton(onPressed: _deleteDeck, icon: const Icon(Icons.delete_outline), tooltip: s('delete')),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editCard(),
        icon: const Icon(Icons.add),
        label: Text(s('new_card')),
      ),
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) => setState(() => query = value),
                          decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: s('search'), isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(onPressed: _study, icon: const Icon(Icons.play_arrow), label: Text(s('study'))),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: Text(s('boxes'), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w300))),
                      Text('$due / ${deck.cards.length}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      IconButton(onPressed: _manageBoxes, tooltip: s('boxes'), icon: const Icon(Icons.tune)),
                    ],
                  ),
                  SizedBox(
                    height: 118,
                    child: deck.boxes.isEmpty
                        ? Center(child: Text(s('no_cards')))
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: deck.boxes.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, index) {
                              final box = deck.boxes[index];
                              final count = deck.cards.where((card) => card.boxIndex == index).length;
                              return SizedBox(
                                width: 132,
                                child: AnimatedGlassCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        color: boxColor(box),
                                        alignment: Alignment.center,
                                        child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                      ),
                                      const Spacer(),
                                      Text(box.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                                      Text('$count ${s('cards_count')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: Text(s('cards'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w300))),
                      Text('${cards.length}', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  if (query.isNotEmpty)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(onPressed: () => setState(() => query = ''), icon: const Icon(Icons.close), label: Text(s('cancel'))),
                    ),
                ],
              ),
            ),
          ),
          if (cards.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: SliverToBoxAdapter(
                child: AnimatedGlassCard(
                  child: Padding(padding: const EdgeInsets.all(18), child: Text(s('no_cards'), textAlign: TextAlign.center)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => widget.settings.animations
                      ? TweenAnimationBuilder<double>(
                          key: ValueKey(cards[index].id),
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: Duration(milliseconds: 180 + (index.clamp(0, 5) * 28).toInt()),
                          curve: Curves.easeOutCubic,
                          child: _cardTile(cards[index]),
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 12 * (1 - value)),
                              child: child,
                            ),
                          ),
                        )
                      : _cardTile(cards[index]),
                  childCount: cards.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cardTile(FlashCard card) {
    final deck = widget.deck;
    final maxBox = math.max(0, deck.boxes.length - 1);
    final boxIndex = deck.boxes.isEmpty ? 0 : card.boxIndex.clamp(0, maxBox).toInt();
    final box = deck.boxes.isEmpty ? null : deck.boxes[boxIndex];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedGlassCard(
        onTap: () => _editCard(card),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              color: box == null ? Theme.of(context).colorScheme.primary : boxColor(box),
              alignment: Alignment.center,
              child: Text('${boxIndex + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(card.front.isEmpty ? '🖼️' : card.front, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(card.back.isEmpty ? '🖼️' : card.back, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (card.tags.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(card.tags, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() => card.favorite = !card.favorite);
                widget.onChanged();
              },
              tooltip: s('favorite_only'),
              icon: Icon(card.favorite ? Icons.star : Icons.star_border, color: card.favorite ? Colors.amber : null),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameDeck() async {
    final controller = TextEditingController(text: widget.deck.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s('rename')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          onSubmitted: (value) {
            final trimmed = value.trim();
            if (trimmed.isNotEmpty) Navigator.pop(dialogContext, trimmed);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(s('cancel'))),
          FilledButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              if (trimmed.isNotEmpty) Navigator.pop(dialogContext, trimmed);
            },
            child: Text(s('save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || name == null || name.isEmpty) return;
    setState(() => widget.deck.name = name);
    widget.onChanged();
  }

  Future<void> _deleteDeck() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s('delete')),
        content: Text('${widget.deck.name}\n\n${widget.deck.cards.length} ${s('cards_count')}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(s('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(s('delete'))),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.pop(context, 'deleted');
  }

  Future<void> _editCard([FlashCard? card]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CardEditor(deck: widget.deck, card: card)),
    );
    if (result == true && mounted) {
      setState(() {});
      widget.onChanged();
    }
  }

  Future<void> _study() async {
    final now = DateTime.now();
    final due = widget.deck.cards.where((card) => !card.dueAt.isAfter(now)).toList();
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(alignment: AlignmentDirectional.centerStart, child: Text(s('study_type'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
            ),
            ListTile(leading: const Icon(Icons.bolt_outlined), title: Text(s('cards_ready')), subtitle: Text('${due.length} ${s('cards_count')}'), onTap: () => Navigator.pop(sheetContext, 'due')),
            ListTile(leading: const Icon(Icons.all_inclusive), title: Text(s('all')), subtitle: Text('${widget.deck.cards.length} ${s('cards_count')}'), onTap: () => Navigator.pop(sheetContext, 'all')),
            ListTile(leading: const Icon(Icons.star_outline), title: Text(s('favorite_only')), subtitle: Text('${widget.deck.cards.where((card) => card.favorite).length} ${s('cards_count')}'), onTap: () => Navigator.pop(sheetContext, 'favorites')),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    final pool = choice == 'all'
        ? List<FlashCard>.from(widget.deck.cards)
        : choice == 'favorites'
            ? widget.deck.cards.where((card) => card.favorite).toList()
            : due;
    if (pool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s('no_review'))));
      return;
    }

    // Difficulty is a second, optional filter. "all" keeps the selected
    // source (due, all cards, or favorites) unchanged.
    final difficulty = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(s('card_difficulty'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
            ),
            for (final option in const ['all', 'hard', 'medium', 'easy'])
              ListTile(
                leading: Icon(
                  option == 'all' ? Icons.all_inclusive
                    : option == 'hard' ? Icons.trending_down
                    : option == 'medium' ? Icons.horizontal_rule
                    : Icons.bolt_outlined,
                ),
                title: Text(option == 'all' ? s('difficulty_all')
                    : option == 'hard' ? s('hard')
                    : option == 'medium' ? s('difficulty_medium')
                    : s('easy')),
                subtitle: Text(
                  '${pool.where((card) => option == 'all' || _effectiveDifficulty(card) == option).length} ${s('cards_count')}',
                ),
                onTap: () => Navigator.pop(sheetContext, option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || difficulty == null) return;
    final selected = difficulty == 'all'
        ? pool
        : pool.where((card) => _effectiveDifficulty(card) == difficulty).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s('no_review'))));
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => StudyPage(deck: widget.deck, settings: widget.settings, studyCards: selected, onChanged: widget.onChanged)),
    );
    if (mounted) setState(() {});
  }

  String _effectiveDifficulty(FlashCard card) {
    if (const ['hard', 'medium', 'easy'].contains(card.difficulty)) {
      return card.difficulty;
    }
    if (card.lapses >= 3 || (card.reviews >= 4 && card.boxIndex <= 1)) {
      return 'hard';
    }
    if (card.boxIndex >= 3 && card.lapses == 0) return 'easy';
    // New and unclassified cards stay in the medium bucket, so all cards
    // remain discoverable even before enough review history is available.
    return 'medium';
  }

  Future<void> _manageBoxes() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BoxManager(
        deck: widget.deck,
        onChanged: () {
          setState(() {});
          widget.onChanged();
        },
      ),
    );
  }
}

class _BoxManager extends StatefulWidget {
  final Deck deck;
  final VoidCallback onChanged;

  const _BoxManager({required this.deck, required this.onChanged});

  @override
  State<_BoxManager> createState() => _BoxManagerState();
}

class _BoxManagerState extends State<_BoxManager> {
  String s(String key) => AppStrings.t(context, key);

  Future<void> _add() async {
    final controller = TextEditingController(text: '${s('box')} ${widget.deck.boxes.length + 1}');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s('add_box')),
        content: TextField(controller: controller, autofocus: true, maxLength: 80),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(s('cancel'))),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: Text(s('save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || name == null || name.isEmpty) return;
    widget.deck.boxes.add(LeitnerBox(id: uid(), name: name, colorValue: Colors.primaries[widget.deck.boxes.length % Colors.primaries.length].toARGB32()));
    setState(() {});
    widget.onChanged();
  }

  Future<void> _rename(int index) async {
    final controller = TextEditingController(text: widget.deck.boxes[index].name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s('rename')),
        content: TextField(controller: controller, autofocus: true, maxLength: 80),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(s('cancel'))),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: Text(s('save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || name == null || name.isEmpty) return;
    setState(() => widget.deck.boxes[index].name = name);
    widget.onChanged();
  }

  Future<void> _delete(int index) async {
    if (widget.deck.boxes.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s('delete_box_confirm'))));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s('delete_box')),
        content: Text(s('delete_box_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(s('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(s('delete'))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      widget.deck.boxes.removeAt(index);
      for (final card in widget.deck.cards) {
        if (card.boxIndex == index) {
          card.boxIndex = 0;
        } else if (card.boxIndex > index) {
          card.boxIndex--;
        }
      }
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final height = math.min(560.0, MediaQuery.sizeOf(context).height * .75);
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
              child: Row(
                children: [
                  Expanded(child: Text(s('boxes'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w300))),
                  IconButton(onPressed: _add, icon: const Icon(Icons.add), tooltip: s('add_box')),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: widget.deck.boxes.length,
                itemBuilder: (_, index) {
                  final box = widget.deck.boxes[index];
                  final count = widget.deck.cards.where((card) => card.boxIndex == index).length;
                  return ListTile(
                    leading: Container(width: 40, height: 40, color: boxColor(box), alignment: Alignment.center, child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                    title: Text(box.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('$count ${s('cards_count')}'),
                    trailing: Wrap(
                      spacing: 0,
                      children: [
                        IconButton(onPressed: () => _rename(index), icon: const Icon(Icons.edit_outlined), tooltip: s('rename')),
                        IconButton(onPressed: () => _delete(index), icon: const Icon(Icons.delete_outline), tooltip: s('delete')),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
