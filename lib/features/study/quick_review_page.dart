import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/models/app_models.dart';
import '../../core/models/app_settings.dart';
import '../../core/utils/helpers.dart';
import '../../shared/widgets/animated_glass_card.dart';

class QuickReviewPage extends StatefulWidget {
  final List<Deck> decks;
  final AppSettings settings;
  final VoidCallback onChanged;

  const QuickReviewPage({
    super.key,
    required this.decks,
    required this.settings,
    required this.onChanged,
  });

  @override
  State<QuickReviewPage> createState() => _QuickReviewPageState();
}

class _ReviewItem {
  final Deck deck;
  final FlashCard card;
  const _ReviewItem(this.deck, this.card);
}

class _QuickReviewPageState extends State<QuickReviewPage> {
  late final List<_ReviewItem> _items;
  late final bool _isDueSession;
  Timer? _revealTimer;
  int _index = 0;
  int _reviewed = 0;
  bool _revealed = false;
  bool _finished = false;

  String s(String key) => AppStrings.t(context, key);

  @override
  void initState() {
    super.initState();
    final all = <_ReviewItem>[
      for (final deck in widget.decks)
        for (final card in deck.cards) _ReviewItem(deck, card),
    ];
    final due = all.where((item) => !item.card.dueAt.isAfter(DateTime.now())).toList();
    _isDueSession = due.isNotEmpty;
    _items = due.isNotEmpty ? due : all;
    _scheduleAutoReveal();
  }

  void _scheduleAutoReveal() {
    _revealTimer?.cancel();
    if (!widget.settings.autoReveal || _revealed || _finished || _items.isEmpty) return;
    _revealTimer = Timer(
      Duration(seconds: widget.settings.autoRevealDelaySeconds.clamp(1, 60).toInt()),
      () {
        if (mounted && !_revealed && !_finished) setState(() => _revealed = true);
      },
    );
  }

  void _showAnswer() {
    _revealTimer?.cancel();
    if (mounted && !_revealed) setState(() => _revealed = true);
  }

  void _rate(bool knew) {
    if (_items.isEmpty || _finished || !_revealed) return;
    _revealTimer?.cancel();
    final item = _items[_index];
    final card = item.card;
    final lastBox = math.max(0, item.deck.boxes.length - 1);
    final now = DateTime.now();
    card.reviews++;
    if (!knew) {
      card.lapses++;
      card.boxIndex = 0;
      card.dueAt = now.add(const Duration(minutes: 10));
    } else {
      card.boxIndex = math.min(lastBox, math.max(0, card.boxIndex + 1));
      final delays = const [1, 2, 4, 7, 14, 30];
      card.dueAt = now.add(Duration(days: delays[math.min(card.boxIndex, delays.length - 1)]));
    }
    widget.onChanged();
    unawaited(widget.settings.recordReview(knew: knew));
    _reviewed++;
    if (_index >= _items.length - 1) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _index++;
      _revealed = false;
    });
    _scheduleAutoReveal();
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(s('quick_review')),
        actions: [
          if (!_finished && _items.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Center(child: Text('${_index + 1}/${_items.length}', style: const TextStyle(fontWeight: FontWeight.w700))),
            ),
        ],
      ),
      body: SafeArea(
        child: _items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.style_outlined, size: 54, color: scheme.primary),
                      const SizedBox(height: 14),
                      Text(s('quick_review_empty'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              )
            : _finished
                ? _completion(scheme)
                : _reviewBody(scheme),
      ),
    );
  }

  Widget _reviewBody(ColorScheme scheme) {
    final item = _items[_index];
    final card = item.card;
    final text = _revealed ? card.back : card.front;
    final image = _revealed ? card.backImage : card.frontImage;
    final progress = (_index + (_revealed ? .8 : .2)) / _items.length;
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: progress.clamp(0, 1).toDouble(), minHeight: 6),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: Text(item.deck.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700))),
                Text(_isDueSession ? s('cards_ready') : s('all'), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GestureDetector(
                onTap: _showAnswer,
                child: AnimatedGlassCard(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        color: scheme.primary,
                        alignment: Alignment.center,
                        child: Icon(_revealed ? Icons.visibility_outlined : Icons.flash_on_outlined, color: Colors.white, size: 26),
                      ),
                      const SizedBox(height: 12),
                      Text(_revealed ? s('answer') : s('card_front'), style: TextStyle(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      if (image != null && image.isNotEmpty)
                        SafeMemoryImage(
                          base64: image,
                          height: constraints.maxHeight * .22,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          borderRadius: BorderRadius.zero,
                        ),
                      if (text.trim().isNotEmpty)
                        Flexible(
                          child: SingleChildScrollView(
                            child: Center(
                              child: Text(
                                text,
                                textAlign: TextAlign.center,
                                textDirection: Directionality.of(context),
                                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700, height: 1.3, color: scheme.onSurface),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      if (!_revealed) Text(s('tap'), textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                      if (card.tags.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(card.tags, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!_revealed)
              FilledButton.icon(
                onPressed: _showAnswer,
                icon: const Icon(Icons.visibility_outlined),
                label: Text(s('quick_show_answer')),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _rate(false),
                      icon: const Icon(Icons.close),
                      label: Text(s('didnt_know'), maxLines: 2, overflow: TextOverflow.ellipsis),
                      style: FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _rate(true),
                      icon: const Icon(Icons.check),
                      label: Text(s('knew'), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 7),
            Text(s('quick_widget_hint'), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _completion(ColorScheme scheme) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 68, height: 68, color: scheme.primary, alignment: Alignment.center,
                child: const Icon(Icons.check, size: 38, color: Colors.white)),
              const SizedBox(height: 18),
              Text(s('done'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('$_reviewed ${s('cards_count')}', style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 18),
              FilledButton(onPressed: () => Navigator.pop(context), child: Text(s('close'))),
            ],
          ),
        ),
      );
}
