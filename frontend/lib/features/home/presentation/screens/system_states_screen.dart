import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/sahyan_app_bar.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../core/widgets/sahyan_card.dart';

class SystemStatesScreen extends StatefulWidget {
  const SystemStatesScreen({super.key});

  @override
  State<SystemStatesScreen> createState() => _SystemStatesScreenState();
}

class _SystemStatesScreenState extends State<SystemStatesScreen> {
  int _selectedStateIndex = 0;

  final List<String> _states = [
    'Empty Results',
    'No Internet / Offline',
    'Driver Cancelled',
    'Permission Denied',
    'Payment Pending',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: const SahyanAppBar(
        title: 'System & Edge States',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // State Selector Tab Bar
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.containerMargin,
                ),
                itemCount: _states.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final isSelected = _selectedStateIndex == index;
                  return InkWell(
                    onTap: () => setState(() => _selectedStateIndex = index),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryForest
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryForest
                              : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _states[index],
                        style: AppTypography.caption.copyWith(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Main State View Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.containerMargin,
                  vertical: AppSpacing.sm,
                ),
                child: _buildCurrentStateView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStateView() {
    switch (_selectedStateIndex) {
      case 0:
        return _buildEmptyResultsState();
      case 1:
        return _buildOfflineState();
      case 2:
        return _buildDriverCancelledState();
      case 3:
        return _buildPermissionDeniedState();
      case 4:
        return _buildPaymentPendingState();
      default:
        return _buildEmptyResultsState();
    }
  }

  // 1. Empty Results State
  Widget _buildEmptyResultsState() {
    return SahyanCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.softForest,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.primaryForest,
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.warmBackground,
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: Text(
              'Corridor Availability: 0',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No Scheduled Rides on this Corridor',
            style: AppTypography.screenTitle.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No hosts are currently travelling from Rajkot to Vadodara on this date. Post a route request or explore nearby corridor departures.',
            style: AppTypography.secondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warmBackground,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.alt_route_rounded,
                  color: AppColors.primaryForest,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alternative Corridor Suggestion',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '3 carpools departing Anand Expressway junction',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SahyanButton(
            text: 'Notify Me When Ride is Posted',
            icon: Icons.notifications_active_outlined,
            isFullWidth: true,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Corridor alert notification configured'),
                  backgroundColor: AppColors.primaryForest,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          SahyanButton(
            text: 'Post a Route Request',
            variant: SahyanButtonVariant.outline,
            icon: Icons.add_circle_outline_rounded,
            isFullWidth: true,
            onPressed: () => context.go('/offer-ride'),
          ),
        ],
      ),
    );
  }

  // 2. Offline Telemetry Mode
  Widget _buildOfflineState() {
    return SahyanCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.textSecondary,
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.warmBackground,
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: Text(
              'Offline Telemetry Mode',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'You are Offline',
            style: AppTypography.screenTitle.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Live telemetry paused. Cached corridor maps and your active boarding PIN remain securely accessible without signal.',
            style: AppTypography.secondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warmBackground,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.pin_rounded,
                      color: AppColors.primaryForest,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Boarding PIN',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '4821',
                  style: AppTypography.screenTitle.copyWith(
                    color: AppColors.primaryForest,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SahyanButton(
            text: 'Retry Connection',
            icon: Icons.refresh_rounded,
            isFullWidth: true,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Checking network connectivity...'),
                  backgroundColor: AppColors.primaryForest,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 3. Driver Cancelled State
  Widget _buildDriverCancelledState() {
    return SahyanCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.softForest,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cancel_outlined,
              color: AppColors.mutedRust,
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.softForest,
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: Text(
              'Instant Escrow Reversal',
              style: AppTypography.caption.copyWith(
                color: AppColors.primaryForest,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Ride Cancelled by Driver',
            style: AppTypography.screenTitle.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'The driver encountered an unexpected mechanical delay. 100% of your ₹350 contribution has been refunded instantly via UPI.',
            style: AppTypography.secondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warmBackground,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Refund Method', style: AppTypography.caption),
                Text(
                  'UPI · ₹350.00 (Credited)',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryForest,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SahyanButton(
            text: 'Find Alternative Ride (3 available)',
            icon: Icons.directions_car_rounded,
            isFullWidth: true,
            onPressed: () => context.go('/search-results'),
          ),
        ],
      ),
    );
  }

  // 4. Permission Denied State
  Widget _buildPermissionDeniedState() {
    return SahyanCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.softForest,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_disabled_rounded,
              color: AppColors.mutedRust,
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.warmBackground,
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: Text(
              'System Permission Required',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Corridor Geolocation Access',
            style: AppTypography.screenTitle.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Sahyan needs high-precision location to coordinate highway boarding points and corridor navigation safely.',
            style: AppTypography.secondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          SahyanButton(
            text: 'Enable Device GPS',
            icon: Icons.my_location_rounded,
            isFullWidth: true,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Requesting device location permission...'),
                  backgroundColor: AppColors.primaryForest,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 5. Payment Pending State
  Widget _buildPaymentPendingState() {
    return SahyanCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.softForest,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: AppColors.mutedBrass,
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.warmBackground,
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: Text(
              'Awaiting Bank Webhook',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Payment Authorization Pending',
            style: AppTypography.screenTitle.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your payment of ₹350 is being processed by your bank. We will update the host automatically once confirmed.',
            style: AppTypography.secondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warmBackground,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transaction ID', style: AppTypography.caption),
                Text(
                  'TXN-SHYN-9941',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryForest,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SahyanButton(
            text: 'Check Payment Status',
            icon: Icons.sync_rounded,
            isFullWidth: true,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Checking bank webhook status...'),
                  backgroundColor: AppColors.primaryForest,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
