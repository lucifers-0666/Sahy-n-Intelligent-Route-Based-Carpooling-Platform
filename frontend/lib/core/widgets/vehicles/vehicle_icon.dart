import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../features/vehicles/domain/vehicle_type.dart';
import 'vehicle_painters.dart';

enum VehicleIconVariant {
  illustration,
  mapMarker,
  badge,
}

/// Centralized Sahyān Vehicle Icon Widget.
/// Renders standard vehicle illustrations and directional map markers
/// across all 19 vehicle categories.
class VehicleIcon extends StatelessWidget {
  final VehicleType type;
  final VehicleIconVariant variant;
  final double width;
  final double height;
  final Color? color;
  final bool isSelected;
  final bool isActive;
  final double heading;

  const VehicleIcon({
    super.key,
    required this.type,
    this.variant = VehicleIconVariant.illustration,
    this.width = 64,
    this.height = 40,
    this.color,
    this.isSelected = false,
    this.isActive = true,
    this.heading = 0.0,
  });

  const VehicleIcon.illustration({
    super.key,
    required this.type,
    this.width = 72,
    this.height = 44,
    this.color,
    this.isSelected = false,
  })  : variant = VehicleIconVariant.illustration,
        isActive = true,
        heading = 0.0;

  const VehicleIcon.mapMarker({
    super.key,
    required this.type,
    double size = 48,
    this.heading = 0.0,
    this.isActive = true,
    this.color,
  })  : variant = VehicleIconVariant.mapMarker,
        width = size,
        height = size,
        isSelected = false;

  const VehicleIcon.badge({
    super.key,
    required this.type,
    double size = 40,
    this.color,
    this.isSelected = false,
  })  : variant = VehicleIconVariant.badge,
        width = size,
        height = size,
        isActive = true,
        heading = 0.0;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    switch (variant) {
      case VehicleIconVariant.badge:
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryLight
                : AppColors.surfaceVariant,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          padding: EdgeInsets.all(width * 0.18),
          child: CustomPaint(
            size: Size(width, height),
            painter: VehicleIllustrationPainter(
              type: type,
              primaryColor: effectiveColor,
              isSelected: false,
            ),
          ),
        );

      case VehicleIconVariant.mapMarker:
        return RepaintBoundary(
          child: CustomPaint(
            size: Size(width, height),
            painter: VehicleMarkerPainter(
              type: type,
              primaryColor: effectiveColor,
              isActive: isActive,
              heading: heading,
            ),
          ),
        );

      case VehicleIconVariant.illustration:
        return RepaintBoundary(
          child: CustomPaint(
            size: Size(width, height),
            painter: VehicleIllustrationPainter(
              type: type,
              primaryColor: effectiveColor,
              isSelected: isSelected,
            ),
          ),
        );
    }
  }
}

/// Helper facade for accessing vehicle visual metadata and asset paths.
class VehicleAssets {
  VehicleAssets._();

  static String displayName(VehicleType type) => type.displayName;
  static int defaultCapacity(VehicleType type) => type.defaultSeatCapacity;
  static String categoryName(VehicleType type) => type.categoryGroup.displayName;
  static bool isElectric(VehicleType type) => type.isElectric;

  static String uiAssetPath(VehicleType type) =>
      'assets/icons/vehicles/${type.code}/${type.code}_ui.png';

  static String markerAssetPath(VehicleType type) =>
      'assets/icons/vehicles/${type.code}/${type.code}_marker.png';

  static Widget iconFor(VehicleType type, {double width = 56, double height = 36, Color? color}) {
    return VehicleIcon.illustration(
      type: type,
      width: width,
      height: height,
      color: color,
    );
  }

  static Widget badgeFor(VehicleType type, {double size = 40, bool isSelected = false}) {
    return VehicleIcon.badge(
      type: type,
      size: size,
      isSelected: isSelected,
    );
  }
}
