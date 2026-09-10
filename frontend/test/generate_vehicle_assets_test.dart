import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/core/widgets/vehicles/vehicle_painters.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_type.dart';

void main() {
  testWidgets('Generate vehicle PNG assets for all 19 categories', (tester) async {
    await tester.runAsync(() async {
      for (final type in VehicleType.values) {
        final code = type.code;
        final dirPath = 'assets/icons/vehicles/$code';
        final dir = Directory(dirPath);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }

        // 1. Generate UI Illustration PNG (192x120)
        final uiRecorder = ui.PictureRecorder();
        final uiCanvas = Canvas(uiRecorder);
        final uiPainter = VehicleIllustrationPainter(
          type: type,
          primaryColor: AppColors.primary,
          secondaryColor: AppColors.primaryLight,
          accentColor: AppColors.accent,
        );
        uiPainter.paint(uiCanvas, const Size(192, 120));
        final uiPic = uiRecorder.endRecording();
        final uiImg = await uiPic.toImage(192, 120);
        final uiBytes = await uiImg.toByteData(format: ui.ImageByteFormat.png);
        if (uiBytes != null) {
          final file = File('$dirPath/${code}_ui.png');
          file.writeAsBytesSync(uiBytes.buffer.asUint8List());
        }

        // 2. Generate Map Marker PNG (128x128)
        final markerRecorder = ui.PictureRecorder();
        final markerCanvas = Canvas(markerRecorder);
        final markerPainter = VehicleMarkerPainter(
          type: type,
          primaryColor: AppColors.primary,
          isActive: true,
          heading: 0.0,
        );
        markerPainter.paint(markerCanvas, const Size(128, 128));
        final markerPic = markerRecorder.endRecording();
        final markerImg = await markerPic.toImage(128, 128);
        final markerBytes = await markerImg.toByteData(format: ui.ImageByteFormat.png);
        if (markerBytes != null) {
          final file = File('$dirPath/${code}_marker.png');
          file.writeAsBytesSync(markerBytes.buffer.asUint8List());
        }
      }
    });

    final totalFiles = Directory('assets/icons/vehicles')
        .listSync(recursive: true)
        .whereType<File>()
        .length;
    expect(totalFiles, 38);
  });
}
