import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

class StoredAppData {
  final List<Deck> decks;
  final List<QuizDefinition> quizzes;

  const StoredAppData({required this.decks, required this.quizzes});
}

class StorageService {
  // Legacy keys are kept for one-way migration from existing installations.
  static const _key = 'parin_litner_v4_data';
  static const _quizzesKey = 'parin_litner_v1_quizzes';
  static const _snapshotKey = 'talent_litner_v5_snapshot';

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

  Future<StoredAppData> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = _readSnapshot(prefs);
    if (snapshot != null) {
      // Decode the large combined payload only once at application startup.
      return StoredAppData(
        decks: _decodeDecks(snapshot['decks']),
        quizzes: _decodeQuizzes(snapshot['quizzes']),
      );
    }

    final deckRaw = prefs.getString(_key);
    final quizRaw = prefs.getString(_quizzesKey);
    return StoredAppData(
      decks: deckRaw == null || deckRaw.isEmpty
          ? <Deck>[]
          : _decodeDecks(_decodeLegacyList(
              deckRaw,
              'Saved flashcard data is damaged. Your original data has been preserved.',
            )),
      quizzes: quizRaw == null || quizRaw.isEmpty
          ? <QuizDefinition>[]
          : _decodeQuizzes(_decodeLegacyList(
              quizRaw,
              'Saved quiz data is damaged. Your original data has been preserved.',
            )),
    );
  }

  Future<List<Deck>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = _readSnapshot(prefs);
    if (snapshot != null) return _decodeDecks(snapshot['decks']);

    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <Deck>[];
    return _decodeDecks(
      _decodeLegacyList(
        raw,
        'Saved flashcard data is damaged. Your original data has been preserved.',
      ),
    );
  }

  Future<bool> hasSavedDecks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_snapshotKey) || prefs.containsKey(_key);
  }

  /// Persist flashcards and quizzes with one preference write.
  ///
  /// This prevents a normal save or backup restore from leaving one collection
  /// updated while the other still contains an older snapshot.
  Future<void> saveAll(
    List<Deck> decks,
    List<QuizDefinition> quizzes,
  ) async {
    final payload = jsonEncode(<String, dynamic>{
      'version': 1,
      'decks': decks.map((deck) => deck.toJson()).toList(),
      'quizzes': quizzes.map((quiz) => quiz.toJson()).toList(),
    });
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(_snapshotKey, payload);
    if (!saved) throw StateError('Unable to persist app data snapshot.');
  }

  // Keep the original single-collection methods source-compatible, but route
  // them through the combined snapshot so they cannot make it stale.
  Future<void> save(List<Deck> decks) async {
    final quizzes = await loadQuizzes();
    await saveAll(decks, quizzes);
  }

  Future<List<QuizDefinition>> loadQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = _readSnapshot(prefs);
    if (snapshot != null) return _decodeQuizzes(snapshot['quizzes']);

    final raw = prefs.getString(_quizzesKey);
    if (raw == null || raw.isEmpty) return <QuizDefinition>[];
    return _decodeQuizzes(
      _decodeLegacyList(
        raw,
        'Saved quiz data is damaged. Your original data has been preserved.',
      ),
    );
  }

  Future<void> saveQuizzes(List<QuizDefinition> quizzes) async {
    final decks = await load();
    await saveAll(decks, quizzes);
  }
}
