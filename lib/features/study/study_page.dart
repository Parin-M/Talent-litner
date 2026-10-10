import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/models/app_models.dart';
import '../../core/models/app_settings.dart';
import '../../core/services/music_service.dart';
import '../../core/utils/helpers.dart';

class StudyPage extends StatefulWidget {
  final Deck deck;
  final AppSettings settings;
  final VoidCallback onChanged;
  final List<FlashCard>? studyCards;
  const StudyPage({super.key, required this.deck, required this.settings, required this.onChanged, this.studyCards});
  @override State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> with SingleTickerProviderStateMixin {
  late final List<FlashCard> cards;
  late final AnimationController flip;
  Timer? timer;
  Timer? autoRevealTimer;
  int index = 0;
  int seconds = 0;
  bool revealed = false;
  bool musicPlaying = false;
  bool finished = false;
  String s(String key) => AppStrings.t(context, key);

  @override
  void initState() {
    super.initState();
    cards = List<FlashCard>.from(widget.studyCards ?? widget.deck.cards.where((c) => !c.dueAt.isAfter(DateTime.now())))..shuffle();
    flip = AnimationController(vsync: this, duration: Duration(milliseconds: widget.settings.animations ? 400 : 1));
    if (widget.settings.showTimer) timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted && !finished) setState(() => seconds++); });
    if (cards.isNotEmpty && widget.settings.musicEnabled) _playMusic();
    _scheduleAutoReveal();
  }

  Future<void> _playMusic() async { try { await MusicService.instance.play(widget.settings.musicTrack, volume: widget.settings.musicVolume); if (mounted) setState(() => musicPlaying = true); } catch (_) {} }

  void _scheduleAutoReveal() {
    autoRevealTimer?.cancel();
    if (!widget.settings.autoReveal || cards.isEmpty || revealed || finished) return;
    autoRevealTimer = Timer(
      Duration(seconds: widget.settings.autoRevealDelaySeconds.clamp(1, 30).toInt()),
      () {
        if (mounted && !finished && !revealed) _toggleReveal();
      },
    );
  }

  Future<void> _buzz({bool heavy = false}) async {
    if (!widget.settings.haptics) return;
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: heavy ? 100 : 35);
        return;
      }
    } catch (_) {}
    try {
      if (heavy) {
        await HapticFeedback.heavyImpact();
      } else {
        await HapticFeedback.vibrate();
      }
    } catch (_) {}
  }

  void _toggleReveal() {
    if (finished || cards.isEmpty) return;
    autoRevealTimer?.cancel();
    setState(() => revealed = !revealed);
    if (revealed) {
      flip.forward();
    } else {
      flip.reverse();
      _scheduleAutoReveal();
    }
    unawaited(_buzz());
  }

  void _rate(int rating) {
    if (finished || cards.isEmpty || !revealed) return;
    final card = cards[index];
    final lastBox = max(0, widget.deck.boxes.length - 1);
    final now = DateTime.now();
    card.reviews++;
    if (rating == 0) { card.lapses++; card.boxIndex = 0; card.dueAt = now.add(const Duration(minutes: 10)); }
    else if (rating == 1) { card.boxIndex = card.boxIndex.clamp(0, lastBox).toInt(); card.dueAt = now.add(const Duration(days: 1)); }
    else if (rating == 2) { card.boxIndex = min(lastBox, max(0, card.boxIndex + 1)); card.dueAt = now.add(Duration(days: [1, 2, 4, 7, 14, 30][min(card.boxIndex, 5)])); }
    else { card.boxIndex = min(lastBox, max(0, card.boxIndex + 2)); card.dueAt = now.add(Duration(days: [2, 4, 7, 14, 30, 60][min(card.boxIndex, 5)])); }
    widget.onChanged();
    widget.settings.recordReview(knew: rating == 2);
    unawaited(_buzz());
    if (widget.settings.showXp && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('+12 XP'), duration: Duration(milliseconds: 650)));
    if (index == cards.length - 1) { finished = true; unawaited(_buzz(heavy: true)); _finish(); return; }
    setState(() { index++; revealed = false; });
    flip.reset();
    _scheduleAutoReveal();
  }

  void _swipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (!revealed || finished) return;
    if (velocity > 450) { _rate(2); } else if (velocity < -450) { _rate(0); }
  }

  Future<void> _finish() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    await showDialog<void>(context: context, builder: (context) => AlertDialog(title: Text(s('done')), content: Text('${cards.length} ${s('cards_count')}\n${_time()}'), actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(s('great')))]));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _back() async {
    if (finished || !widget.settings.confirmExit) { if (mounted) Navigator.pop(context); return; }
    final leave = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text(s('confirm_exit')), content: Text(s('confirm_exit_sub')), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(s('cancel'))), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(s('close')))]));
    if (leave == true && mounted) Navigator.pop(context);
  }

  String _time() => '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() { timer?.cancel(); autoRevealTimer?.cancel(); flip.dispose(); if (musicPlaying) MusicService.instance.stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return Scaffold(appBar: AppBar(title: Text(s('study'))), body: Center(child: Padding(padding: const EdgeInsets.all(28), child: Text(s('no_due'), textAlign: TextAlign.center))));
    final card = cards[index];
    final progress = ((index + (revealed ? .9 : .1)) / cards.length).clamp(0.0, 1.0).toDouble();
    return PopScope(canPop: !widget.settings.confirmExit || finished, onPopInvokedWithResult: (didPop, result) { if (!didPop && widget.settings.confirmExit && !finished) _back(); }, child: Scaffold(
      appBar: AppBar(leading: IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back)), title: Text('${index + 1} / ${cards.length}'), actions: [if (widget.settings.showTimer) Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Center(child: Text(_time(), style: const TextStyle(fontWeight: FontWeight.w700)))), if (widget.settings.musicEnabled) IconButton(onPressed: () async { if (musicPlaying) { await MusicService.instance.pause(); if (mounted) setState(() => musicPlaying = false); } else { await _playMusic(); } }, icon: Icon(musicPlaying ? Icons.music_note : Icons.music_off), tooltip: s('music_btn'))]),
      body: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 18), child: Column(children: [
        if (widget.settings.showProgress) ...[LinearProgressIndicator(value: progress, minHeight: 7), const SizedBox(height: 14)],
        Expanded(child: GestureDetector(onTap: _toggleReveal, onHorizontalDragEnd: _swipe, child: AnimatedBuilder(animation: flip, builder: (context, child) { final angle = flip.value * pi; final front = angle <= pi / 2; final face = _CardFace(text: front ? card.front : card.back, image: front ? card.frontImage : card.backImage, label: front ? s('tap') : s('answer')); final visible = front ? face : Transform(alignment: Alignment.center, transform: Matrix4.rotationY(pi), child: face); return Transform(alignment: Alignment.center, transform: Matrix4.identity()..setEntry(3,2,.0012)..rotateY(angle), child: visible); }))),
        const SizedBox(height: 12),
        if (revealed) Row(
          children: [
            Expanded(
              child: _Rate(
                label: s('didnt_know'),
                icon: Icons.close,
                color: Theme.of(context).colorScheme.error,
                onTap: () => _rate(0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Rate(
                label: s('knew'),
                icon: Icons.check,
                color: const Color(0xFF2E7D32),
                onTap: () => _rate(2),
              ),
            ),
          ],
        ),
        Padding(padding: const EdgeInsets.only(top:6), child: Text(revealed ? s('swipe') : s('tap'), textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
      ]))),
    ));
  }
}

class _CardFace extends StatelessWidget {
  final String text;
  final String? image;
  final String label;

  const _CardFace({required this.text, required this.image, required this.label});

  Future<void> _zoom(BuildContext context) async {
    if (image == null || image!.isEmpty) return;
    final size = MediaQuery.sizeOf(context);
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        backgroundColor: Colors.black,
        child: SizedBox(
          width: size.width,
          height: size.height * .82,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 6,
                  boundaryMargin: const EdgeInsets.all(40),
                  child: Center(
                    child: SafeMemoryImage(
                      base64: image,
                      fit: BoxFit.contain,
                      width: size.width,
                      height: size.height * .82,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: AppStrings.t(context, 'close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.style_outlined, size: 42),
                const SizedBox(height: 10),
                SafeMemoryImage(
                  base64: image,
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.zero,
                ),
                if (image != null && image!.isNotEmpty)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: () => _zoom(context),
                      icon: const Icon(Icons.zoom_in),
                      label: Text(AppStrings.t(context, 'zoom_image')),
                    ),
                  ),
                if (text.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    textDirection: Directionality.of(context),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.35),
                  ),
                ],
                const SizedBox(height: 16),
                Text(label, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Rate extends StatelessWidget {
  final String label; final IconData icon; final VoidCallback onTap;
  const _Rate({required this.label, required this.icon, required this.onTap});
  @override Widget build(BuildContext context) => OutlinedButton(onPressed:onTap, child:Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(icon),Text(label,maxLines:1,overflow:TextOverflow.ellipsis)])));
}
