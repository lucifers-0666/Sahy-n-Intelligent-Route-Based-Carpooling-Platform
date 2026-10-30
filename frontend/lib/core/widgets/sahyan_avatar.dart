import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../utils/profile_image_helper.dart';

/// Standardized Sahyān User Avatar component.
/// Delivers clean circular profile avatars with initials fallback,
/// supports both Base64 Data URIs (local cropped uploads) and Network URLs,
/// and includes an optional verified indicator.
class SahyanAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final bool isVerified;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double borderWidth;

  const SahyanAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 24.0,
    this.isVerified = false,
    this.onTap,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth = 1.5,
  });

  String get _initials {
    if (name == null || name!.trim().isEmpty) return '';
    final parts = name!.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = getProfileImageProvider(imageUrl);
    final hasImage = imageProvider != null;

    final bgColor = backgroundColor ?? AppColors.softForest;
    final fgColor = foregroundColor ?? AppColors.primaryForest;

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      backgroundImage: imageProvider,
      onBackgroundImageError: hasImage ? (exception, stackTrace) {} : null,
      child: !hasImage
          ? Text(
              _initials.isNotEmpty ? _initials : '',
              style: AppTypography.caption.copyWith(
                fontSize: radius * 0.75,
                fontWeight: FontWeight.w800,
                color: fgColor,
                fontFamily: 'Plus Jakarta Sans',
              ),
            )
          : null,
    );

    if (borderColor != null) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor!, width: borderWidth),
        ),
        child: avatar,
      );
    }

    if (isVerified) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified,
                size: (radius * 0.65).clamp(12.0, 18.0),
                color: AppColors.deepEmerald,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: avatar,
      );
    }
    return avatar;
  }
}
