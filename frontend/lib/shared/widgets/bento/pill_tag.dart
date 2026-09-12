import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum PillTagVariant {
  neutral,
  mint,
  dark,
  gold,
  coral,
}

class PillTag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final PillTagVariant variant;
  final Color? customBackground;
  final Color? customTextColor;
  final EdgeInsetsGeometry? padding;
  final double fontSize;
  final VoidCallback? onTap;

  const PillTag({
    super.key,
    required this.label,
    this.icon,
    this.variant = PillTagVariant.neutral,
    this.customBackground,
    this.customTextColor,
    this.padding,
    this.fontSize = 12,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;

    switch (variant) {
      case PillTagVariant.mint:
        bg = SahyanColors.primaryLight;
        fg = SahyanColors.primaryDark;
        border = Border.all(
          color: SahyanColors.primaryMint.withValues(alpha: 0.3),
          width: 0.8,
        );
        break;
      case PillTagVariant.dark:
        bg = SahyanColors.primaryDark;
        fg = Colors.white;
        border = null;
        break;
      case PillTagVariant.gold:
        bg = const Color(0xFFFEF7EA);
        fg = const Color(0xFFB57A18);
        border = Border.all(
          color: SahyanColors.goldStar.withValues(alpha: 0.3),
          width: 0.8,
        );
        break;
      case PillTagVariant.coral:
        bg = const Color(0xFFFDEEEB);
        fg = SahyanColors.urgentCoral;
        border = Border.all(
          color: SahyanColors.urgentCoral.withValues(alpha: 0.3),
          width: 0.8,
        );
        break;
      case PillTagVariant.neutral:
        bg = SahyanColors.chipBackground;
        fg = SahyanColors.textMain;
        border = Border.all(color: SahyanColors.border, width: 0.8);
        break;
    }

    if (customBackground != null) bg = customBackground!;
    if (customTextColor != null) fg = customTextColor!;

    Widget content = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
