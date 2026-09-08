import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/sahyan_chip.dart';

/// Horizontally scrollable quick transit hub selection chips.
/// Solves the horizontal clipping issue with fluid scrolling and proper item spacing.
class QuickHubChips extends StatelessWidget {
  final List<Map<String, dynamic>> hubs;
  final String? selectedHub;
  final ValueChanged<Map<String, dynamic>> onHubSelected;

  const QuickHubChips({
    super.key,
    required this.hubs,
    this.selectedHub,
    required this.onHubSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        itemCount: hubs.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final hub = hubs[index];
          final name = hub['name'] as String;
          final isSelected = selectedHub == name;

          return SahyanChip(
            label: name,
            isSelected: isSelected,
            activeColor: AppColors.softForest,
            activeTextColor: AppColors.deepForest,
            onTap: () => onHubSelected(hub),
          );
        },
      ),
    );
  }
}
