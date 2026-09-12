import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class SegmentedPillBarItem {
  final String label;
  final int? badgeCount;

  const SegmentedPillBarItem({
    required this.label,
    this.badgeCount,
  });
}

class SegmentedPillBar extends StatelessWidget {
  final List<SegmentedPillBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final EdgeInsetsGeometry? padding;

  const SegmentedPillBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SahyanColors.chipBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SahyanColors.border, width: 0.8),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final isSelected = index == selectedIndex;
          final item = items[index];

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isSelected) {
                  HapticFeedback.selectionClick();
                  onSelect(index);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? SahyanColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: SahyanColors.textMain.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? SahyanColors.primaryDark
                            : SahyanColors.textMuted,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (item.badgeCount != null && item.badgeCount! > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? SahyanColors.primaryMint
                              : SahyanColors.border,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${item.badgeCount}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : SahyanColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
