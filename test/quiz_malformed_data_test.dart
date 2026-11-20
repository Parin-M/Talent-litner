import 'package:flutter_test/flutter_test.dart';
import 'package:parin_litner/core/models/app_models.dart';

void main() {
  test('legacy or malformed quiz question with no options remains loadable', () {
    final question = QuizQuestion.fromJson(<String, dynamic>{
      'id': 'empty-options',
      'prompt': 'Question from an incomplete legacy backup',
      'options': <dynamic>[],
      'correctIndex': 0,
    });

    expect(question.options, isEmpty);
    expect(question.correctIndex, 0);
  });

  test('quiz question clamps an out-of-range correct answer index', () {
    final question = QuizQuestion.fromJson(<String, dynamic>{
      'id': 'invalid-index',
      'prompt': 'Question',
      'options': <String>['A', 'B'],
      'correctIndex': 9,
    });

    expect(question.correctIndex, 1);
  });
}
