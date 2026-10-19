import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/app_models.dart';
import '../utils/helpers.dart';

enum CardPdfLayout { flashcards, worksheet, quiz }

enum CardPdfPageSize { a4, a5, letter }

enum CardPdfSortOrder { original, favoritesFirst, dueFirst }

class CardPdfExportOptions {
  final CardPdfLayout layout;
  final CardPdfPageSize pageSize;
  final CardPdfSortOrder sortOrder;
  final int cardsPerPage;
  final bool landscape;
  final bool includeAnswers;
  final bool includeImages;
  final bool includeTags;
  final bool includeBox;
  final bool includeDifficulty;
  final bool includePageNumbers;
  final bool matchingCardsOnly;
  final String questionLabel;
  final String answerLabel;
  final String tagsLabel;
  final String boxLabel;
  final String difficultyLabel;
  final String favoriteLabel;
  final String imageCardLabel;
  final String pageLabel;
  final String answerKeyLabel;

  const CardPdfExportOptions({
    this.layout = CardPdfLayout.flashcards,
    this.pageSize = CardPdfPageSize.a4,
    this.sortOrder = CardPdfSortOrder.original,
    this.cardsPerPage = 2,
    this.landscape = false,
    this.includeAnswers = true,
    this.includeImages = true,
    this.includeTags = true,
    this.includeBox = false,
    this.includeDifficulty = false,
    this.includePageNumbers = true,
    this.matchingCardsOnly = false,
    required this.questionLabel,
    required this.answerLabel,
    required this.tagsLabel,
    required this.boxLabel,
    required this.difficultyLabel,
    required this.favoriteLabel,
    required this.imageCardLabel,
    required this.pageLabel,
    required this.answerKeyLabel,
  });
}

class CardPdfExportService {
  const CardPdfExportService._();

  static Future<Uint8List> generate({
    required Deck deck,
    required List<FlashCard> cards,
    required CardPdfExportOptions options,
  }) async {
    if (cards.isEmpty) {
      throw ArgumentError('Cannot export an empty card collection.');
    }

    final sortedCards = List<FlashCard>.from(cards);
    switch (options.sortOrder) {
      case CardPdfSortOrder.original:
        break;
      case CardPdfSortOrder.favoritesFirst:
        sortedCards.sort((a, b) => (b.favorite ? 1 : 0).compareTo(a.favorite ? 1 : 0));
        break;
      case CardPdfSortOrder.dueFirst:
        sortedCards.sort((a, b) => a.dueAt.compareTo(b.dueAt));
        break;
    }

    final searchableText = <String>[
      deck.name,
      deck.description,
      options.questionLabel,
      options.answerLabel,
      options.tagsLabel,
      options.boxLabel,
      options.difficultyLabel,
      options.favoriteLabel,
      options.imageCardLabel,
      options.pageLabel,
      options.answerKeyLabel,
      for (final card in sortedCards) card.front,
      for (final card in sortedCards) card.back,
      for (final card in sortedCards) card.tags,
    ].join(' ');
    final theme = await _loadTheme(searchableText);
    final pageFormat = switch (options.pageSize) {
      CardPdfPageSize.a4 => PdfPageFormat.a4,
      CardPdfPageSize.a5 => PdfPageFormat.a5,
      CardPdfPageSize.letter => PdfPageFormat.letter,
    };
    final orientation = options.landscape
        ? pw.PageOrientation.landscape
        : pw.PageOrientation.portrait;
    final pageWidth = options.landscape ? pageFormat.height : pageFormat.width;
    final pageHeight = options.landscape ? pageFormat.width : pageFormat.height;
    final cardsPerPage = options.cardsPerPage == 1 || options.cardsPerPage == 4
        ? options.cardsPerPage
        : 2;
    final cardPageCount = (sortedCards.length / cardsPerPage).ceil();
    final answerPageCount = options.layout == CardPdfLayout.quiz && options.includeAnswers
        ? (sortedCards.length / cardsPerPage).ceil()
        : 0;
    final totalPages = cardPageCount + answerPageCount;
    const margin = 26.0;
    const gap = 9.0;
    const headerHeight = 34.0;
    final footerHeight = options.includePageNumbers ? 22.0 : 6.0;
    final usableHeight = pageHeight -
        margin * 2 -
        headerHeight -
        footerHeight -
        gap * (cardsPerPage - 1);
    final cardHeight = math.max(70.0, usableHeight / cardsPerPage);
    final contentWidth = pageWidth - margin * 2;

    final document = pw.Document(
      title: deck.name,
      author: 'Parin Mashalchian',
      subject: 'Talent Litner flashcards',
    );

    for (var start = 0; start < sortedCards.length; start += cardsPerPage) {
      final end = math.min(start + cardsPerPage, sortedCards.length);
      final chunk = sortedCards.sublist(start, end);
      final pageIndex = start ~/ cardsPerPage;

      document.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: pageFormat,
            orientation: orientation,
            margin: const pw.EdgeInsets.all(margin),
            theme: theme,
            textDirection: _isRtl(searchableText)
                ? pw.TextDirection.rtl
                : pw.TextDirection.ltr,
          ),
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 9),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        deck.name,
                        style: pw.TextStyle(
                          fontSize: 17,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                    ),
                    pw.Text(
                      '${sortedCards.length} cards',
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < chunk.length; i++)
                _buildCard(
                  deck: deck,
                  card: chunk[i],
                  number: start + i + 1,
                  options: options,
                  width: contentWidth,
                  height: cardHeight,
                  gap: i == chunk.length - 1 ? 0 : gap,
                ),
              if (options.includePageNumbers) pw.Spacer(),
              if (options.includePageNumbers)
                _pageNumber(options.pageLabel, pageIndex + 1, totalPages),
            ],
          ),
        ),
      );
    }

    if (answerPageCount > 0) {
      for (var start = 0; start < sortedCards.length; start += cardsPerPage) {
        final end = math.min(start + cardsPerPage, sortedCards.length);
        final chunk = sortedCards.sublist(start, end);
        final pageIndex = cardPageCount + start ~/ cardsPerPage;
        final answerHeight = math.max(
          50.0,
          (usableHeight - 18) / cardsPerPage,
        );

        document.addPage(
          pw.Page(
            pageTheme: pw.PageTheme(
              pageFormat: pageFormat,
              orientation: orientation,
              margin: const pw.EdgeInsets.all(margin),
              theme: theme,
              textDirection: _isRtl(searchableText)
                  ? pw.TextDirection.rtl
                  : pw.TextDirection.ltr,
            ),
            build: (_) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Text(
                    options.answerKeyLabel + ' — ' + deck.name,
                    style: pw.TextStyle(
                      fontSize: 17,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal900,
                    ),
                  ),
                ),
                for (var i = 0; i < chunk.length; i++)
                  pw.Container(
                    height: answerHeight,
                    margin: pw.EdgeInsets.only(
                      bottom: i == chunk.length - 1 ? 0 : gap,
                    ),
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.FittedBox(
                      fit: pw.BoxFit.scaleDown,
                      alignment: pw.Alignment.topLeft,
                      child: pw.SizedBox(
                        width: contentWidth - 20,
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              '${start + i + 1}.',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                                color: PdfColors.teal900,
                              ),
                            ),
                            pw.SizedBox(width: 9),
                            pw.Expanded(
                              child: pw.Text(
                                _safeText(chunk[i].back, options.imageCardLabel),
                                style: pw.TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (options.includePageNumbers) pw.Spacer(),
                if (options.includePageNumbers)
                  _pageNumber(options.pageLabel, pageIndex + 1, totalPages),
              ],
            ),
          ),
        );
      }
    }

    return document.save();
  }

  static pw.Widget _buildCard({
    required Deck deck,
    required FlashCard card,
    required int number,
    required CardPdfExportOptions options,
    required double width,
    required double height,
    required double gap,
  }) {
    final frontImage = options.includeImages ? tryDecodeBase64Image(card.frontImage) : null;
    final backImage = options.includeImages ? tryDecodeBase64Image(card.backImage) : null;
    final showAnswer = options.includeAnswers && options.layout != CardPdfLayout.quiz;
    final baseFontSize = options.cardsPerPage == 4 ? 9.0 : options.cardsPerPage == 2 ? 11.0 : 13.0;

    final front = _section(
      label: '${options.questionLabel} $number',
      body: _safeText(card.front, options.imageCardLabel),
      image: frontImage,
      fontSize: baseFontSize,
      imageHeight: math.min(92.0, math.max(28.0, height * 0.27)),
    );
    final answer = _section(
      label: options.answerLabel,
      body: _safeText(card.back, options.imageCardLabel),
      image: backImage,
      fontSize: baseFontSize,
      imageHeight: math.min(92.0, math.max(28.0, height * 0.27)),
    );

    pw.Widget content;
    if (options.layout == CardPdfLayout.flashcards && showAnswer) {
      content = pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: front),
          pw.Container(
            width: 1,
            margin: const pw.EdgeInsets.symmetric(horizontal: 10),
            color: PdfColors.grey400,
          ),
          pw.Expanded(child: answer),
        ],
      );
    } else {
      content = pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          front,
          if (showAnswer) ...[
            pw.SizedBox(height: 7),
            pw.Container(height: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 7),
            answer,
          ],
        ],
      );
    }

    final metadata = <String>[];
    if (options.includeTags && card.tags.trim().isNotEmpty) {
      metadata.add('${options.tagsLabel}: ${card.tags.trim()}');
    }
    if (options.includeBox && deck.boxes.isNotEmpty) {
      final boxIndex = card.boxIndex.clamp(0, deck.boxes.length - 1).toInt();
      metadata.add('${options.boxLabel}: ${deck.boxes[boxIndex].name}');
    }
    if (options.includeDifficulty) {
      metadata.add('${options.difficultyLabel}: ${card.difficulty}');
      if (card.favorite) metadata.add(options.favoriteLabel);
    }

    return pw.Container(
      height: height,
      margin: pw.EdgeInsets.only(bottom: gap),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.FittedBox(
        fit: pw.BoxFit.scaleDown,
        alignment: pw.Alignment.topLeft,
        child: pw.SizedBox(
          width: width - 20,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              content,
              if (metadata.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Text(
                  metadata.join('  •  '),
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static pw.Widget _section({
    required String label,
    required String body,
    required Uint8List? image,
    required double fontSize,
    required double imageHeight,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: const pw.BoxDecoration(
            color: PdfColors.indigo50,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
              color: PdfColors.indigo900,
            ),
          ),
        ),
        pw.SizedBox(height: 6),
        if (image != null)
          pw.Container(
            height: imageHeight,
            alignment: pw.Alignment.centerLeft,
            child: pw.Image(pw.MemoryImage(image), fit: pw.BoxFit.contain),
          ),
        pw.Text(
          body,
          style: pw.TextStyle(
            fontSize: fontSize,
            lineSpacing: 2,
            color: PdfColors.grey900,
          ),
        ),
      ],
    );
  }

  static pw.Widget _pageNumber(String label, int page, int total) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        '$label $page / $total',
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }

  static String _safeText(String value, String imagePlaceholder) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? imagePlaceholder : trimmed;
  }

  static bool _isRtl(String content) =>
      RegExp(r'[\u0590-\u08FF]').hasMatch(content);

  static Future<pw.ThemeData> _loadTheme(String content) async {
    if (!RegExp(r'[^\x00-\x7F]').hasMatch(content)) {
      return pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      );
    }

    if (RegExp(r'[\u0590-\u05FF]').hasMatch(content)) {
      return pw.ThemeData.withFont(
        base: await PdfGoogleFonts.notoSansHebrewRegular(),
        bold: await PdfGoogleFonts.notoSansHebrewBold(),
      );
    }

    if (RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(content)) {
      return pw.ThemeData.withFont(
        base: await PdfGoogleFonts.notoSansArabicRegular(),
        bold: await PdfGoogleFonts.notoSansArabicBold(),
      );
    }

    if (RegExp(r'[\u3040-\u30FF\u4E00-\u9FFF]').hasMatch(content)) {
      return pw.ThemeData.withFont(
        base: await PdfGoogleFonts.notoSansJPRegular(),
        bold: await PdfGoogleFonts.notoSansJPBold(),
      );
    }

    if (RegExp(r'[\uAC00-\uD7AF]').hasMatch(content)) {
      return pw.ThemeData.withFont(
        base: await PdfGoogleFonts.notoSansKRRegular(),
        bold: await PdfGoogleFonts.notoSansKRBold(),
      );
    }

    return pw.ThemeData.withFont(
      base: await PdfGoogleFonts.notoSansRegular(),
      bold: await PdfGoogleFonts.notoSansBold(),
    );
  }
}
