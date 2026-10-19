import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../models/app_models.dart';

class BackupBundle {
  final List<Deck> decks;
  final List<QuizDefinition> quizzes;
  const BackupBundle({required this.decks, required this.quizzes});
}

class BackupService {
  static const List<int> _magic = <int>[0x50, 0x4c, 0x49, 0x54, 0x42, 0x4b, 0x30, 0x31]; // PLITBK01
  static const int _maxManifestBytes = 64 * 1024 * 1024;
  static const int _maxAssets = 50000;

  Future<bool> exportBackup(List<Deck> decks, {List<QuizDefinition> quizzes = const <QuizDefinition>[]}) async {
    final assets = <String, Uint8List>{};
    var nextAsset = 0;
    String? addImage(dynamic raw, String label) {
      if (raw == null) return null;
      if (raw is! String) throw FormatException('Invalid image data for $label.');
      if (raw.trim().isEmpty) return null;
      final Uint8List data;
      try { data = Uint8List.fromList(base64Decode(raw.trim())); }
      on FormatException { throw FormatException('Invalid image data for $label.'); }
      if (data.isEmpty) return null;
      nextAsset++;
      final name = 'image_${nextAsset.toString().padLeft(6, '0')}.bin';
      assets[name] = data;
      return name;
    }

    final deckPayload = <Map<String, dynamic>>[];
    for (final deck in decks) {
      final deckJson = deck.toJson();
      final originalCards = (deckJson['cards'] as List? ?? const []);
      deckJson['cards'] = originalCards.map((rawCard) {
        final card = Map<String, dynamic>.from(rawCard as Map);
        final id = card['id']?.toString() ?? 'unknown';
        card['frontImageAsset'] = addImage(card.remove('frontImage'), 'card $id front');
        card['backImageAsset'] = addImage(card.remove('backImage'), 'card $id back');
        return card;
      }).toList();
      deckPayload.add(deckJson);
    }

    final manifest = <String, dynamic>{
      'app': 'Parin Litner', 'format': 2,
      'quizzes': quizzes.map((quiz) => quiz.toJson()).toList(),
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'imageCount': assets.length, 'decks': deckPayload,
    };
    final manifestBytes = Uint8List.fromList(utf8.encode(jsonEncode(manifest)));
    if (manifestBytes.length > _maxManifestBytes) throw const FormatException('Backup metadata is too large.');
    final output = <int>[..._magic, ..._uint32(manifestBytes.length), ...manifestBytes];
    for (final entry in assets.entries) {
      final nameBytes = utf8.encode(entry.key);
      if (nameBytes.isEmpty || nameBytes.length > 0xffff) throw const FormatException('Invalid image asset name.');
      output..addAll(_uint16(nameBytes.length))..addAll(nameBytes)..addAll(_uint32(entry.value.length))..addAll(entry.value);
    }

    final saved = await FilePicker.saveFile(
      dialogTitle: 'ذخیره پشتیبان Parin Litner',
      fileName: 'parin_litner_backup.plbackup',
      type: FileType.custom,
      allowedExtensions: ['plbackup'],
      bytes: Uint8List.fromList(output),
    );
    return saved != null;
  }

  Future<List<Deck>?> importDecks() async => (await importBackup())?.decks;

  Future<BackupBundle?> importBackup() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['plbackup', 'json'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final bytes = picked.files.first.bytes;
    if (bytes == null) throw const FormatException('Unable to read the selected backup file.');
    if (_hasMagic(bytes)) return _decodeBinaryBackup(bytes);

    // Backward compatibility for pre-.plbackup JSON files.
    final dynamic decoded;
    try { decoded = jsonDecode(utf8.decode(bytes)); }
    on FormatException { throw const FormatException('This is not a valid Parin Litner backup.'); }
    final dynamic rawDecks = decoded is Map ? decoded['decks'] : decoded;
    final dynamic rawQuizzes = decoded is Map ? decoded['quizzes'] : null;
    if (rawDecks is! List) throw const FormatException('The selected file does not contain a deck list.');
    final decks = rawDecks.map((raw) {
      if (raw is! Map) throw const FormatException('A deck record is invalid.');
      return Deck.fromJson(Map<String, dynamic>.from(raw));
    }).toList();
    final quizzes = rawQuizzes is List
        ? rawQuizzes.whereType<Map>().map((raw) => QuizDefinition.fromJson(Map<String, dynamic>.from(raw))).toList()
        : <QuizDefinition>[];
    return BackupBundle(decks: decks, quizzes: quizzes);
  }

  BackupBundle _decodeBinaryBackup(Uint8List bytes) {
    if (bytes.length < 12) throw const FormatException('Backup file is incomplete.');
    final manifestLength = _readUint32(bytes, 8);
    if (manifestLength > _maxManifestBytes || manifestLength > bytes.length - 12) throw const FormatException('Backup metadata length is invalid.');
    final manifestStart = 12;
    final assetStart = manifestStart + manifestLength;
    final dynamic rawManifest;
    try { rawManifest = jsonDecode(utf8.decode(bytes.sublist(manifestStart, assetStart))); }
    on FormatException { throw const FormatException('Backup metadata is damaged.'); }
    if (rawManifest is! Map) throw const FormatException('Backup metadata is invalid.');
    final manifest = Map<String, dynamic>.from(rawManifest);
    final format = manifest['format'];
    if (manifest['app'] != 'Parin Litner' || (format != 1 && format != 2)) throw const FormatException('This backup version is not supported.');
    final count = manifest['imageCount'];
    if (count is! int || count < 0 || count > _maxAssets) throw const FormatException('Backup image count is invalid.');

    var offset = assetStart;
    final assets = <String, Uint8List>{};
    for (var i = 0; i < count; i++) {
      if (offset + 2 > bytes.length) throw const FormatException('Backup image table is incomplete.');
      final nameLength = _readUint16(bytes, offset);
      offset += 2;
      if (nameLength == 0 || offset + nameLength + 4 > bytes.length) throw const FormatException('Backup image entry is invalid.');
      final name = utf8.decode(bytes.sublist(offset, offset + nameLength));
      offset += nameLength;
      final dataLength = _readUint32(bytes, offset);
      offset += 4;
      if (dataLength > bytes.length - offset || assets.containsKey(name)) throw const FormatException('Backup image data is incomplete or duplicated.');
      assets[name] = Uint8List.fromList(bytes.sublist(offset, offset + dataLength));
      offset += dataLength;
    }
    if (offset != bytes.length) throw const FormatException('Backup file contains unexpected trailing data.');

    final dynamic rawDecks = manifest['decks'];
    if (rawDecks is! List) throw const FormatException('Backup does not contain a deck list.');
    final decks = rawDecks.map((rawDeck) {
      if (rawDeck is! Map) throw const FormatException('A deck record is invalid.');
      final deck = Map<String, dynamic>.from(rawDeck);
      final dynamic rawCards = deck['cards'];
      if (rawCards is! List) throw const FormatException('A deck has an invalid card list.');
      deck['cards'] = rawCards.map((rawCard) {
        if (rawCard is! Map) throw const FormatException('A card record is invalid.');
        final card = Map<String, dynamic>.from(rawCard);
        for (final side in const ['front', 'back']) {
          final ref = card.remove('${side}ImageAsset');
          if (ref != null) {
            if (ref is! String || !assets.containsKey(ref)) throw const FormatException('A card image is missing from the backup.');
            card['${side}Image'] = base64Encode(assets[ref]!);
          } else {
            card['${side}Image'] = null;
          }
        }
        return card;
      }).toList();
      return Deck.fromJson(deck);
    }).toList();
    final dynamic rawQuizzes = manifest['quizzes'];
    final quizzes = rawQuizzes is List
        ? rawQuizzes.whereType<Map>().map((raw) => QuizDefinition.fromJson(Map<String, dynamic>.from(raw))).toList()
        : <QuizDefinition>[];
    return BackupBundle(decks: decks, quizzes: quizzes);
  }

  Future<bool> exportDecks(List<Deck> decks) => exportBackup(decks);

  bool _hasMagic(Uint8List bytes) {
    if (bytes.length < _magic.length) return false;
    for (var i = 0; i < _magic.length; i++) { if (bytes[i] != _magic[i]) return false; }
    return true;
  }
  List<int> _uint16(int value) { final data = ByteData(2)..setUint16(0, value, Endian.big); return data.buffer.asUint8List(); }
  List<int> _uint32(int value) { final data = ByteData(4)..setUint32(0, value, Endian.big); return data.buffer.asUint8List(); }
  int _readUint16(Uint8List bytes, int offset) => ByteData.sublistView(bytes, offset, offset + 2).getUint16(0, Endian.big);
  int _readUint32(Uint8List bytes, int offset) => ByteData.sublistView(bytes, offset, offset + 4).getUint32(0, Endian.big);
}
