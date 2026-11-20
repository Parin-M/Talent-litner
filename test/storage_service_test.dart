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
}
