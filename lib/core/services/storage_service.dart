import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import 'image_storage_service.dart';

class StoredAppData {
  final List<Deck> decks;
  final List<QuizDefinition> quizzes;

  const StoredAppData({required this.decks, required this.quizzes});
}

class StorageService {
  static const _key = 'parin_litner_v4_data';
  static const _quizzesKey = 'parin_litner_v1_quizzes';
  static const _snapshotKey = 'talent_litner_v5_snapshot';

  final ImageStorageService imageStore;
  Future<void> _writeQueue = Future<void>.value();

  StorageService({ImageStorageService? imageStore})
      : imageStore = imageStore ?? ImageStorageService();

  Map<String, dynamic>? _readSnapshot(SharedPreferences prefs) {
    final raw = prefs.getString(_snapshotKey);
    if (raw == null) return null;

    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const FormatException(
        'Saved app data snapshot is damaged. Your original data has been preserved.',
      );
    }

    if (decoded is! Map ||
        decoded['decks'] is! List ||
        decoded['quizzes'] is! List) {
      throw const FormatException(
        'Saved app data snapshot has an invalid structure. Your original data has been preserved.',
      );
    }
    return Map<String, dynamic>.from(decoded);
  }

  dynamic _decodeLegacyList(String raw, String errorMessage) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw FormatException(errorMessage);
    }
    if (decoded is! List) throw FormatException(errorMessage);
    return decoded;
  }

  List<Deck> _decodeDecks(dynamic decoded) {
    try {
      return (decoded as List).map((item) {
        if (item is! Map) {
          throw const FormatException('A saved deck record is invalid.');
        }
        return Deck.fromJson(Map<String, dynamic>.from(item));
      }).toList();
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
        'A saved deck could not be read. Your original data has been preserved.',
      );
    }
  }

  List<QuizDefinition> _decodeQuizzes(dynamic decoded) {
    try {
      return (decoded as List).map((item) {
        if (item is! Map) {
          throw const FormatException('A saved quiz record is invalid.');
        }
        return QuizDefinition.fromJson(Map<String, dynamic>.from(item));
      }).toList();
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
        'A saved quiz could not be read. Your original data has been preserved.',
      );
    }
  }

  List<Deck> _decodeLegacyDecks(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <Deck>[];
    return _decodeDecks(_decodeLegacyList(
      raw,
      'Saved flashcard data is damaged. Your original data has been preserved.',
    ));
  }

  List<QuizDefinition> _decodeLegacyQuizzes(SharedPreferences prefs) {
    final raw = prefs.getString(_quizzesKey);
    if (raw == null || raw.isEmpty) return <QuizDefinition>[];
    return _decodeQuizzes(_decodeLegacyList(
      raw,
      'Saved quiz data is damaged. Your original data has been preserved.',
    ));
  }

  Future<StoredAppData> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = _readSnapshot(prefs);
    final data = snapshot == null
        ? StoredAppData(
            decks: _decodeLegacyDecks(prefs),
            quizzes: _decodeLegacyQuizzes(prefs),
          )
        : StoredAppData(
            decks: _decodeDecks(snapshot['decks']),
            quizzes: _decodeQuizzes(snapshot['quizzes']),
          );

    // File writes finish before the compact reference snapshot is committed.
    // A migration failure leaves the old Base64 preferences recoverable.
    if (await normalizeImages(data.decks, data.quizzes)) {
      await saveAll(data.decks, data.quizzes);
    }
    return data;
  }

  Future<List<Deck>> load() async => (await loadAll()).decks;

  Future<bool> hasSavedDecks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_snapshotKey) || prefs.containsKey(_key);
  }

  Future<bool> normalizeImages(
    List<Deck> decks,
    List<QuizDefinition> quizzes,
  ) async {
    var changed = false;
    for (final deck in decks) {
      for (final card in deck.cards) {
        final front = await imageStore.storeImageData(card.frontImage);
        final back = await imageStore.storeImageData(card.backImage);
        if (front != card.frontImage) {
          card.frontImage = front;
          changed = true;
        }
        if (back != card.backImage) {
          card.backImage = back;
          changed = true;
        }
      }
    }
    for (final quiz in quizzes) {
      for (final question in quiz.questions) {
        final prompt = await imageStore.storeImageData(question.promptImage);
        final answer = await imageStore.storeImageData(question.answerImage);
        if (prompt != question.promptImage) {
          question.promptImage = prompt;
          changed = true;
        }
        if (answer != question.answerImage) {
          question.answerImage = answer;
          changed = true;
        }
      }
    }
    return changed;
  }

  /// Snapshot data is copied at invocation and queued writes commit in order.
  Future<void> saveAll(
    List<Deck> decks,
    List<QuizDefinition> quizzes,
  ) {
    final deckSnapshot = decks
        .map((deck) => Deck.fromJson(Map<String, dynamic>.from(deck.toJson())))
        .toList();
    final quizSnapshot = quizzes
        .map((quiz) =>
            QuizDefinition.fromJson(Map<String, dynamic>.from(quiz.toJson())))
        .toList();

    final operation = _writeQueue.then<void>((_) async {
      await normalizeImages(deckSnapshot, quizSnapshot);
      final payload = jsonEncode(<String, dynamic>{
        'version': 2,
        'decks': deckSnapshot.map((deck) => deck.toJson()).toList(),
        'quizzes': quizSnapshot.map((quiz) => quiz.toJson()).toList(),
      });
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString(_snapshotKey, payload);
      if (!saved) throw StateError('Unable to persist app data snapshot.');

      // Remove duplicated legacy JSON only after the new snapshot is durable.
      await prefs.remove(_key);
      await prefs.remove(_quizzesKey);
    });

    _writeQueue = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> flush() => _writeQueue;

  Future<void> save(List<Deck> decks) async {
    final current = await loadAll();
    await saveAll(decks, current.quizzes);
  }

  Future<List<QuizDefinition>> loadQuizzes() async =>
      (await loadAll()).quizzes;

  Future<void> saveQuizzes(List<QuizDefinition> quizzes) async {
    final current = await loadAll();
    await saveAll(current.decks, quizzes);
  }
}
