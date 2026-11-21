import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

typedef ImageDirectoryProvider = Future<Directory> Function();

/// Stores images as app-private files, keeping Base64 blobs out of JSON storage.
class ImageStorageService {
  static const String referencePrefix = 'talent-image:v1:';
  static const int maxImageBytes = 64 * 1024 * 1024;
  static final RegExp _fileNamePattern = RegExp(r'^[a-f0-9]{64}\.bin$');

  final ImageDirectoryProvider _directoryProvider;

  ImageStorageService({ImageDirectoryProvider? directoryProvider})
      : _directoryProvider =
            directoryProvider ?? getApplicationDocumentsDirectory;

  static bool isStoredReference(String? value) =>
      value != null && _fileName(value) != null;

  static String? _fileName(String? value) {
    if (value == null || !value.startsWith(referencePrefix)) return null;
    final name = value.substring(referencePrefix.length);
    return _fileNamePattern.hasMatch(name) ? name : null;
  }

  Future<Directory> _imagesDirectory() async {
    final root = await _directoryProvider();
    final directory = Directory('${root.path}/talent_litner_images');
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<String> storeBytes(List<int> bytes) async {
    if (bytes.isEmpty) throw const FormatException('The selected image is empty.');
    if (bytes.length > maxImageBytes) {
      throw const FormatException('The selected image exceeds the supported size.');
    }
    final digest = sha256.convert(bytes).toString();
    final name = '$digest.bin';
    final directory = await _imagesDirectory();
    final file = File('${directory.path}/$name');
    var writeNeeded = !await file.exists();
    if (!writeNeeded) {
      try {
        writeNeeded = sha256.convert(await file.readAsBytes()).toString() != digest;
      } on FileSystemException {
        writeNeeded = true;
      }
    }
    if (writeNeeded) await file.writeAsBytes(bytes, flush: true);
    return '$referencePrefix$name';
  }

  Future<String?> storeImageData(String? value) async {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim();
    if (normalized.startsWith(referencePrefix)) {
      if (!isStoredReference(normalized)) {
        throw const FormatException('A stored image reference is invalid.');
      }
      return normalized;
    }
    return storeBytes(base64Decode(normalized));
  }

  Future<Uint8List?> readBytes(String? value) async {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim();
    if (normalized.startsWith(referencePrefix)) {
      final name = _fileName(normalized);
      if (name == null) return null;
      try {
        final directory = await _imagesDirectory();
        final file = File('${directory.path}/$name');
        if (!await file.exists()) return null;
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty || bytes.length > maxImageBytes) return null;
        return bytes;
      } on FileSystemException {
        return null;
      }
    }
    try {
      final bytes = base64Decode(normalized);
      if (bytes.isEmpty || bytes.length > maxImageBytes) return null;
      return Uint8List.fromList(bytes);
    } on FormatException {
      return null;
    }
  }

  Future<String?> readAsBase64(String? value) async {
    if (value == null || value.trim().isEmpty) return null;
    final bytes = await readBytes(value);
    if (bytes == null || bytes.isEmpty) {
      throw const FormatException(
        'An image referenced by this document is missing or unreadable.',
      );
    }
    return base64Encode(bytes);
  }
}
