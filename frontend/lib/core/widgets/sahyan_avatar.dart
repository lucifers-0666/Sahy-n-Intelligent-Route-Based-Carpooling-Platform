import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Standardized Sahyān User Avatar component.
/// Delivers clean circular profile avatars with initials fallback and optional verified indicator.
class SahyanAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final bool isVerified;
  final VoidCallback? onTap;

  const SahyanAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 24.0,
    this.isVerified = false,
    this.onTap,
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
    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.softForest,
      backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
          ? NetworkImage(imageUrl!)
          : null,
      child: (imageUrl == null || imageUrl!.isEmpty)
          ? Text(
              _initials.isNotEmpty ? _initials : '',
              style: AppTypography.caption.copyWith(
                fontSize: radius * 0.75,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryForest,
              ),
            )
          : null,
    );

    if (isVerified) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.mutedBrass, width: 1.5),
            ),
            child: avatar,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified,
                size: 14,
                color: AppColors.mutedBrass,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }
}
