import 'package:flutter_test/flutter_test.dart';
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
}
