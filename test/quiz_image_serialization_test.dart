import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parin_litner/core/services/backup_service.dart';
import 'package:parin_litner/core/models/app_models.dart';
import 'package:parin_litner/core/services/image_storage_service.dart';

class _TestPlatformFile implements PlatformFile {
  _TestPlatformFile({
    required this.name,
    required this.path,
    required Uint8List bytes,
  }) : _bytes = bytes;

  @override
  final String name;

  @override
  final String? path;

  final Uint8List _bytes;

  @override
  Future<int> length() async => _bytes.length;

  @override
  Stream<Uint8List> readAsByteStream() => Stream<Uint8List>.value(_bytes);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('quiz question images survive JSON round-trip', () {
    final question = QuizQuestion(
      id: 'question-1',
      prompt: 'Identify this structure',
      options: const ['A', 'B', 'C'],
      correctIndex: 1,
      explanation: 'The image shows the correct structure.',
      promptImage: 'cXVlc3Rpb24taW1hZ2U=',
      answerImage: 'YW5zd2VyLWltYWdl',
    );

    final restored = QuizQuestion.fromJson(question.toJson());

    expect(restored.promptImage, question.promptImage);
    expect(restored.answerImage, question.answerImage);
    expect(restored.correctIndex, 1);
    expect(restored.options, question.options);
  });

  test('quiz definition keeps question images when serialized', () {
    final quiz = QuizDefinition(
      id: 'quiz-1',
      title: 'Image test',
      questions: [
        QuizQuestion(
          id: 'question-1',
          prompt: 'What is shown?',
          options: const ['One', 'Two'],
          correctIndex: 0,
          promptImage: 'cHJvbXB0',
          answerImage: 'YW5zd2Vy',
        ),
      ],
    );

    final restored = QuizDefinition.fromJson(quiz.toJson());

    expect(restored.questions.single.promptImage, 'cHJvbXB0');
    expect(restored.questions.single.answerImage, 'YW5zd2Vy');
  });

  test('portable backup round-trip preserves flashcard and quiz images', () {
    final decks = [
      Deck(
        id: 'deck-1',
        name: 'Images',
        cards: [
          FlashCard(
            id: 'card-1',
            front: 'Front',
            back: 'Back',
            frontImage: base64Encode([1, 2, 3, 4]),
            backImage: base64Encode([5, 6, 7, 8]),
          ),
        ],
      ),
    ];
    final quizzes = [
      QuizDefinition(
        id: 'quiz-1',
        title: 'Image quiz',
        questions: [
          QuizQuestion(
            id: 'question-1',
            prompt: 'Question with image',
            options: const ['A', 'B'],
            correctIndex: 1,
            explanation: 'Answer with a diagram',
            promptImage: base64Encode([9, 10, 11]),
            answerImage: base64Encode([12, 13, 14]),
          ),
        ],
      ),
    ];

    final service = BackupService();
    final bytes = service.buildBackupBytes(decks, quizzes: quizzes);
    final restored = service.decodeBackupBytes(bytes);

    expect(restored.decks.single.cards.single.frontImage, decks.single.cards.single.frontImage);
    expect(restored.decks.single.cards.single.backImage, decks.single.cards.single.backImage);
    expect(restored.quizzes.single.questions.single.promptImage, quizzes.single.questions.single.promptImage);
    expect(restored.quizzes.single.questions.single.answerImage, quizzes.single.questions.single.answerImage);
    expect(restored.quizzes.single.questions.single.correctIndex, 1);
    expect(restored.imageCount, 4);
  });

  test('backup decoder rejects truncated binary image payloads', () {
    final service = BackupService();
    final bytes = service.buildBackupBytes([
      Deck(
        id: 'deck-1',
        name: 'Deck',
        cards: [
          FlashCard(id: 'card-1', front: 'Q', back: 'A', frontImage: base64Encode([1, 2, 3])),
        ],
      ),
    ]);

    expect(
      () => service.decodeBackupBytes(Uint8List.fromList(bytes.sublist(0, bytes.length - 1))),
      throwsFormatException,
    );
  });

  test('legacy JSON backups remain importable', () {
    final deck = Deck(
      id: 'legacy-deck',
      name: 'Legacy',
      cards: [FlashCard(id: 'legacy-card', front: 'Q', back: 'A', frontImage: base64Encode([7, 8]))],
    );
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode({'decks': [deck.toJson()]})));
    final restored = BackupService().decodeBackupBytes(bytes);

    expect(restored.decks.single.name, 'Legacy');
    expect(restored.decks.single.cards.single.frontImage, deck.cards.single.frontImage);
    expect(restored.quizzes, isEmpty);
  });

  test('legacy JSON backup rejects malformed quiz records instead of skipping them', () {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode({
      'decks': <dynamic>[],
      'quizzes': <dynamic>[null],
    })));

    expect(
      () => BackupService().decodeBackupBytes(bytes),
      throwsFormatException,
    );
  });

  test('portable backup can be decoded from a chunked file stream', () async {
    final decks = [
      Deck(
        id: 'stream-deck',
        name: 'Stream backup',
        cards: [
          FlashCard(
            id: 'stream-card',
            front: 'Front',
            back: 'Back',
            frontImage: base64Encode([1, 2, 3, 4]),
          ),
        ],
      ),
    ];
    final original = BackupService().buildBackupBytes(decks);
    final chunks = <List<int>>[];
    for (var offset = 0; offset < original.length;) {
      final end = offset + 7 < original.length ? offset + 7 : original.length;
      chunks.add(original.sublist(offset, end));
      offset = end;
    }

    final restored = await BackupService().decodeBackupStream(
      Stream<List<int>>.fromIterable(chunks),
      expectedLength: original.length,
    );

    expect(restored.decks.single.name, 'Stream backup');
    expect(
      restored.decks.single.cards.single.frontImage,
      decks.single.cards.single.frontImage,
    );
  });

  test('import accepts a custom .plbackup file selected from storage', () async {
    final temp = await Directory.systemTemp.createTemp('talent-plbackup-import-');
    try {
      final sourceDeck = Deck(
        id: 'picked-deck',
        name: 'Picked backup',
        cards: [FlashCard(id: 'picked-card', front: 'Question', back: 'Answer')],
      );
      final bytes = BackupService().buildBackupBytes([sourceDeck]);
      final backupFile = File('${temp.path}/portable.PLbackup');
      await backupFile.writeAsBytes(bytes, flush: true);

      final service = BackupService(
        pickBackupFile: () async => _TestPlatformFile(
          name: 'portable.PLbackup',
          path: backupFile.path,
          bytes: bytes,
        ),
      );
      final restored = await service.importBackup();

      expect(restored, isNotNull);
      expect(restored!.decks.single.name, 'Picked backup');
      expect(restored.decks.single.cards.single.front, 'Question');
    } finally {
      await temp.delete(recursive: true);
    }
  });

  test('portable backup stream rejects truncated file reads', () async {
    final original = BackupService().buildBackupBytes(const <Deck>[]);
    final incomplete = original.sublist(0, original.length - 1);

    await expectLater(
      BackupService().decodeBackupStream(
        Stream<List<int>>.value(incomplete),
        expectedLength: original.length,
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('async backup materializes file-backed card and quiz images', () async {
    final temp = await Directory.systemTemp.createTemp('talent-backup-images-');
    try {
      final imageStore = ImageStorageService(
        directoryProvider: () async => temp,
      );
      final imageBytes = <int>[21, 22, 23, 24, 25, 26];
      final reference = await imageStore.storeBytes(imageBytes);
      final decks = [
        Deck(
          id: 'file-image-deck',
          name: 'File image deck',
          cards: [
            FlashCard(
              id: 'file-image-card',
              front: 'Question',
              back: 'Answer',
              frontImage: reference,
            ),
          ],
        ),
      ];
      final quizzes = [
        QuizDefinition(
          id: 'file-image-quiz',
          title: 'File image quiz',
          questions: [
            QuizQuestion(
              id: 'file-image-question',
              prompt: 'Prompt',
              options: const ['A', 'B'],
              correctIndex: 1,
              answerImage: reference,
            ),
          ],
        ),
      ];

      final service = BackupService(imageStore: imageStore);
      final backup = await service.buildBackupBytesAsync(decks, quizzes: quizzes);
      final restored = service.decodeBackupBytes(backup);

      expect(restored.decks.single.cards.single.frontImage, base64Encode(imageBytes));
      expect(restored.quizzes.single.questions.single.answerImage, base64Encode(imageBytes));
      expect(restored.imageCount, 2);
      expect(decks.single.cards.single.frontImage, reference);
    } finally {
      await temp.delete(recursive: true);
    }
  });
}
