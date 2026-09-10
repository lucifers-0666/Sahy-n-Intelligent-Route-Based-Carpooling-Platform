import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/sahyan_app_bar.dart';
import '../../../../core/widgets/sahyan_avatar.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../core/widgets/sahyan_card.dart';
import '../../../../shared/models/ride_model.dart';
import '../../../rides/presentation/rides_provider.dart';

class DriverActiveRideScreen extends ConsumerStatefulWidget {
  final RideModel? initialRide;

  const DriverActiveRideScreen({super.key, this.initialRide});

  @override
  ConsumerState<DriverActiveRideScreen> createState() =>
      _DriverActiveRideScreenState();
}

class _DriverActiveRideScreenState
    extends ConsumerState<DriverActiveRideScreen> {
  late RideModel? _ride;
  final TextEditingController _pinController = TextEditingController();
  final Set<String> _verifiedPassengers = {'P1'};
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _ride = widget.initialRide;
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verifyPassengerPin(String passengerId, String expectedPin) {
    if (_pinController.text.trim() == expectedPin) {
      setState(() {
        _verifiedPassengers.add(passengerId);
        _pinController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passenger boarding PIN verified successfully!'),
          backgroundColor: AppColors.primaryForest,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid boarding PIN. Please check with passenger.'),
          backgroundColor: AppColors.mutedRust,
        ),
      );
    }
  }

  Future<void> _handleCompleteJourney() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        title: Text(
          'Complete Journey?',
          style: AppTypography.sectionHeader,
        ),
        content: Text(
          'Confirm that all passengers have arrived safely at their destinations. Escrow payout will be released to your earnings account.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryForest,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Complete Trip', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCompleting = true);
    if (_ride != null) {
      await ref
          .read(myRidesProvider.notifier)
          .completeTrip(_ride!.id);
    }

    if (!mounted) return;
    setState(() => _isCompleting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Journey completed! Escrow earnings updated.'),
        backgroundColor: AppColors.primaryForest,
      ),
    );

    context.go('/journey-completed');
  }

  @override
  Widget build(BuildContext context) {
    final originName = _ride?.origin.name ?? 'Ahmedabad Highway Junction';
    final destName = _ride?.destination.name ?? 'Rajkot Central Toll';
    final totalEscrow = (_ride?.contributionPerSeat ?? 350) * 2;

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: SahyanAppBar(
        title: 'Driver Navigation HUD',
        subtitle: 'Live Corridor Telemetry',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.shield_outlined,
              color: AppColors.primaryForest,
            ),
            tooltip: 'Safety Hub',
            onPressed: () => context.push('/safety-center'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerMargin,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live GPS Status Strip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryForest,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'NH 47 Express Corridor',
                              style: AppTypography.cardTitle.copyWith(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softForest,
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.navigation_rounded,
                            size: 12,
                            color: AppColors.primaryForest,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Live GPS Active',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Turn Guidance HUD Card
              SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryForest,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: const Icon(
                        Icons.turn_slight_right_rounded,
                        color: AppColors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '2.4 km',
                                  style: AppTypography.screenTitle.copyWith(
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text('ahead', style: AppTypography.caption),
                            ],
                          ),
                          Text(
                            'Stay on NH 47 towards Chotila / Rajkot',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.volume_up_rounded,
                        color: AppColors.primaryForest,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Audio navigation active'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Telemetry Bento Grid
              Row(
                children: [
                  Expanded(
                    child: SahyanCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.speed_rounded,
                                size: 16,
                                color: AppColors.primaryForest,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Current Speed',
                                  style: AppTypography.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '78 km/h',
                            style: AppTypography.screenTitle.copyWith(
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            'Optimal cruise speed',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryForest,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SahyanCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: AppColors.mutedBrass,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Estimated Arrival',
                                  style: AppTypography.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '10:30 AM',
                            style: AppTypography.screenTitle.copyWith(
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            '42m remaining',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Corridor Progress Deck
              SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '$originName to $destName',
                            style: AppTypography.cardTitle.copyWith(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                            'Smooth Traffic',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    LinearProgressIndicator(
                      value: 0.65,
                      backgroundColor: AppColors.warmBackground,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primaryForest,
                      ),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '148 km completed',
                            style: AppTypography.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '72 km remaining',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Passenger Manifest & Check-in Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Passenger Manifest & Boarding PINs',
                      style: AppTypography.sectionHeader.copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                      'Escrow: ₹${totalEscrow.toStringAsFixed(0)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryForest,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Passenger 1 (Already Boarded)
              SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const SahyanAvatar(name: 'Rohit Sharma', radius: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rohit Sharma',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('Seat A1 · Window', style: AppTypography.caption),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softForest,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: AppColors.primaryForest,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Boarded',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primaryForest,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Passenger 2 (Verification Needed)
              SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SahyanAvatar(name: 'Priya Mehta', radius: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Priya Mehta',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('Seat A2 · Mid', style: AppTypography.caption),
                            ],
                          ),
                        ),
                        if (_verifiedPassengers.contains('P2'))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softForest,
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: AppColors.primaryForest,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Boarded',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primaryForest,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            'Pending PIN',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.mutedRust,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    if (!_verifiedPassengers.contains('P2')) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: TextField(
                                controller: _pinController,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: 'Enter 4-digit PIN (Try 4821)',
                                  hintStyle: AppTypography.caption,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadii.sm,
                                    ),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryForest,
                              minimumSize: const Size(80, 38),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.sm,
                                ),
                              ),
                            ),
                            onPressed: () => _verifyPassengerPin('P2', '4821'),
                            child: const Text(
                              'Verify',
                              style: TextStyle(color: AppColors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Complete Journey Action
              SahyanButton(
                text: 'Complete Journey',
                icon: Icons.check_circle_rounded,
                isLoading: _isCompleting,
                isFullWidth: true,
                onPressed: _handleCompleteJourney,
              ),

              const SizedBox(height: AppSpacing.sm),

              SahyanButton(
                text: 'Emergency Assistance',
                variant: SahyanButtonVariant.destructive,
                icon: Icons.emergency_rounded,
                isFullWidth: true,
                onPressed: () => context.push('/safety-center'),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
