import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

class StorageService {
  static const _key = 'parin_litner_v4_data';
  static const _quizzesKey = 'parin_litner_v1_quizzes';

  Future<List<Deck>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Deck.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<Deck> decks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(decks.map((e) => e.toJson()).toList()));
  }
  Future<List<QuizDefinition>> loadQuizzes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_quizzesKey);
      if (raw == null || raw.isEmpty) return <QuizDefinition>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <QuizDefinition>[];
      return decoded.whereType<Map>()
          .map((item) => QuizDefinition.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return <QuizDefinition>[];
    }
  }

  Future<void> saveQuizzes(List<QuizDefinition> quizzes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quizzesKey, jsonEncode(quizzes.map((quiz) => quiz.toJson()).toList()));
  }
}
