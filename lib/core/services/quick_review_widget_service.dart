import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../i18n/app_strings.dart';
import '../models/app_models.dart';

/// Sends a lightweight snapshot of card text to the Android home-screen widget.
/// The app remains the source of truth; widget actions never change review state.
class QuickReviewWidgetService {
  static const MethodChannel _channel = MethodChannel('parin_litner/quick_widget');

  static Future<void> sync({
    required List<Deck> decks,
    required String languageCode,
  }) async {
    final parts = languageCode.split('-');
    final locale = Locale.fromSubtags(languageCode: parts.first, countryCode: parts.length > 1 ? parts[1] : null);
    final strings = AppStrings(locale);
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
    final isRtl = const <String>{'fa', 'ar', 'he'}.contains(locale.languageCode);
    final payload = jsonEncode({
      'labels': {
        'title': 'PARIN LITNER · ' + strings.text('quick_review').toUpperCase(),
        'reveal': strings.text('quick_show_answer'),
        'hide': strings.text('quick_hide_answer'),
        'next': strings.text('test_next'),
        'open': strings.text('home'),
        'empty': strings.text('quick_review_empty'),
        'due': strings.text('cards_ready'),
        'all': strings.text('cards_count'),
      },
      'isRtl': isRtl,
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
