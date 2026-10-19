import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/app_models.dart';

/// Sends a lightweight snapshot of card text to the Android home-screen widget.
/// The app remains the source of truth; widget actions never change review state.
class QuickReviewWidgetService {
  static const MethodChannel _channel = MethodChannel('parin_litner/quick_widget');

  static Future<void> sync({
    required List<Deck> decks,
    required String languageCode,
  }) async {
    final now = DateTime.now();
    final cards = <Map<String, Object?>>[];
    for (final deck in decks) {
      for (final card in deck.cards) {
        cards.add({
          'deck': deck.name,
          'front': card.front.trim().isEmpty ? (languageCode == 'fa' ? 'کارت تصویری' : 'Image card') : card.front,
          'back': card.back.trim().isEmpty ? (languageCode == 'fa' ? 'پاسخ تصویری' : 'Image answer') : card.back,
          'due': !card.dueAt.isAfter(now),
        });
      }
    }
    final isFa = languageCode == 'fa';
    final payload = jsonEncode({
      'labels': {
        'title': isFa ? 'پرین لیترن · مرور سریع' : 'PARIN LITNER · QUICK REVIEW',
        'reveal': isFa ? 'نمایش پاسخ' : 'Reveal',
        'hide': isFa ? 'پنهان' : 'Hide',
        'next': isFa ? 'بعدی' : 'Next',
        'open': isFa ? 'باز کردن' : 'Open app',
        'empty': isFa ? 'ابتدا چند فلش‌کارت بسازید.' : 'Create a few flashcards first.',
        'due': isFa ? 'کارت آماده مرور' : 'cards due',
        'all': isFa ? 'کارت برای مرور سریع' : 'cards available',
      },
      'isRtl': isFa || languageCode == 'ar' || languageCode == 'he',
      'cards': cards,
    });
    try {
      await _channel.invokeMethod<void>('syncCards', {'payload': payload});
    } on MissingPluginException {
      // Non-Android builds and older development installations skip the native widget.
    } on PlatformException {
      // Do not break saving or studying if widget synchronization fails.
    }
  }
}
