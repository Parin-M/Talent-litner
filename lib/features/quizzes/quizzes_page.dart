import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/models/app_models.dart';
import '../../core/utils/helpers.dart';
import '../../shared/widgets/animated_glass_card.dart';

Widget? _quizImage(String? encoded, {double height = 190}) {
  if (encoded == null || encoded.isEmpty) return null;
  try {
    final bytes = base64Decode(encoded);
    if (bytes.isEmpty) return null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(bytes, height: height, width: double.infinity, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
    );
  } catch (_) {
    return null;
  }
}

class QuizzesPage extends StatefulWidget {
  final List<QuizDefinition> quizzes;
  final VoidCallback onChanged;
  const QuizzesPage({super.key, required this.quizzes, required this.onChanged});

  @override
  State<QuizzesPage> createState() => _QuizzesPageState();
}

class _QuizzesPageState extends State<QuizzesPage> {
  String s(String key) => AppStrings.t(context, key);

  Future<void> _edit([QuizDefinition? quiz]) async {
    final result = await Navigator.of(context).push<QuizDefinition>(
      MaterialPageRoute(builder: (_) => QuizEditorPage(initial: quiz)),
    );
    if (result == null || !mounted) return;
    final index = widget.quizzes.indexWhere((entry) => entry.id == result.id);
    setState(() {
      if (index < 0) {
        widget.quizzes.add(result);
      } else {
        widget.quizzes[index] = result;
      }
      widget.quizzes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
    widget.onChanged();
  }

  Future<void> _delete(QuizDefinition quiz) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s('test_delete')),
        content: Text(s('test_delete_confirm') + '\n\n' + quiz.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(s('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(s('delete'))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => widget.quizzes.removeWhere((entry) => entry.id == quiz.id));
    widget.onChanged();
  }

  Future<void> _take(QuizDefinition quiz) async {
    await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => QuizRunPage(quiz: quiz)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(s('test_builder'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: Text(s('new_test')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
        children: [
          Container(
            color: scheme.primary,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.fact_check_outlined, size: 38, color: Colors.white),
                const SizedBox(height: 10),
                Text(s('test_builder'), style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w300)),
                const SizedBox(height: 4),
                Text(s('test_builder_sub'), style: const TextStyle(color: Colors.white, height: 1.4)),
                const SizedBox(height: 12),
                Text(widget.quizzes.length.toString() + ' ' + s('tests'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (widget.quizzes.isEmpty)
            AnimatedGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.playlist_add_outlined, size: 42, color: scheme.primary),
                    const SizedBox(height: 10),
                    Text(s('test_no_tests'), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: Text(s('new_test'))),
                  ],
                ),
              ),
            )
          else
            for (final quiz in widget.quizzes) ...[
              const SizedBox(height: 8),
              AnimatedGlassCard(
                onTap: () => _take(quiz),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 48, height: 48, color: scheme.primary, alignment: Alignment.center,
                      child: const Icon(Icons.quiz_outlined, color: Colors.white, size: 25)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(quiz.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          if (quiz.description.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(quiz.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                          ],
                          const SizedBox(height: 7),
                          Text(quiz.questions.length.toString() + ' ' + s('test_questions'),
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: s('test_actions'),
                      onSelected: (value) {
                        if (value == 'edit') _edit(quiz);
                        if (value == 'delete') _delete(quiz);
                        if (value == 'take') _take(quiz);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'take', child: Text(s('test_take'))),
                        PopupMenuItem(value: 'edit', child: Text(s('edit_test'))),
                        PopupMenuItem(value: 'delete', child: Text(s('delete'))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          const SizedBox(height: 14),
          Text(s('test_backup_note'), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, height: 1.45)),
        ],
      ),
    );
  }
}

class QuizEditorPage extends StatefulWidget {
  final QuizDefinition? initial;
  const QuizEditorPage({super.key, this.initial});

  @override
  State<QuizEditorPage> createState() => _QuizEditorPageState();
}

class _QuizEditorPageState extends State<QuizEditorPage> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final List<QuizQuestion> _questions;

  String s(String key) => AppStrings.t(context, key);

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initial?.title ?? '');
    _description = TextEditingController(text: widget.initial?.description ?? '');
    _questions = widget.initial?.questions.map((question) => QuizQuestion.fromJson(question.toJson())).toList() ?? <QuizQuestion>[];
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _editQuestion([QuizQuestion? existing]) async {
    final result = await Navigator.of(context).push<QuizQuestion>(
      MaterialPageRoute(builder: (_) => QuizQuestionEditorPage(initial: existing)),
    );
    if (!mounted || result == null) return;
    setState(() {
      final index = _questions.indexWhere((question) => question.id == result.id);
      if (index < 0) {
        _questions.add(result);
      } else {
        _questions[index] = result;
      }
    });
  }

  void _save() {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s('test_need_title'))));
      return;
    }
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s('test_need_question'))));
      return;
    }
    Navigator.pop(context, QuizDefinition(
      id: widget.initial?.id ?? uid(),
      title: _title.text.trim(),
      description: _description.text.trim(),
      questions: _questions,
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.initial == null ? s('new_test') : s('edit_test'))),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: Text(s('save'))),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          TextField(controller: _title, maxLength: 100, textInputAction: TextInputAction.next,
            decoration: InputDecoration(labelText: s('test_title'), hintText: s('test_title_hint'))),
          const SizedBox(height: 10),
          TextField(controller: _description, maxLines: 2, maxLength: 300,
            decoration: InputDecoration(labelText: s('test_description'))),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: Text(s('test_questions'), style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w300))),
              Text(_questions.length.toString(), style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary)),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _questions.length; i++) ...[
            const SizedBox(height: 7),
            AnimatedGlassCard(
              onTap: () => _editQuestion(_questions[i]),
              child: Row(
                children: [
                  Container(width: 36, height: 36, color: scheme.primary, alignment: Alignment.center,
                    child: Text((i + 1).toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_questions[i].prompt, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(_questions[i].options.length.toString() + ' ' + s('test_options'), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ],
                  )),
                  IconButton(onPressed: () => _editQuestion(_questions[i]), icon: const Icon(Icons.edit_outlined), tooltip: s('edit_test')),
                  IconButton(onPressed: () => setState(() => _questions.removeAt(i)), icon: const Icon(Icons.delete_outline), tooltip: s('delete')),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => _editQuestion(), icon: const Icon(Icons.add), label: Text(s('test_add_question'))),
        ],
      ),
    );
  }
}

class QuizQuestionEditorPage extends StatefulWidget {
  final QuizQuestion? initial;
  const QuizQuestionEditorPage({super.key, this.initial});

  @override
  State<QuizQuestionEditorPage> createState() => _QuizQuestionEditorPageState();
}

class _QuizQuestionEditorPageState extends State<QuizQuestionEditorPage> {
  static const int _maxOptions = 20;
  late final TextEditingController _prompt;
  late final TextEditingController _explanation;
  late final List<TextEditingController> _options;
  int _correctIndex = 0;
  String? _promptImage;
  String? _answerImage;

  String s(String key) => AppStrings.t(context, key);

  @override
  void initState() {
    super.initState();
    _prompt = TextEditingController(text: widget.initial?.prompt ?? '');
    _explanation = TextEditingController(text: widget.initial?.explanation ?? '');
    final values = widget.initial?.options ?? const <String>[];
    _options = (values.length >= 2 ? values : const ['', '', '', ''])
        .map((value) => TextEditingController(text: value))
        .toList();
    _correctIndex = widget.initial?.correctIndex ?? 0;
    _promptImage = widget.initial?.promptImage;
    _answerImage = widget.initial?.answerImage;
  }

  @override
  void dispose() {
    _prompt.dispose();
    _explanation.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage({required bool questionImage}) async {
    try {
      final picked = await FilePicker.pickFiles(type: FileType.image, withData: true);
      if (picked == null || picked.files.isEmpty || !mounted) return;
      final bytes = picked.files.first.bytes;
      if (bytes == null || bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s('test_image_error'))));
        return;
      }
      if (bytes.length > 12 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s('test_image_too_large'))));
        return;
      }
      setState(() {
        if (questionImage) {
          _promptImage = base64Encode(bytes);
        } else {
          _answerImage = base64Encode(bytes);
        }
      });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s('test_image_error'))));
    }
  }

  Widget _imageControls({required bool questionImage}) {
    final image = questionImage ? _promptImage : _answerImage;
    final title = s(questionImage ? 'test_question_image' : 'test_answer_image');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
          OutlinedButton.icon(
            onPressed: () => _pickImage(questionImage: questionImage),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(s(image == null ? 'add_image' : 'change_image')),
          ),
          if (image != null) IconButton(
            onPressed: () => setState(() {
              if (questionImage) { _promptImage = null; } else { _answerImage = null; }
            }),
            icon: const Icon(Icons.delete_outline),
            tooltip: s('delete'),
          ),
        ]),
        if (image != null) ...[
          const SizedBox(height: 8),
          _quizImage(image, height: 180) ?? const SizedBox.shrink(),
        ],
      ],
    );
  }

  void _addOption() {
    if (_options.length >= _maxOptions) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s('test_max_options'))));
      return;
    }
    setState(() => _options.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_options.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s('test_min_options'))));
      return;
    }
    setState(() {
      _options.removeAt(index).dispose();
      if (_correctIndex == index) {
        _correctIndex = 0;
      } else if (_correctIndex > index) {
        _correctIndex--;
      }
    });
  }

  void _save() {
    if (_prompt.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s('test_need_prompt'))));
      return;
    }
    final options = _options.map((controller) => controller.text.trim()).toList();
    if (options.length < 2 || options.any((option) => option.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s('test_empty_option'))));
      return;
    }
    Navigator.pop(context, QuizQuestion(
      id: widget.initial?.id ?? uid(),
      prompt: _prompt.text.trim(),
      options: options,
      correctIndex: _correctIndex,
      explanation: _explanation.text.trim(),
      promptImage: _promptImage,
      answerImage: _answerImage,
    ));
  }

  String _marker(int index) => String.fromCharCode(65 + index);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(s('test_add_question'))),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: Text(s('save'))),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          TextField(controller: _prompt, autofocus: true, maxLength: 700, maxLines: 3,
            decoration: InputDecoration(labelText: s('test_question'), hintText: s('test_question_hint'), alignLabelWithHint: true)),
          const SizedBox(height: 8),
          _imageControls(questionImage: true),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: Text(s('test_options'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w300))),
              Text(_options.length.toString(), style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(s('test_correct_answer'), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 6),
          for (var i = 0; i < _options.length; i++) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Radio<int>(value: i, groupValue: _correctIndex, onChanged: (value) => setState(() => _correctIndex = value ?? 0)),
                  Container(width: 28, height: 36, color: i == _correctIndex ? scheme.primary : scheme.surfaceContainerHighest,
                    alignment: Alignment.center, child: Text(_marker(i), style: TextStyle(fontWeight: FontWeight.w700, color: i == _correctIndex ? Colors.white : scheme.onSurface))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(
                    controller: _options[i],
                    maxLength: 250,
                    maxLines: 2,
                    decoration: InputDecoration(counterText: '', hintText: s('test_option') + ' ' + _marker(i), isDense: true),
                  )),
                  IconButton(onPressed: () => _removeOption(i), icon: const Icon(Icons.remove_circle_outline), tooltip: s('test_remove_option')),
                ],
              ),
            ),
          ],
          OutlinedButton.icon(
            onPressed: _options.length < _maxOptions ? _addOption : null,
            icon: const Icon(Icons.add),
            label: Text(s('test_add_option')),
          ),
          const SizedBox(height: 18),
          TextField(controller: _explanation, maxLines: 3, maxLength: 500,
            decoration: InputDecoration(labelText: s('test_explanation'), alignLabelWithHint: true)),
          const SizedBox(height: 8),
          _imageControls(questionImage: false),
        ],
      ),
    );
  }
}

class QuizRunPage extends StatefulWidget {
  final QuizDefinition quiz;
  const QuizRunPage({super.key, required this.quiz});

  @override
  State<QuizRunPage> createState() => _QuizRunPageState();
}

class _QuizRunPageState extends State<QuizRunPage> {
  late final List<int?> _answers;
  int _index = 0;
  bool _showResults = false;

  String s(String key) => AppStrings.t(context, key);

  int get _score => List<int>.generate(widget.quiz.questions.length, (i) => i)
      .where((i) => _answers[i] == widget.quiz.questions[i].correctIndex)
      .length;

  @override
  void initState() {
    super.initState();
    _answers = List<int?>.filled(widget.quiz.questions.length, null);
  }

  void _restart() {
    setState(() {
      for (var i = 0; i < _answers.length; i++) {
        _answers[i] = null;
      }
      _index = 0;
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final questions = widget.quiz.questions;
    return Scaffold(
      appBar: AppBar(title: Text(widget.quiz.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: _showResults
          ? _results(scheme)
          : questions.isEmpty
              ? Center(child: Text(s('test_no_questions')))
              : _questionBody(scheme, questions),
    );
  }

  Widget _questionBody(ColorScheme scheme, List<QuizQuestion> questions) {
    final question = questions[_index];
    return Column(
      children: [
        LinearProgressIndicator(value: (_index + 1) / questions.length, minHeight: 6),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Expanded(child: Text(s('test_question'), style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700))),
              Text((_index + 1).toString() + '/' + questions.length.toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            children: [
              AnimatedGlassCard(child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(question.prompt, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.35)),
              )),
              if (_quizImage(question.promptImage) case final image?) ...[const SizedBox(height: 12), image],
              const SizedBox(height: 10),
              for (var i = 0; i < question.options.length; i++) ...[
                const SizedBox(height: 7),
                AnimatedGlassCard(
                  onTap: () => setState(() => _answers[_index] = i),
                  child: Row(
                    children: [
                      Container(width: 34, height: 34,
                        color: _answers[_index] == i ? scheme.primary : scheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Text(String.fromCharCode(65 + i), style: TextStyle(fontWeight: FontWeight.w700, color: _answers[_index] == i ? Colors.white : scheme.onSurface))),
                      const SizedBox(width: 12),
                      Expanded(child: Text(question.options[i], style: const TextStyle(fontSize: 16))),
                      if (_answers[_index] == i) Icon(Icons.check, color: scheme.primary),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: _index > 0 ? () => setState(() => _index--) : null, child: Text(s('test_previous')))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton(
                  onPressed: () => setState(() {
                    if (_index < questions.length - 1) {
                      _index++;
                    } else {
                      _showResults = true;
                    }
                  }),
                  child: Text(_index == questions.length - 1 ? s('test_finish') : s('test_next')),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _results(ColorScheme scheme) {
    final questions = widget.quiz.questions;
    final percent = questions.isEmpty ? 0 : (_score * 100 / questions.length).round();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          color: scheme.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.assessment_outlined, color: Colors.white, size: 36),
              const SizedBox(height: 8),
              Text(s('test_result'), style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w300)),
              const SizedBox(height: 5),
              Text(_score.toString() + ' / ' + questions.length.toString(), style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w300)),
              Text('$percent%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < questions.length; i++) ...[
          const SizedBox(height: 8),
          AnimatedGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_answers[i] == questions[i].correctIndex ? Icons.check_circle_outline : Icons.error_outline,
                      color: _answers[i] == questions[i].correctIndex ? const Color(0xFF16803C) : scheme.error),
                    const SizedBox(width: 8),
                    Expanded(child: Text((i + 1).toString() + '. ' + questions[i].prompt, style: const TextStyle(fontWeight: FontWeight.w700))),
                  ],
                ),
                if (_quizImage(questions[i].promptImage, height: 150) case final promptImage?) ...[const SizedBox(height: 10), promptImage],
                const SizedBox(height: 10),
                Text(s('test_your_answer') + ': ' + (_answers[i] == null
                  ? s('test_unanswered')
                  : questions[i].options[_answers[i]!.clamp(0, questions[i].options.length - 1).toInt()])),
                const SizedBox(height: 4),
                Text(s('test_correct_answer') + ': ' + questions[i].options[questions[i].correctIndex],
                  style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
                if (_quizImage(questions[i].answerImage, height: 180) case final answerImage?) ...[const SizedBox(height: 10), answerImage],
                if (questions[i].explanation.trim().isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(questions[i].explanation, style: TextStyle(color: scheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: OutlinedButton.icon(onPressed: _restart, icon: const Icon(Icons.replay), label: Text(s('test_restart')))),
            const SizedBox(width: 10),
            Expanded(child: FilledButton(onPressed: () => Navigator.pop(context), child: Text(s('close')))),
          ],
        ),
      ],
    );
  }
}
