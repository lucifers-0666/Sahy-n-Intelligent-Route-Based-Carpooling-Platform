import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_spacing.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/sahyan_app_bar.dart';
import 'package:sahyan/core/widgets/sahyan_button.dart';
import 'package:sahyan/core/widgets/sahyan_card.dart';
import 'package:sahyan/features/bookings/domain/booking_model.dart';
import 'package:sahyan/shared/models/ride_model.dart';

class TripReceiptScreen extends StatelessWidget {
  final BookingModel? booking;
  final RideModel? ride;

  const TripReceiptScreen({super.key, this.booking, this.ride});

  @override
  Widget build(BuildContext context) {
    final String receiptId = booking?.id ?? ride?.id ?? 'RCP-${DateTime.now().millisecondsSinceEpoch}';
    final String shortId = receiptId.length > 8 ? receiptId.substring(receiptId.length - 8).toUpperCase() : receiptId;
    final DateTime tripDate = booking?.createdAt ?? ride?.dateTime ?? DateTime.now();
    final String formattedDate = DateFormat('EEE, dd MMM yyyy, hh:mm a').format(tripDate);

    final String origin = booking?.pickup.name ?? ride?.origin.name ?? 'Ahmedabad';
    final String destination = booking?.drop.name ?? ride?.destination.name ?? 'Vadodara';
    final String driverName = booking?.ride?.driverName ?? ride?.driverName ?? 'Verified Driver';
    final String vehicleInfo = booking?.ride?.vehicle.fullName ?? ride?.vehicle.fullName ?? 'Registered Vehicle';
    final String regNumber = booking?.ride?.vehicle.registrationNumber ?? ride?.vehicle.registrationNumber ?? 'GJ-01-XX-0000';
    final int seats = booking?.requestedSeats ?? 1;
    final double perSeat = booking?.contributionPerSeat ?? ride?.contributionPerSeat ?? 250.0;
    final double total = booking?.totalContribution ?? (seats * perSeat);
    final double co2Saved = (seats * 3.2);

    final receiptSummaryText = '''
SAHYĀN PEER COST-SHARING STATEMENT
Receipt ID: #$shortId
Date: $formattedDate
Route: $origin -> $destination
Driver: $driverName
Vehicle: $vehicleInfo ($regNumber)
Seats Reserved: $seats
Contribution per Seat: ₹${perSeat.toStringAsFixed(0)}
Total Fuel Split: ₹${total.toStringAsFixed(0)}
CO2 Emissions Prevented: ${co2Saved.toStringAsFixed(1)} kg

Non-Commercial Peer Carpool Declaration:
Operating under private vehicle fuel cost-sharing principles in compliance with private vehicle pooling guidelines.
''';

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: const SahyanAppBar(
        title: 'Trip Cost-Share Receipt',
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Receipt Card
              SahyanCard(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Brand Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SAHYĀN',
                              style: AppTypography.headingSmall.copyWith(
                                color: AppColors.primaryForest,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              'Peer Fuel Cost-Sharing Statement',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.softForest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'PAID / SETTLED',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: AppSpacing.sm),

                    // Metadata
                    _buildRow('Statement Number', '#$shortId', isMono: true),
                    _buildRow('Journey Date', formattedDate),
                    _buildRow('Corridor Route', '$origin -> $destination'),
                    _buildRow('Driver Partner', driverName),
                    _buildRow('Vehicle Details', '$vehicleInfo ($regNumber)'),

                    const SizedBox(height: AppSpacing.sm),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: AppSpacing.sm),

                    // Cost Share Breakdown
                    Text(
                      'CONTRIBUTION BREAKDOWN',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildRow('Reserved Capacity', '$seats Seat${seats > 1 ? 's' : ''}'),
                    _buildRow('Fuel Share per Seat', '₹${perSeat.toStringAsFixed(0)}'),
                    _buildRow('Platform Commission', '₹0 (Zero Markup)'),

                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.softForest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Fuel Cost Split',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryForest,
                            ),
                          ),
                          Text(
                            '₹${total.toStringAsFixed(0)}',
                            style: AppTypography.headingSmall.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryForest,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Eco Impact
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.warmBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.eco_rounded,
                            color: AppColors.primaryForest,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Prevented approx. ${co2Saved.toStringAsFixed(1)} kg of CO2 by sharing this ride.',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: AppSpacing.sm),

                    // Legal Non-Commercial Declaration
                    Text(
                      'LEGAL & REGULATORY DECLARATION',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Sahyān operates strictly under non-commercial peer-to-peer fuel cost compensation rules. Vehicle owners cannot earn a commercial profit; all payments represent shared fuel and vehicle operating costs permitted under private vehicle pooling guidelines.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Action Buttons
              SahyanButton(
                text: 'Copy Statement to Clipboard',
                icon: Icons.copy_rounded,
                isFullWidth: true,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: receiptSummaryText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cost-share statement copied to clipboard.'),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.border),
                  backgroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Booking Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: isMono ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }
}
