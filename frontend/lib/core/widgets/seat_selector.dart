import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

class SeatSelector extends StatelessWidget {
  final int totalSeats;
  final int availableSeats;
  final List<String> selectedSeats;
  final ValueChanged<List<String>> onSeatsChanged;

  const SeatSelector({
    super.key,
    this.totalSeats = 4,
    required this.availableSeats,
    required this.selectedSeats,
    required this.onSeatsChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Generate seat layout (Front: Passenger A1 & Driver; Rear: A2, A3, A4)
    final List<Map<String, dynamic>> seats = [
      {'id': 'A1', 'label': 'Front Passenger', 'isAvailable': availableSeats >= 1},
      {'id': 'A2', 'label': 'Rear Left', 'isAvailable': availableSeats >= 2},
      {'id': 'A3', 'label': 'Rear Center', 'isAvailable': availableSeats >= 3},
      {'id': 'A4', 'label': 'Rear Right', 'isAvailable': availableSeats >= 4},
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Seat(s)',
                style: AppTypography.sectionHeader.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: selectedSeats.isNotEmpty
                      ? AppColors.softForest
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: selectedSeats.isNotEmpty
                        ? AppColors.primaryForest.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  selectedSeats.isNotEmpty
                      ? '${selectedSeats.length} seat${selectedSeats.length > 1 ? 's' : ''} chosen'
                      : 'Tap seat to pick',
                  style: AppTypography.caption.copyWith(
                    color: selectedSeats.isNotEmpty
                        ? AppColors.primaryForest
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),

          // Windshield / Front Cabin Header
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.horizontal_rule_rounded,
                    size: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'FRONT CABIN / WINDSHIELD',
                    style: AppTypography.caption.copyWith(
                      letterSpacing: 0.8,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.horizontal_rule_rounded,
                    size: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          // Front Row: Passenger (A1) & Driver
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSeatItem(seats[0]),
              // Driver Position
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: AppColors.border,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.drive_eta_rounded,
                        color: AppColors.primaryForest,
                        size: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Driver',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'Occupied',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.base),
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  'REAR CABIN',
                  style: AppTypography.caption.copyWith(
                    letterSpacing: 0.8,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: AppSpacing.base),

          // Rear Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSeatItem(seats[1]),
              _buildSeatItem(seats[2]),
              _buildSeatItem(seats[3]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeatItem(Map<String, dynamic> seat) {
    final String id = seat['id'];
    final String label = seat['label'];
    final bool isAvailable = seat['isAvailable'];
    final bool isSelected = selectedSeats.contains(id);

    Color bgColor = AppColors.white;
    Color borderColor = AppColors.border;
    Color textColor = AppColors.textPrimary;
    Color iconColor = AppColors.textSecondary;

    if (!isAvailable) {
      bgColor = AppColors.surfaceContainerLow.withValues(alpha: 0.8);
      borderColor = AppColors.border.withValues(alpha: 0.6);
      textColor = AppColors.textSecondary.withValues(alpha: 0.5);
      iconColor = AppColors.textSecondary.withValues(alpha: 0.4);
    } else if (isSelected) {
      bgColor = AppColors.softForest;
      borderColor = AppColors.primaryForest;
      textColor = AppColors.primaryForest;
      iconColor = AppColors.primaryForest;
    }

    return Semantics(
      label: '$label, seat $id, ${isAvailable ? (isSelected ? 'selected' : 'available') : 'occupied'}',
      button: isAvailable,
      child: GestureDetector(
        onTap: isAvailable
            ? () {
                final newSelected = List<String>.from(selectedSeats);
                if (isSelected) {
                  newSelected.remove(id);
                } else {
                  newSelected.add(id);
                }
                onSeatsChanged(newSelected);
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryForest.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.airline_seat_recline_normal_rounded,
                color: iconColor,
                size: 24,
              ),
              const SizedBox(height: 3),
              Text(
                id,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 13,
                ),
              ),
              Text(
                isAvailable ? (isSelected ? 'Picked' : 'Open') : 'Booked',
                style: AppTypography.caption.copyWith(
                  color: isSelected
                      ? AppColors.primaryForest
                      : (isAvailable
                          ? AppColors.textSecondary
                          : AppColors.textSecondary.withValues(alpha: 0.5)),
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
