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
    const pad = EdgeInsets.all(4);

    return Container(
      height: 48,
      padding: padding ?? pad,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2EF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SahyanColors.border, width: 0.8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final tabWidth = items.isNotEmpty ? totalWidth / items.length : 0.0;

          return Stack(
            children: [
              // Sliding White Pill Indicator
              if (items.isNotEmpty)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  left: selectedIndex * tabWidth,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: SahyanColors.surface,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: SahyanColors.textMain.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),

              // Interactive Tab Items Row
              Row(
                children: List.generate(items.length, (index) {
                  final isSelected = index == selectedIndex;
                  final item = items[index];

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (!isSelected) {
                          HapticFeedback.selectionClick();
                          onSelect(index);
                        }
                      },
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isSelected
                                      ? SahyanColors.primaryDark
                                      : SahyanColors.textMuted,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (item.badgeCount != null &&
                                  item.badgeCount! > 0) ...[
                                const SizedBox(width: 6),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
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
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
