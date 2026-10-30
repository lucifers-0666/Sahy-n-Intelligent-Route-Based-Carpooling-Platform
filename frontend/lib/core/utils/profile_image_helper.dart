import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Settings for cropping and resizing user profile photos.
class CropSettings {
  final int targetSize; // Output pixel dimension, e.g. 300 or 600
  final double scale; // Zoom factor, 1.0 to 3.0
  final Offset panOffset; // Normalized pan offset (-1.0 to 1.0)
  final int rotationDegrees; // 0, 90, 180, 270
  final bool isCircleFrame;

  const CropSettings({
    this.targetSize = 300,
    this.scale = 1.0,
    this.panOffset = Offset.zero,
    this.rotationDegrees = 0,
    this.isCircleFrame = true,
  });

  CropSettings copyWith({
    int? targetSize,
    double? scale,
    Offset? panOffset,
    int? rotationDegrees,
    bool? isCircleFrame,
  }) {
    return CropSettings(
      targetSize: targetSize ?? this.targetSize,
      scale: scale ?? this.scale,
      panOffset: panOffset ?? this.panOffset,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      isCircleFrame: isCircleFrame ?? this.isCircleFrame,
    );
  }
}

/// Provides safe, unified ImageProvider resolution for profile avatars:
/// supports Data URIs (Base64 JPEG/PNG), Network URLs, and Assets.
ImageProvider? getProfileImageProvider(String? photoUrl) {
  if (photoUrl == null) return null;
  final trimmed = photoUrl.trim();
  if (trimmed.isEmpty) return null;

  if (trimmed.startsWith('data:image')) {
    try {
      final commaIndex = trimmed.indexOf(',');
      final base64Part =
          commaIndex != -1 ? trimmed.substring(commaIndex + 1) : trimmed;
      final bytes = base64Decode(base64Part);
      return MemoryImage(bytes);
    } catch (e) {
      debugPrint('Failed to decode base64 profile image: $e');
      return null;
    }
  }

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return NetworkImage(trimmed);
  }

  if (trimmed.startsWith('assets/')) {
    return AssetImage(trimmed);
  }

  return null;
}

/// Crops, rotates, resizes, and encodes raw image bytes to an optimized Data URI.
Future<String?> processAndCropImageBytes({
  required Uint8List rawBytes,
  required CropSettings settings,
}) async {
  try {
    img.Image? original = img.decodeImage(rawBytes);
    if (original == null) return null;

    // Auto-normalize orientation from EXIF
    original = img.bakeOrientation(original);

    // Apply manual rotation if requested
    if (settings.rotationDegrees != 0) {
      original = img.copyRotate(original, angle: settings.rotationDegrees);
    }

    final origW = original.width;
    final origH = original.height;

    // Minimum dimension defines baseline square
    final minDim = origW < origH ? origW : origH;
    final baseCropSize = (minDim / settings.scale).clamp(32.0, minDim.toDouble());

    // Center coordinates adjusted for user pan
    final centerX = origW / 2.0 - (settings.panOffset.dx * (origW / 2.0));
    final centerY = origH / 2.0 - (settings.panOffset.dy * (origH / 2.0));

    int cropX = (centerX - baseCropSize / 2.0).round();
    int cropY = (centerY - baseCropSize / 2.0).round();

    // Clamp strictly within image boundaries
    if (cropX < 0) cropX = 0;
    if (cropY < 0) cropY = 0;
    if (cropX + baseCropSize > origW) cropX = (origW - baseCropSize).round();
    if (cropY + baseCropSize > origH) cropY = (origH - baseCropSize).round();

    final int cropWidth = baseCropSize.round().clamp(1, origW - cropX);
    final int cropHeight = baseCropSize.round().clamp(1, origH - cropY);

    final img.Image cropped = img.copyCrop(
      original,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    // Resize to target resolution (e.g. 300x300 or 600x600)
    final target = settings.targetSize;
    final img.Image resized = img.copyResize(
      cropped,
      width: target,
      height: target,
      interpolation: img.Interpolation.cubic,
    );

    final jpgBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    final base64String = base64Encode(jpgBytes);
    return 'data:image/jpeg;base64,$base64String';
  } catch (e) {
    debugPrint('Error processing and cropping profile image: $e');
    return null;
  }
}
