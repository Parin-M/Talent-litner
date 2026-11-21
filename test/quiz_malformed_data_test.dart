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
  test('legacy deck without Leitner boxes receives the default boxes', () {
    final deck = Deck.fromJson(<String, dynamic>{
      'id': 'legacy-deck',
      'name': 'Legacy deck',
      'cards': <dynamic>[],
    });

    expect(deck.boxes, hasLength(5));
    expect(deck.boxes.first.name, 'خانه ۱');
  });

  test('quiz decoder rejects a non-list question collection', () {
    expect(
      () => QuizDefinition.fromJson(<String, dynamic>{
        'id': 'bad-quiz',
        'title': 'Bad quiz',
        'questions': <String, dynamic>{'not': 'a list'},
      }),
      throwsFormatException,
    );
  });

  test('quiz decoder rejects malformed question records instead of dropping them', () {
    expect(
      () => QuizDefinition.fromJson(<String, dynamic>{
        'id': 'partial-quiz',
        'title': 'Partial quiz',
        'questions': <dynamic>[
          <String, dynamic>{'id': 'valid', 'prompt': 'Q', 'options': <String>['A'], 'correctIndex': 0},
          null,
        ],
      }),
      throwsFormatException,
    );
  });

  test('deck decoder clamps cards to valid box indices', () {
    final deck = Deck.fromJson(<String, dynamic>{
      'id': 'boxes-deck',
      'name': 'Box validation',
      'boxes': <dynamic>[
        <String, dynamic>{'id': 'one', 'name': 'One'},
        <String, dynamic>{'id': 'two', 'name': 'Two'},
      ],
      'cards': <dynamic>[
        <String, dynamic>{'id': 'below', 'front': 'Q1', 'back': 'A1', 'box': -4},
        <String, dynamic>{'id': 'above', 'front': 'Q2', 'back': 'A2', 'box': 9},
      ],
    });

    expect(deck.cards.map((card) => card.boxIndex), [0, 1]);
    expect(
      deck.boxes.map((box) => deck.cards.where((card) => card.boxIndex == deck.boxes.indexOf(box)).length),
      [1, 1],
    );
  });

  test('quiz question decoder rejects a non-list options field', () {
    expect(
      () => QuizQuestion.fromJson(<String, dynamic>{
        'id': 'bad-options',
        'prompt': 'Question',
        'options': <String, dynamic>{'A': 'One'},
        'correctIndex': 0,
      }),
      throwsA(isA<FormatException>()),
    );
  });

}
