import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/models/app_models.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/utils/helpers.dart';

class CardEditor extends StatefulWidget {
  final Deck deck;
  final FlashCard? card;
  const CardEditor({super.key, required this.deck, this.card});
  @override State<CardEditor> createState() => _CardEditorState();
}

class _CardEditorState extends State<CardEditor> {
  late final TextEditingController front = TextEditingController(text: widget.card?.front ?? '');
  late final TextEditingController back = TextEditingController(text: widget.card?.back ?? '');
  late final TextEditingController tags = TextEditingController(text: widget.card?.tags ?? '');
  late int box = widget.card?.boxIndex ?? 0;
  late String difficulty = widget.card?.difficulty ?? 'auto';
  String? frontImage;
  String? backImage;
  bool saving = false;

  String s(String key) => AppStrings.t(context, key);

  @override
  void initState() {
    super.initState();
    frontImage = _clean(widget.card?.frontImage);
    backImage = _clean(widget.card?.backImage);
    if (widget.deck.boxes.isEmpty || box < 0 || box >= widget.deck.boxes.length) box = 0;
  }

  String? _clean(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      base64Decode(value.trim());
      return value.trim();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    front.dispose();
    back.dispose();
    tags.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.first.bytes;
      if (bytes == null || bytes.isEmpty || !mounted) return;
      final encoded = base64Encode(bytes);
      setState(() => isFront ? frontImage = encoded : backImage = encoded);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s('image_error'))));
    }
  }

  Future<void> _save() async {
    if (saving) return;
    final frontOk = front.text.trim().isNotEmpty || frontImage != null;
    final backOk = back.text.trim().isNotEmpty || backImage != null;
    if (!frontOk || !backOk) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s('save_card'))));
      return;
    }
    setState(() => saving = true);
    final card = widget.card ?? FlashCard(id: uid(), front: '', back: '');
    card.front = front.text.trim();
    card.back = back.text.trim();
    card.tags = tags.text.trim();
    card.boxIndex = widget.deck.boxes.isEmpty ? 0 : box.clamp(0, widget.deck.boxes.length - 1).toInt();
    card.difficulty = difficulty;
    card.frontImage = frontImage;
    card.backImage = backImage;
    if (widget.card == null) widget.deck.cards.insert(0, card);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    if (widget.card == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s('delete_card')),
        content: Text(s('delete_card_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s('delete'))),
        ],
      ),
    );
    if (ok == true) {
      widget.deck.cards.remove(widget.card);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Widget _imageSection({required bool frontSide, required String title}) {
    final data = frontSide ? frontImage : backImage;
    final bytes = tryDecodeBase64Image(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
            if (data != null) IconButton(onPressed: () => setState(() => frontSide ? frontImage = null : backImage = null), icon: const Icon(Icons.delete_outline), tooltip: s('delete')),
            OutlinedButton.icon(onPressed: () => _pickImage(frontSide), icon: const Icon(Icons.add_photo_alternate_outlined), label: Text(data == null ? s('add_image') : s('change_image'))),
          ],
        ),
        if (bytes != null) ...[
          const SizedBox(height: 8),
          Image.memory(bytes, height: 170, width: double.infinity, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox(height: 170)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxBox = widget.deck.boxes.isEmpty ? 0 : widget.deck.boxes.length - 1;
    box = box.clamp(0, maxBox).toInt();
    return Scaffold(
      appBar: AppBar(title: Text(widget.card == null ? s('new_card') : s('edit_card')), actions: [if (widget.card != null) IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline), tooltip: s('delete'))]),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          children: [
            TextField(controller: front, maxLines: 5, decoration: InputDecoration(labelText: s('card_front'), hintText: s('front_hint'), alignLabelWithHint: true)),
            const SizedBox(height: 10),
            _imageSection(frontSide: true, title: s('front_image')),
            const Divider(height: 28),
            TextField(controller: back, maxLines: 6, decoration: InputDecoration(labelText: s('card_back'), hintText: s('back_hint'), alignLabelWithHint: true)),
            const SizedBox(height: 10),
            _imageSection(frontSide: false, title: s('back_image')),
            const Divider(height: 28),
            TextField(controller: tags, decoration: InputDecoration(labelText: s('tags'), hintText: s('tags_hint'))),
            const SizedBox(height: 12),
            if (widget.deck.boxes.isNotEmpty)
              DropdownButtonFormField<int>(
                initialValue: box,
                isExpanded: true,
                decoration: InputDecoration(labelText: s('box')),
                items: [for (var i = 0; i < widget.deck.boxes.length; i++) DropdownMenuItem(value: i, child: Text(widget.deck.boxes[i].name))],
                onChanged: (value) => setState(() => box = value ?? 0),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: difficulty,
              isExpanded: true,
              decoration: InputDecoration(labelText: s('card_difficulty')),
              items: [
                DropdownMenuItem(value: 'auto', child: Text(s('difficulty_auto'))),
                DropdownMenuItem(value: 'easy', child: Text(s('difficulty_easy'))),
                DropdownMenuItem(value: 'medium', child: Text(s('difficulty_medium'))),
                DropdownMenuItem(value: 'hard', child: Text(s('difficulty_hard'))),
              ],
              onChanged: (value) => setState(() => difficulty = value ?? 'auto'),
            ),
            const SizedBox(height: 22),
            SizedBox(height: 52, child: FilledButton.icon(onPressed: saving ? null : _save, icon: const Icon(Icons.save_outlined), label: Text(s('save_card')))),
          ],
        ),
      ),
    );
  }
}
