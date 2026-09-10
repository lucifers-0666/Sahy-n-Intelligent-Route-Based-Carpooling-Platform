import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/design_system.dart';

class LiveRideTrackingScreen extends StatelessWidget {
  final String? originName;
  final String? destinationName;
  final String? driverName;
  final String? vehicleInfo;

  const LiveRideTrackingScreen({
    super.key,
    this.originName,
    this.destinationName,
    this.driverName,
    this.vehicleInfo,
  });

  @override
  Widget build(BuildContext context) {
    final origin = originName ?? 'Iscon Cross Roads, Ahmedabad';
    final destination = destinationName ?? 'GIFT Tower 1, Gandhinagar';
    final driver = driverName ?? 'Karan Patel';
    final vehicle = vehicleInfo ?? 'Hyundai Creta • GJ-01-AB-1234';

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: SahyanAppBar(
        title: 'Live Tracking',
        subtitle: 'Route progress and arrival estimate',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.shield_outlined,
              color: AppColors.primaryForest,
              size: 22,
            ),
            tooltip: 'Safety Center',
            onPressed: () => context.push('/trip-safety'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Map Presentation Area
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                color: const Color(0xFFE5EBE7),
                child: Stack(
                  children: [
                    // Stylized Route Grid Canvas
                    CustomPaint(
                      size: Size.infinite,
                      painter: _RouteMapPainter(),
                    ),

                    // ETA Floating Card at top
                    Positioned(
                      top: AppSpacing.md,
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.deepForest,
                          borderRadius: BorderRadius.circular(AppRadii.full),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.near_me_rounded,
                                  color: AppColors.softForest,
                                  size: 18,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'ETA: 24 mins (18.4 km)',
                                  style: AppTypography.cardTitle.copyWith(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.softForest,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.full,
                                ),
                              ),
                              child: Text(
                                'ON SCHEDULE',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primaryForest,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // GPS Signal Status pill
                    Positioned(
                      bottom: AppSpacing.md,
                      left: AppSpacing.md,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2E7D32),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Verified Route Geometry',
                              style: AppTypography.caption.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Tracking Details Sheet
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadii.lg),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Driver Overview
                      Row(
                        children: [
                          SahyanAvatar(name: driver, radius: 22),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driver,
                                  style: AppTypography.cardTitle.copyWith(
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  vehicle,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.phone_outlined,
                              color: AppColors.primaryForest,
                            ),
                            tooltip: 'Call Driver',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Contacting driver...'),
                                  backgroundColor: AppColors.deepForest,
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const Divider(
                        height: AppSpacing.lg,
                        color: AppColors.border,
                      ),

                      // Waypoints
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryForest,
                                    width: 2.5,
                                  ),
                                  color: Colors.white,
                                ),
                              ),
                              Container(
                                width: 2,
                                height: 28,
                                color: AppColors.border,
                              ),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryForest,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  origin,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  destination,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: SahyanButton(
                              text: 'Share Trip',
                              icon: Icons.share_outlined,
                              variant: SahyanButtonVariant.outline,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Live link copied to clipboard.',
                                    ),
                                    backgroundColor: AppColors.deepForest,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: SahyanButton(
                              text: 'Safety Center',
                              icon: Icons.shield_outlined,
                              onPressed: () => context.push('/trip-safety'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFE9F0EC);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final roadPaint = Paint()
      ..color = const Color(0xFFD3E0D8)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final routePaint = Paint()
      ..color = AppColors.primaryForest
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.25, size.height * 0.8);
    path.cubicTo(
      size.width * 0.35,
      size.height * 0.55,
      size.width * 0.65,
      size.height * 0.5,
      size.width * 0.75,
      size.height * 0.25,
    );

    canvas.drawPath(path, roadPaint);
    canvas.drawPath(path, routePaint);

    // Origin Marker
    final originDot = Paint()..color = Colors.white;
    final originRing = Paint()
      ..color = AppColors.primaryForest
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final originOffset = Offset(size.width * 0.25, size.height * 0.8);
    canvas.drawCircle(originOffset, 8, originDot);
    canvas.drawCircle(originOffset, 8, originRing);

    // Destination Marker
    final destDot = Paint()..color = AppColors.primaryForest;
    final destOffset = Offset(size.width * 0.75, size.height * 0.25);
    canvas.drawCircle(destOffset, 9, destDot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
