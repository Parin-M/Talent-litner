import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:parin_litner/core/models/app_models.dart';
import 'package:parin_litner/core/services/image_storage_service.dart';
import 'package:parin_litner/core/services/pdf_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CardPdfExportOptions options() => CardPdfExportOptions(
        questionLabel: 'Question',
        answerLabel: 'Answer',
        tagsLabel: 'Tags',
        boxLabel: 'Box',
        difficultyLabel: 'Difficulty',
        favoriteLabel: 'Favorite',
        imageCardLabel: 'Image',
        pageLabel: 'Page',
        answerKeyLabel: 'Answer key',
      );

  test('generates a PDF with a file-backed flashcard image', () async {
    final temp = await Directory.systemTemp.createTemp('talent-pdf-images-');
    try {
      final imageStore = ImageStorageService(
        directoryProvider: () async => temp,
      );
      const png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=';
      final reference = await imageStore.storeBytes(base64Decode(png));
      final deck = Deck(
        id: 'pdf-deck',
        name: 'PDF deck',
        cards: [
          FlashCard(
            id: 'pdf-card',
            front: 'Question',
            back: 'Answer',
            frontImage: reference,
          ),
        ],
      );

      final bytes = await CardPdfExportService.generate(
        deck: deck,
        cards: deck.cards,
        options: options(),
        imageStore: imageStore,
      );

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(500));
    } finally {
      await temp.delete(recursive: true);
    }
  });

  test('rejects an empty collection without attempting PDF generation', () async {
    final deck = Deck(id: 'empty-deck', name: 'Empty');
    await expectLater(
      CardPdfExportService.generate(
        deck: deck,
        cards: const <FlashCard>[],
        options: options(),
      ),
      throwsArgumentError,
    );
  });
}
