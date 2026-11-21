import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/image_storage_service.dart';

String uid() => '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}';
int dueCount(Deck d) => d.cards.where((c) => !c.dueAt.isAfter(DateTime.now())).length;
Color boxColor(LeitnerBox b) => Color(b.colorValue);

Uint8List? tryDecodeBase64Image(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  try {
    final bytes = base64Decode(value.trim());
    return bytes.isEmpty ? null : Uint8List.fromList(bytes);
  } catch (_) {
    return null;
  }
}

/// Loads either a legacy Base64 image or an image stored in app-private files.
class SafeMemoryImage extends StatefulWidget {
  final String? base64;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final Widget? error;

  const SafeMemoryImage({
    super.key,
    required this.base64,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.borderRadius = BorderRadius.zero,
    this.error,
  });

  @override
  State<SafeMemoryImage> createState() => _SafeMemoryImageState();
}

class _SafeMemoryImageState extends State<SafeMemoryImage> {
  late Future<Uint8List?> _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SafeMemoryImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.base64 != widget.base64) _load();
  }

  void _load() {
    _bytes = ImageStorageService().readBytes(widget.base64);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.hasError ||
            bytes == null ||
            bytes.isEmpty) {
          return widget.error ?? const SizedBox.shrink();
        }
        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: Image.memory(
            bytes,
            height: widget.height,
            width: widget.width,
            fit: widget.fit,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) =>
                widget.error ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
