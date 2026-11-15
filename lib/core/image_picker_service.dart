import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Utilities for picking and processing a profile picture.
///
/// Images are decoded, downscaled to a small square, and re-encoded to PNG so
/// they can be stored compactly (base64) in Firestore and rendered with a
/// [MemoryImage] without depending on Firebase Storage.
class ProfileImageService {
  static const int _targetSize = 256;

  /// Opens the platform file picker (gallery) and returns the processed PNG as
  /// base64, or `null` if the user cancelled.
  static Future<String?> pickAndEncodeProfileImage() async {
    final files = await FilePicker.pickFiles(
      type: FileType.image,
    );
    if (files.isEmpty) return null;

    final file = files.first;
    final Uint8List bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;

    final Uint8List pngBytes = await _processToPng(bytes);
    return base64Encode(pngBytes);
  }

  /// Decodes raw image bytes and re-encodes as a downscaled square PNG.
  static Future<Uint8List> _processToPng(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    // Crop to a centered square to avoid distortion.
    final width = image.width;
    final height = image.height;
    final side = width < height ? width : height;
    final srcX = (width - side) ~/ 2;
    final srcY = (height - side) ~/ 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(srcX.toDouble(), srcY.toDouble(), side.toDouble(), side.toDouble()),
      Rect.fromLTWH(0, 0, _targetSize.toDouble(), _targetSize.toDouble()),
      paint,
    );
    final picture = recorder.endRecording();
    final resizedImage = await picture.toImage(_targetSize, _targetSize);
    final byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);

    image.dispose();
    resizedImage.dispose();

    if (byteData == null) {
      throw Exception('Gagal memproses gambar profil.');
    }
    return byteData.buffer.asUint8List();
  }

  /// Decodes a base64 profile photo into an image provider, or returns null.
  static ImageProvider? decodeToProvider(String? photoData) {
    if (photoData == null || photoData.isEmpty) return null;
    try {
      final bytes = base64Decode(photoData);
      if (bytes.isEmpty) return null;
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Returns the first initial of a name, uppercased, with a safe fallback.
  static String initial(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return 'U';
    return trimmed[0].toUpperCase();
  }
}
