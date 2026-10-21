import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../core/i18n/app_strings.dart';
import '../../core/models/app_models.dart';
import '../../core/models/app_settings.dart';
import '../../core/services/pdf_export_service.dart';
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
          IconButton(onPressed: _exportPdf, icon: const Icon(Icons.picture_as_pdf_outlined), tooltip: s('pdf_export')),
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
                  (context, index) => _cardTile(cards[index]),
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

  Future<void> _exportPdf() async {
    final q = query.trim().toLowerCase();
    final matchingCount = q.isEmpty
        ? widget.deck.cards.length
        : widget.deck.cards.where((card) =>
            '${card.front} ${card.back} ${card.tags}'.toLowerCase().contains(q)).length;
    final request = await showDialog<_PdfExportRequest>(
      context: context,
      builder: (_) => _PdfExportDialog(
        hasSearch: q.isNotEmpty,
        matchingCount: matchingCount,
        totalCount: widget.deck.cards.length,
      ),
    );
    if (!mounted || request == null) return;

    final selectedCards = request.options.matchingCardsOnly && q.isNotEmpty
        ? widget.deck.cards.where((card) =>
            '${card.front} ${card.back} ${card.tags}'.toLowerCase().contains(q)).toList()
        : List<FlashCard>.from(widget.deck.cards);
    if (selectedCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s('no_cards'))),
      );
      return;
    }

    var progressDialogOpen = true;
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
            const SizedBox(width: 16),
            Expanded(child: Text(s('pdf_generating'))),
          ],
        ),
      ),
    ));

    try {
      final bytes = await CardPdfExportService.generate(
        deck: widget.deck,
        cards: selectedCards,
        options: request.options,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      progressDialogOpen = false;

      final cleanName = widget.deck.name
          .replaceAll(RegExp(r'[/:*?"<>|]+'), '-')
          .trim();
      final filename = '${cleanName.isEmpty ? 'talent-litner-cards' : cleanName}.pdf';
      if (request.printInstead) {
        await Printing.layoutPdf(
          name: filename,
          onLayout: (_) async => bytes,
        );
      } else {
        await Printing.sharePdf(bytes: bytes, filename: filename);
      }
    } catch (_) {
      if (mounted) {
        if (progressDialogOpen) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s('pdf_export_error'))),
        );
      }
    }
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
      if (card == null) await widget.settings.recordCardCreated();
      if (!mounted) return;
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
    final selected = choice == 'all'
        ? List<FlashCard>.from(widget.deck.cards)
        : choice == 'favorites'
            ? widget.deck.cards.where((card) => card.favorite).toList()
            : due;
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


class _PdfExportRequest {
  final CardPdfExportOptions options;
  final bool printInstead;

  const _PdfExportRequest({required this.options, required this.printInstead});
}

class _PdfExportDialog extends StatefulWidget {
  final bool hasSearch;
  final int matchingCount;
  final int totalCount;

  const _PdfExportDialog({
    required this.hasSearch,
    required this.matchingCount,
    required this.totalCount,
  });

  @override
  State<_PdfExportDialog> createState() => _PdfExportDialogState();
}

class _PdfExportDialogState extends State<_PdfExportDialog> {
  CardPdfLayout _layout = CardPdfLayout.flashcards;
  CardPdfPageSize _pageSize = CardPdfPageSize.a4;
  CardPdfSortOrder _sortOrder = CardPdfSortOrder.original;
  int _cardsPerPage = 2;
  bool _landscape = false;
  bool _includeAnswers = true;
  bool _includeImages = true;
  bool _includeTags = true;
  bool _includeBox = false;
  bool _includeDifficulty = false;
  bool _includePageNumbers = true;
  bool _matchingCardsOnly = false;

  String s(String key) => AppStrings.t(context, key);

  String _layoutLabel(CardPdfLayout value) => switch (value) {
    CardPdfLayout.flashcards => s('pdf_layout_flashcards'),
    CardPdfLayout.worksheet => s('pdf_layout_worksheet'),
    CardPdfLayout.quiz => s('pdf_layout_quiz'),
  };

  String _pageSizeLabel(CardPdfPageSize value) => switch (value) {
    CardPdfPageSize.a4 => s('pdf_size_a4'),
    CardPdfPageSize.a5 => s('pdf_size_a5'),
    CardPdfPageSize.letter => s('pdf_size_letter'),
  };

  String _sortLabel(CardPdfSortOrder value) => switch (value) {
    CardPdfSortOrder.original => s('pdf_sort_original'),
    CardPdfSortOrder.favoritesFirst => s('pdf_sort_favorites'),
    CardPdfSortOrder.dueFirst => s('pdf_sort_due'),
  };

  CardPdfExportOptions _options() => CardPdfExportOptions(
    layout: _layout,
    pageSize: _pageSize,
    sortOrder: _sortOrder,
    cardsPerPage: _cardsPerPage,
    landscape: _landscape,
    includeAnswers: _includeAnswers,
    includeImages: _includeImages,
    includeTags: _includeTags,
    includeBox: _includeBox,
    includeDifficulty: _includeDifficulty,
    includePageNumbers: _includePageNumbers,
    matchingCardsOnly: _matchingCardsOnly,
    questionLabel: s('pdf_question'),
    answerLabel: s('pdf_answer'),
    tagsLabel: s('tags'),
    boxLabel: s('boxes'),
    difficultyLabel: s('card_difficulty'),
    favoriteLabel: s('favorite_only'),
    imageCardLabel: s('pdf_image_card'),
    pageLabel: s('pdf_page'),
    answerKeyLabel: s('pdf_answer_key'),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(s('pdf_export_title')),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s('pdf_options_hint'), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 14),
              DropdownButtonFormField<CardPdfLayout>(
                value: _layout,
                decoration: InputDecoration(labelText: s('pdf_layout')),
                items: CardPdfLayout.values.map((value) => DropdownMenuItem(
                  value: value,
                  child: Text(_layoutLabel(value)),
                )).toList(),
                onChanged: (value) => setState(() => _layout = value ?? _layout),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<CardPdfPageSize>(
                      value: _pageSize,
                      decoration: InputDecoration(labelText: s('pdf_page_size')),
                      items: CardPdfPageSize.values.map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(_pageSizeLabel(value)),
                      )).toList(),
                      onChanged: (value) => setState(() => _pageSize = value ?? _pageSize),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _cardsPerPage,
                      decoration: InputDecoration(labelText: s('pdf_cards_per_page')),
                      items: const [1, 2, 4].map((value) => DropdownMenuItem(
                        value: value,
                        child: Text('$value'),
                      )).toList(),
                      onChanged: (value) => setState(() => _cardsPerPage = value ?? _cardsPerPage),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CardPdfSortOrder>(
                value: _sortOrder,
                decoration: InputDecoration(labelText: s('pdf_sort')),
                items: CardPdfSortOrder.values.map((value) => DropdownMenuItem(
                  value: value,
                  child: Text(_sortLabel(value)),
                )).toList(),
                onChanged: (value) => setState(() => _sortOrder = value ?? _sortOrder),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _landscape,
                title: Text(s('pdf_landscape')),
                onChanged: (value) => setState(() => _landscape = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _includeAnswers,
                title: Text(_layout == CardPdfLayout.quiz ? s('pdf_answer_key') : s('pdf_include_answers')),
                onChanged: (value) => setState(() => _includeAnswers = value ?? true),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _includeImages,
                title: Text(s('pdf_include_images')),
                onChanged: (value) => setState(() => _includeImages = value ?? true),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _includeTags,
                title: Text(s('pdf_include_tags')),
                onChanged: (value) => setState(() => _includeTags = value ?? true),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _includeBox,
                title: Text(s('pdf_include_box')),
                onChanged: (value) => setState(() => _includeBox = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _includeDifficulty,
                title: Text(s('pdf_include_difficulty')),
                onChanged: (value) => setState(() => _includeDifficulty = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _includePageNumbers,
                title: Text(s('pdf_page_numbers')),
                onChanged: (value) => setState(() => _includePageNumbers = value ?? true),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (widget.hasSearch)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _matchingCardsOnly,
                  title: Text('${s('pdf_only_matching')} (${widget.matchingCount}/${widget.totalCount})'),
                  onChanged: (value) => setState(() => _matchingCardsOnly = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s('cancel')),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context, _PdfExportRequest(options: _options(), printInstead: true)),
          icon: const Icon(Icons.print_outlined),
          label: Text(s('pdf_print_save')),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, _PdfExportRequest(options: _options(), printInstead: false)),
          icon: const Icon(Icons.share_outlined),
          label: Text(s('pdf_share')),
        ),
      ],
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
