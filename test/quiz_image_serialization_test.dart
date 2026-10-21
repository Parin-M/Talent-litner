import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:parin_litner/core/services/backup_service.dart';
import 'package:parin_litner/core/models/app_models.dart';

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
}
