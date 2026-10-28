import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import '../../../../core/network/socket_client.dart';
import '../../../../core/services/driver_location_service.dart';
import '../../../../shared/models/ride_model.dart';
import '../../../bookings/domain/booking_model.dart';
import '../../../bookings/presentation/bookings_provider.dart';
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
  final Map<String, TextEditingController> _pinControllers = {};
  final Set<String> _verifiedPassengers = {'P1'};
  bool _isCompleting = false;

  TextEditingController _getPinController(String key) {
    return _pinControllers.putIfAbsent(key, () => TextEditingController());
  }

  StreamSubscription<bool>? _gpsInterruptedSub;
  bool _isShowingGpsAlert = false;

  @override
  void initState() {
    super.initState();
    _ride = widget.initialRide;
    _startGpsStream();
    _listenToGpsInterruption();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_ride != null && _ride!.id.isNotEmpty) {
        ref.read(driverRequestsNotifierProvider.notifier).fetchDriverRequests(
          status: 'accepted',
          rideId: _ride!.id,
        );
      }
    });
  }

  void _listenToGpsInterruption() {
    _gpsInterruptedSub = DriverLocationService.instance.gpsInterruptedStream
        .listen((isInterrupted) {
      if (!mounted) return;
      if (isInterrupted && !_isShowingGpsAlert) {
        _isShowingGpsAlert = true;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) {
            return PopScope(
              canPop: false,
              child: AlertDialog(
                backgroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                icon: const Icon(
                  Icons.location_off_rounded,
                  color: AppColors.error,
                  size: 48,
                ),
                title: Text(
                  'Safety Alert',
                  style: AppTypography.sectionHeader.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                content: Text(
                  'Safety Alert: GPS is required during active shared trips. Re-enable location to resume.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ).then((_) {
          _isShowingGpsAlert = false;
        });
      } else if (!isInterrupted && _isShowingGpsAlert) {
        _isShowingGpsAlert = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  /// Start GPS streaming if on a native platform with a valid ride ID.
  Future<void> _startGpsStream() async {
    final rideId = _ride?.id;
    final isRunningInTest = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('Test');
    if (rideId == null || kIsWeb || isRunningInTest) return;

    try {
      final socketClient = SocketClient.instance;
      socketClient.connect();
      // 'driver-id' would normally come from auth provider; using placeholder
      socketClient.joinRideRoom(rideId, 'driver-self', 'driver');

      final started = await DriverLocationService.instance.startStreaming(
        rideId,
      );
      debugPrint('[DriverActiveRide] GPS streaming: $started');
    } catch (e) {
      debugPrint('[DriverActiveRide] GPS start error: $e');
    }
  }

  /// Stop GPS streaming and leave the socket room.
  Future<void> _stopGpsStream() async {
    final rideId = _ride?.id;
    await DriverLocationService.instance.stopStreaming();
    if (rideId != null && !kIsWeb) {
      SocketClient.instance.leaveRideRoom(rideId);
    }
    debugPrint('[DriverActiveRide] GPS streaming stopped.');
  }

  @override
  void dispose() {
    _gpsInterruptedSub?.cancel();
    for (final controller in _pinControllers.values) {
      controller.dispose();
    }
    _pinController.dispose();
    _stopGpsStream();
    super.dispose();
  }

  Future<void> _verifyPassengerPin({
    required String bookingOrPassengerId,
    String? expectedPin,
    bool isRemoteBooking = false,
  }) async {
    final controller = isRemoteBooking
        ? _getPinController(bookingOrPassengerId)
        : _pinController;
    final enteredPin = controller.text.trim();

    if (enteredPin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 4-digit boarding PIN.'),
          backgroundColor: AppColors.mutedRust,
        ),
      );
      return;
    }

    if (isRemoteBooking) {
      try {
        final success = await ref
            .read(driverRequestsNotifierProvider.notifier)
            .verifyBoardingPin(bookingOrPassengerId, enteredPin);

        if (success) {
          if (!mounted) return;
          setState(() {
            _verifiedPassengers.add(bookingOrPassengerId);
            controller.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Passenger boarding PIN verified successfully!'),
              backgroundColor: AppColors.primaryForest,
            ),
          );
          return;
        }
      } catch (e) {
        // Fall back to matching expected security PIN if network error occurs
        if (expectedPin != null && enteredPin == expectedPin) {
          if (!mounted) return;
          setState(() {
            _verifiedPassengers.add(bookingOrPassengerId);
            controller.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Boarding verified via passenger PIN.'),
              backgroundColor: AppColors.primaryForest,
            ),
          );
          return;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PIN Verification Failed: $e'),
              backgroundColor: AppColors.mutedRust,
            ),
          );
        }
        return;
      }
    }

    // Direct local / fallback check
    if (expectedPin != null && enteredPin == expectedPin) {
      if (!mounted) return;
      setState(() {
        _verifiedPassengers.add(bookingOrPassengerId);
        controller.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passenger boarding PIN verified successfully!'),
          backgroundColor: AppColors.primaryForest,
        ),
      );
    } else {
      if (!mounted) return;
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
        title: Text('Complete Journey?', style: AppTypography.sectionHeader),
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
            child: const Text(
              'Complete Trip',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCompleting = true);

    // Stop GPS stream and leave room before completing trip
    await _stopGpsStream();

    if (_ride != null) {
      await ref.read(myRidesProvider.notifier).completeTrip(_ride!.id);
    }

    if (!mounted) return;
    setState(() => _isCompleting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Journey completed! Escrow earnings updated.'),
        backgroundColor: AppColors.primaryForest,
      ),
    );

    context.go('/journey-completed', extra: _ride);
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
                              style: AppTypography.cardTitle.copyWith(
                                fontSize: 13,
                              ),
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
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 14,
                            ),
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

              // Passenger Manifest & Dynamic PIN Verification
              ..._buildPassengerManifest(ref),

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

  List<Widget> _buildPassengerManifest(WidgetRef ref) {
    final driverRequestsAsync = ref.watch(driverRequestsNotifierProvider);

    return driverRequestsAsync.maybeWhen(
      data: (bookings) {
        final acceptedBookings = bookings.where((b) {
          if (_ride != null && _ride!.id.isNotEmpty) {
            return b.rideId == _ride!.id &&
                (b.status == BookingStatus.accepted ||
                    b.status == BookingStatus.completed);
          }
          return b.status == BookingStatus.accepted;
        }).toList();

        if (acceptedBookings.isNotEmpty) {
          return acceptedBookings.map((booking) {
            final isBoarded = booking.boardedAt != null ||
                _verifiedPassengers.contains(booking.id);
            final controller = _getPinController(booking.id);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SahyanCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SahyanAvatar(name: booking.passengerName, radius: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.passengerName,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${booking.requestedSeats} Seat(s) · Pickup: ${booking.pickup.name}',
                                style: AppTypography.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isBoarded)
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
                    if (!isBoarded) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              style: AppTypography.bodyMedium,
                              decoration: InputDecoration(
                                isDense: true,
                                counterText: '',
                                hintText: 'Enter 4-digit boarding PIN',
                                hintStyle: AppTypography.caption,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 10,
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
                          const SizedBox(width: AppSpacing.sm),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryForest,
                              minimumSize: const Size(80, 42),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.sm,
                                ),
                              ),
                            ),
                            onPressed: () => _verifyPassengerPin(
                              bookingOrPassengerId: booking.id,
                              expectedPin: booking.securityPin,
                              isRemoteBooking: true,
                            ),
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
            );
          }).toList();
        }

        return _buildDefaultPassengerManifest();
      },
      orElse: () => _buildDefaultPassengerManifest(),
    );
  }

  List<Widget> _buildDefaultPassengerManifest() {
    return [
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
                    child: TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      style: AppTypography.bodyMedium,
                      decoration: InputDecoration(
                        isDense: true,
                        counterText: '',
                        hintText: 'Enter 4-digit boarding PIN',
                        hintStyle: AppTypography.caption,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          borderSide: const BorderSide(
                            color: AppColors.border,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryForest,
                      minimumSize: const Size(80, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                    ),
                    onPressed: () => _verifyPassengerPin(
                      bookingOrPassengerId: 'P2',
                      expectedPin: '4821',
                    ),
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
    ];
  }
}
