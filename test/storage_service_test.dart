import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parin_litner/core/models/app_models.dart';
import 'package:parin_litner/core/services/storage_service.dart';
import 'package:parin_litner/core/services/image_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('distinguishes a fresh install from an intentionally empty deck list', () async {
    final storage = StorageService();

    expect(await storage.hasSavedDecks(), isFalse);

    await storage.save(const []);

    expect(await storage.hasSavedDecks(), isTrue);
    expect(await storage.load(), isEmpty);
  });
  test('does not silently replace malformed saved deck data with an empty list', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'parin_litner_v4_data': '{broken-json',
    });

    expect(
      () => StorageService().load(),
      throwsA(isA<FormatException>()),
    );
  });

  test('does not silently discard malformed saved quiz data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'parin_litner_v1_quizzes': '{"not":"a list"}',
    });

    expect(
      () => StorageService().loadQuizzes(),
      throwsA(isA<FormatException>()),
    );
  });

  test('saves decks and quizzes as one consistent snapshot', () async {
    final storage = StorageService();
    final decks = <Deck>[
      Deck(
        id: 'deck-1',
        name: 'Atomic deck',
        cards: [FlashCard(id: 'card-1', front: 'Question', back: 'Answer')],
      ),
    ];
    final quizzes = <QuizDefinition>[
      QuizDefinition(
        id: 'quiz-1',
        title: 'Atomic quiz',
        questions: [
          QuizQuestion(
            id: 'question-1',
            prompt: 'Prompt',
            options: const ['A', 'B'],
            correctIndex: 1,
          ),
        ],
      ),
    ];

    await storage.saveAll(decks, quizzes);

    expect((await storage.load()).single.name, 'Atomic deck');
    expect((await storage.loadQuizzes()).single.title, 'Atomic quiz');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('talent_litner_v5_snapshot'), isNotNull);
  });

  test('reads legacy deck and quiz keys before snapshot migration', () async {
    final deck = Deck(id: 'legacy-deck', name: 'Legacy deck');
    final quiz = QuizDefinition(id: 'legacy-quiz', title: 'Legacy quiz');
    SharedPreferences.setMockInitialValues(<String, Object>{
      'parin_litner_v4_data': jsonEncode([deck.toJson()]),
      'parin_litner_v1_quizzes': jsonEncode([quiz.toJson()]),
    });

    final storage = StorageService();
    expect((await storage.load()).single.name, 'Legacy deck');
    expect((await storage.loadQuizzes()).single.title, 'Legacy quiz');

    await storage.saveAll([deck], [quiz]);
    expect((await storage.load()).single.name, 'Legacy deck');
    expect((await storage.loadQuizzes()).single.title, 'Legacy quiz');
  });


  test('migrates legacy Base64 images to files before committing the snapshot', () async {
    final temp = await Directory.systemTemp.createTemp('talent-image-migration-');
    try {
      final imageBytes = <int>[11, 22, 33, 44, 55];
      final deck = Deck(
        id: 'legacy-image-deck',
        name: 'Legacy image deck',
        cards: [
          FlashCard(
            id: 'legacy-image-card',
            front: 'Front',
            back: 'Back',
            frontImage: base64Encode(imageBytes),
          ),
        ],
      );
      SharedPreferences.setMockInitialValues(<String, Object>{
        'parin_litner_v4_data': jsonEncode([deck.toJson()]),
      });

      final imageStore = ImageStorageService(
        directoryProvider: () async => temp,
      );
      final storage = StorageService(imageStore: imageStore);
      final loaded = await storage.loadAll();
      final reference = loaded.decks.single.cards.single.frontImage;

      expect(ImageStorageService.isStoredReference(reference), isTrue);
      expect(await imageStore.readBytes(reference), imageBytes);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('parin_litner_v4_data'), isFalse);
      final payload = prefs.getString('talent_litner_v5_snapshot')!;
      final snapshot = jsonDecode(payload) as Map<String, dynamic>;
      final savedCard = (snapshot['decks'] as List).single['cards'].single;
      expect(savedCard['frontImage'], reference);
      expect(payload.contains(base64Encode(imageBytes)), isFalse);
    } finally {
      await temp.delete(recursive: true);
    }
  });

  test('serializes rapid writes in invocation order', () async {
    final storage = StorageService();
    final older = storage.saveAll(
      [Deck(id: 'older', name: 'Older')],
      const <QuizDefinition>[],
    );
    final newer = storage.saveAll(
      [Deck(id: 'newer', name: 'Newer')],
      const <QuizDefinition>[],
    );

    await Future.wait([older, newer]);

    expect((await storage.loadAll()).decks.single.id, 'newer');
    await storage.flush();
  });


}
