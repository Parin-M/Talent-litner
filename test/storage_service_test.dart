import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parin_litner/core/services/storage_service.dart';

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

}
