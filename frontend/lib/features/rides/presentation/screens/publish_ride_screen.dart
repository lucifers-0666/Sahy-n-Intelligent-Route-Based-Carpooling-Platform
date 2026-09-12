import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/core/theme/app_theme.dart';
import 'package:sahyan/core/widgets/vehicles/vehicle_icon.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_type.dart';
import 'package:sahyan/shared/widgets/bento/bento_widgets.dart';

class PublishRideScreen extends ConsumerStatefulWidget {
  const PublishRideScreen({super.key});

  @override
  ConsumerState<PublishRideScreen> createState() => _PublishRideScreenState();
}

class _PublishRideScreenState extends ConsumerState<PublishRideScreen> {
  final TextEditingController _originController =
      TextEditingController(text: 'SG Highway, Ahmedabad');
  final TextEditingController _destinationController =
      TextEditingController(text: 'Kalawad Road, Rajkot');

  int _seats = 2;
  bool _middleSeatEmpty = true;
  double _farePerSeat = 350.0;
  bool _isPublishing = false;

  final List<String> _stopovers = const ['Limbdi Toll Plaza', 'Chotila Jn'];

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _onSeatsChanged(int newCount) {
    setState(() {
      _seats = newCount;
    });
  }

  double get _maxRecovery => _seats * _farePerSeat;

  Future<void> _handlePublish() async {
    setState(() => _isPublishing = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isPublishing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: SahyanColors.primaryDark,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: SahyanColors.primaryMint),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Journey published via NH47 at ₹${_farePerSeat.toStringAsFixed(0)} / seat',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/my-bookings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SahyanColors.canvas,
      appBar: AppBar(
        backgroundColor: SahyanColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: SahyanColors.textMain),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Offer a Ride',
          style: TextStyle(
            color: SahyanColors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: SahyanColors.textMuted),
            onPressed: () => context.go('/home'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: SahyanColors.border, height: 0.8),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // Step Progress Header
                  _buildStepHeader(),
                  const SizedBox(height: 14),

                  // Route Minimap Card
                  _buildRouteMinimapCard(),
                  const SizedBox(height: 14),

                  // Pick-up / Drop-off Nodes Card
                  _buildPickupDropoffNodesCard(),
                  const SizedBox(height: 14),

                  // Vehicle Garage Card
                  _buildVehicleGarageCard(),
                  const SizedBox(height: 14),

                  // Seat Stepper & Middle-Seat Policy Card
                  _buildSeatAndPolicyCard(),
                  const SizedBox(height: 14),

                  // AI Dynamic Fare Recommendation Card
                  _buildFareRecommendationCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader() {
    return BentoContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'STEP 2 OF 4: Route & Schedule',
                style: TextStyle(
                  color: SahyanColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SahyanColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '50% Complete',
                  style: TextStyle(
                    color: SahyanColors.primaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.5,
              backgroundColor: SahyanColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                SahyanColors.primaryMint,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              PillTag(
                label: 'via NH47 · 219 km · 3h 40m · Max 5 km Detour',
                icon: Icons.alt_route,
                variant: PillTagVariant.mint,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteMinimapCard() {
    return BentoContainer(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simulated Minimap Area
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: SahyanColors.primaryLight.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Stack(
              children: [
                // Stylized map grid lines
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MinimapGridPainter(),
                  ),
                ),
                // Route polyline representation
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MinimapRoutePainter(),
                  ),
                ),
                // Top tag: Live Telematics
                Positioned(
                  top: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: SahyanColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: SahyanColors.border, width: 0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.radar,
                          size: 13,
                          color: SahyanColors.primaryMint,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Live Route Mesh Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: SahyanColors.textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: SahyanColors.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Interactive Route View',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: SahyanColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Stopovers row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Planned Highway Stopovers',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: SahyanColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _stopovers
                      .map(
                        (stop) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: SahyanColors.canvas,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: SahyanColors.border,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.pin_drop,
                                size: 12,
                                color: SahyanColors.bluePolyline,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                stop,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: SahyanColors.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupDropoffNodesCard() {
    return BentoContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route Nodes & Detour Boundaries',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: SahyanColors.textMain,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visual connection column
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SahyanColors.primaryDark,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 52,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          SahyanColors.primaryDark,
                          SahyanColors.primaryMint,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SahyanColors.primaryMint,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Fields
              Expanded(
                child: Column(
                  children: [
                    TextField(
                      controller: _originController,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SahyanColors.textMain,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Origin Pickup Node',
                        labelStyle: const TextStyle(
                          color: SahyanColors.textMuted,
                          fontSize: 12,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: SahyanColors.canvas,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: SahyanColors.border,
                            width: 0.8,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: SahyanColors.border,
                            width: 0.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _destinationController,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SahyanColors.textMain,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Destination Drop-off Node',
                        labelStyle: const TextStyle(
                          color: SahyanColors.textMuted,
                          fontSize: 12,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: SahyanColors.canvas,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: SahyanColors.border,
                            width: 0.8,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: SahyanColors.border,
                            width: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleGarageCard() {
    return BentoContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Designated Fleet Vehicle',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: SahyanColors.textMain,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SahyanColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: SahyanColors.primaryMint,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Verified Garage',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: SahyanColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SahyanColors.canvas,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SahyanColors.border, width: 0.8),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: SahyanColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SahyanColors.border, width: 0.8),
                  ),
                  child: const Center(
                    child: VehicleIcon(
                      type: VehicleType.sedan,
                      width: 40,
                      height: 26,
                      color: SahyanColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Honda City ZX',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: SahyanColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: SahyanColors.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: SahyanColors.border,
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              'GJ 01 AB 1234',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                color: SahyanColors.textMain,
                              ),
                            ),
                          ),
                          const Text(
                            '• 4 Seats',
                            style: TextStyle(
                              fontSize: 12,
                              color: SahyanColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    minimumSize: const Size(48, 36),
                  ),
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: SahyanColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatAndPolicyCard() {
    return BentoContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Passenger Seats',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: SahyanColors.textMain,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Max capacity: 3 seats',
                      style: TextStyle(
                        fontSize: 12,
                        color: SahyanColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StepCounter(
                value: _seats,
                min: 1,
                max: 3,
                suffix: 'Seats',
                onChanged: _onSeatsChanged,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: SahyanColors.border, height: 1, thickness: 0.8),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Middle-Seat Comfort Policy',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SahyanColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Leave middle seat empty for a premium luxury experience',
                      style: TextStyle(
                        fontSize: 11,
                        color: SahyanColors.textMuted.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _middleSeatEmpty,
                activeTrackColor: SahyanColors.primaryMint,
                activeThumbColor: SahyanColors.surface,
                onChanged: (val) {
                  setState(() {
                    _middleSeatEmpty = val;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFareRecommendationCard() {
    return BentoContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: SahyanColors.primaryMint,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'AI Dynamic Fare',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: SahyanColors.textMain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SahyanColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Fair Price Index',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: SahyanColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SahyanColors.canvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SahyanColors.border, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contribution / Seat',
                        style: TextStyle(
                          fontSize: 11,
                          color: SahyanColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_farePerSeat.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: SahyanColors.textMain,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Recommended for NH47',
                        style: TextStyle(
                          fontSize: 10,
                          color: SahyanColors.primaryMint,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SahyanColors.canvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SahyanColors.border, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Max Fuel Recovery',
                        style: TextStyle(
                          fontSize: 11,
                          color: SahyanColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${_maxRecovery.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: SahyanColors.primaryDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_seats seats × ₹${_farePerSeat.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: SahyanColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: SahyanColors.primaryDark,
              inactiveTrackColor: SahyanColors.border,
              thumbColor: SahyanColors.primaryDark,
              trackHeight: 4,
            ),
            child: Slider(
              value: _farePerSeat,
              min: 250,
              max: 600,
              divisions: 7,
              label: '₹${_farePerSeat.toStringAsFixed(0)}',
              onChanged: (val) {
                setState(() {
                  _farePerSeat = val;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: SahyanColors.surface,
        border: const Border(
          top: BorderSide(color: SahyanColors.border, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: SahyanColors.textMain.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ElevatedButton(
          onPressed: _isPublishing ? null : _handlePublish,
          style: ElevatedButton.styleFrom(
            backgroundColor: SahyanColors.primaryDark,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isPublishing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Publish Shared Journey',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
        ),
      ),
    );
  }
}

class _MinimapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SahyanColors.border.withValues(alpha: 0.6)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MinimapRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.2,
      size.width * 0.85,
      size.height * 0.35,
    );

    final linePaint = Paint()
      ..color = SahyanColors.bluePolyline
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = SahyanColors.primaryDark;
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.8), 5, dotPaint);

    final destPaint = Paint()..color = SahyanColors.primaryMint;
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.35),
      5,
      destPaint,
    );

    // Stopover dots
    final stopPaint = Paint()..color = SahyanColors.goldStar;
    canvas.drawCircle(Offset(size.width * 0.45, size.height * 0.4), 4, stopPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
