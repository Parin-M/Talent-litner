import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

class StorageService {
  static const _key = 'parin_litner_v4_data';
  static const _quizzesKey = 'parin_litner_v1_quizzes';

  Future<List<Deck>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <Deck>[];

    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const FormatException('Saved flashcard data is damaged. Your original data has been preserved.');
    }
    if (decoded is! List) {
      throw const FormatException('Saved flashcard data has an invalid structure. Your original data has been preserved.');
    }

    try {
      return decoded.map((item) {
        if (item is! Map) throw const FormatException('A saved deck record is invalid.');
        return Deck.fromJson(Map<String, dynamic>.from(item));
      }).toList();
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('A saved deck could not be read. Your original data has been preserved.');
    }
  }

  Future<bool> hasSavedDecks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }

  Future<void> save(List<Deck> decks) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(_key, jsonEncode(decks.map((e) => e.toJson()).toList()));
    if (!saved) throw StateError('Unable to persist flashcard data.');
  }

  Future<List<QuizDefinition>> loadQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_quizzesKey);
    if (raw == null || raw.isEmpty) return <QuizDefinition>[];

    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const FormatException('Saved quiz data is damaged. Your original data has been preserved.');
    }
    if (decoded is! List) {
      throw const FormatException('Saved quiz data has an invalid structure. Your original data has been preserved.');
    }

    try {
      return decoded.map((item) {
        if (item is! Map) throw const FormatException('A saved quiz record is invalid.');
        return QuizDefinition.fromJson(Map<String, dynamic>.from(item));
      }).toList();
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('A saved quiz could not be read. Your original data has been preserved.');
    }
  }

  Future<void> saveQuizzes(List<QuizDefinition> quizzes) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(_quizzesKey, jsonEncode(quizzes.map((quiz) => quiz.toJson()).toList()));
    if (!saved) throw StateError('Unable to persist quiz data.');
  }
}
