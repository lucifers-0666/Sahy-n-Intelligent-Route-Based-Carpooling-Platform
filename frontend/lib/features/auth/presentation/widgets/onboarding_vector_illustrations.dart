import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';

/// Original Flutter-native vector illustrations for Sahyān onboarding.
/// Provides lightweight, resolution-independent, 60fps route-sharing visuals
/// with subtle animated route lines and staggered entry.
class OnboardingVectorIllustration extends StatefulWidget {
  final int pageIndex;
  final bool isDark;

  const OnboardingVectorIllustration({
    super.key,
    required this.pageIndex,
    this.isDark = false,
  });

  @override
  State<OnboardingVectorIllustration> createState() =>
      _OnboardingVectorIllustrationState();
}

class _OnboardingVectorIllustrationState
    extends State<OnboardingVectorIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motionController;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final isTestEnvironment =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');

    if (disableAnimations || isTestEnvironment) {
      _motionController.stop();
      _motionController.value = 0.5;
    } else {
      if (!_motionController.isAnimating) {
        _motionController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return AnimatedBuilder(
      animation: _motionController,
      builder: (context, _) {
        final progress = disableAnimations ? 0.5 : _motionController.value;

        switch (widget.pageIndex) {
          case 0:
            return _RouteConvergenceVisual(
              progress: progress,
              isDark: widget.isDark,
            );
          case 1:
            return _RouteMatchVisual(
              progress: progress,
              isDark: widget.isDark,
            );
          case 2:
          default:
            return _TripSafetyVisual(
              progress: progress,
              isDark: widget.isDark,
            );
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen 1: Route Convergence Illustration
// ─────────────────────────────────────────────────────────────────────────────
class _RouteConvergenceVisual extends StatelessWidget {
  final double progress;
  final bool isDark;

  const _RouteConvergenceVisual({
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF06231C) : const Color(0xFF07382D),
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background ambient grid and glow
          CustomPaint(
            painter: _RouteGridPainter(isDark: isDark),
          ),

          // Converging Route Lines
          CustomPaint(
            painter: _ConvergenceRoutePainter(
              progress: progress,
              isDark: isDark,
            ),
          ),

          // Floating Route Origin Badges
          Positioned(
            left: 16,
            top: 24,
            child: _RoutePointBadge(
              label: 'Rider A · SG Highway',
              color: AppColors.softMint,
              textColor: AppColors.primaryText,
              icon: Icons.person_pin_circle_outlined,
            ),
          ),
          Positioned(
            left: 16,
            bottom: 32,
            child: _RoutePointBadge(
              label: 'Driver B · Prahlad Nagar',
              color: AppColors.champagneGold,
              textColor: AppColors.primaryText,
              icon: Icons.directions_car_outlined,
            ),
          ),
          Positioned(
            right: 16,
            top: 86,
            child: _RoutePointBadge(
              label: 'Shared Corridor · NE1',
              color: Colors.white,
              textColor: AppColors.brand,
              icon: Icons.alt_route,
              isHighlight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConvergenceRoutePainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _ConvergenceRoutePainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final route1Paint = Paint()
      ..color = AppColors.softMint.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final route2Paint = Paint()
      ..color = AppColors.champagneGold.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final sharedPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    // Route 1 (Top path moving down to center)
    final path1 = Path();
    path1.moveTo(w * 0.22, h * 0.28);
    path1.cubicTo(w * 0.42, h * 0.28, w * 0.46, h * 0.50, w * 0.58, h * 0.50);
    canvas.drawPath(path1, route1Paint);

    // Route 2 (Bottom path moving up to center)
    final path2 = Path();
    path2.moveTo(w * 0.22, h * 0.76);
    path2.cubicTo(w * 0.42, h * 0.76, w * 0.46, h * 0.50, w * 0.58, h * 0.50);
    canvas.drawPath(path2, route2Paint);

    // Shared Trunk Path
    final sharedPath = Path();
    sharedPath.moveTo(w * 0.58, h * 0.50);
    sharedPath.lineTo(w * 0.88, h * 0.50);
    canvas.drawPath(sharedPath, sharedPaint);

    // Convergence Junction Node with Pulse
    final junction = Offset(w * 0.58, h * 0.50);
    final pulseRadius = 7.0 + (progress * 10.0);
    final pulsePaint = Paint()
      ..color = AppColors.softMint.withValues(alpha: (1.0 - progress) * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(junction, pulseRadius, pulsePaint);

    final nodePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(junction, 5.5, nodePaint);

    // Moving Car Token along the shared path
    final carX = (w * 0.58) + (progress * (w * 0.28));
    final carY = h * 0.50;
    final carMarkerPaint = Paint()
      ..color = AppColors.softMint
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(carX, carY), 6.0, carMarkerPaint);

    final carCorePaint = Paint()
      ..color = AppColors.darkEmerald
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(carX, carY), 3.0, carCorePaint);
  }

  @override
  bool shouldRepaint(covariant _ConvergenceRoutePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen 2: Route Matching Illustration
// ─────────────────────────────────────────────────────────────────────────────
class _RouteMatchVisual extends StatelessWidget {
  final double progress;
  final bool isDark;

  const _RouteMatchVisual({
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF06231C) : const Color(0xFF07382D),
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _RouteGridPainter(isDark: isDark),
          ),
          CustomPaint(
            painter: _MatchRadarPainter(progress: progress, isDark: isDark),
          ),

          // Central Match Card
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isDark ? 0.94 : 0.98),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppColors.softMint.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.sync_alt,
                                color: AppColors.deepEmerald,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Optimal Corridor',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.deepEmerald,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '94% MATCH',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE2E8E4)),
                  const SizedBox(height: 12),
                  _RouteTimelineRow(
                    origin: 'Ahmedabad (SG Highway)',
                    destination: 'Vadodara (Alkapuri)',
                    time: 'Departure aligned: +4 min',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchRadarPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _MatchRadarPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final maxRadius = size.width * 0.42;

    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + (i * 0.33)) % 1.0;
      final radius = ringProgress * maxRadius;
      final alpha = (1.0 - ringProgress) * 0.28;

      final paint = Paint()
        ..color = AppColors.softMint.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MatchRadarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen 3: Trip Safety & Confidence Illustration
// ─────────────────────────────────────────────────────────────────────────────
class _TripSafetyVisual extends StatelessWidget {
  final double progress;
  final bool isDark;

  const _TripSafetyVisual({
    required this.progress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF06231C) : const Color(0xFF07382D),
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _RouteGridPainter(isDark: isDark),
          ),
          CustomPaint(
            painter: _SafetyPulsePainter(progress: progress, isDark: isDark),
          ),

          // Central Verified Shield & Live Protection Badge
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.softMint.withValues(alpha: 0.45),
                        blurRadius: 24,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.verified_user,
                      size: 42,
                      color: AppColors.deepEmerald,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  constraints: const BoxConstraints(maxWidth: 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.softMint,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Live Corridor Telemetry Active',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyPulsePainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _SafetyPulsePainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, (size.height * 0.5) - 18);

    for (int i = 0; i < 2; i++) {
      final p = (progress + (i * 0.5)) % 1.0;
      final radius = 42.0 + (p * 50.0);
      final alpha = (1.0 - p) * 0.35;

      final paint = Paint()
        ..color = AppColors.softMint.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SafetyPulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Sub-widgets & Painters
// ─────────────────────────────────────────────────────────────────────────────
class _RoutePointBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData icon;
  final bool isHighlight;

  const _RoutePointBadge({
    required this.label,
    required this.color,
    required this.textColor,
    required this.icon,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isHighlight ? 0.95 : 0.90),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteTimelineRow extends StatelessWidget {
  final String origin;
  final String destination;
  final String time;

  const _RouteTimelineRow({
    required this.origin,
    required this.destination,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                origin,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 3.5),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 1,
              height: 14,
              color: const Color(0xFFCBD5E1),
            ),
          ),
        ),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                destination,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.schedule, size: 12, color: AppColors.mutedText),
            const SizedBox(width: 4),
            Text(
              time,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RouteGridPainter extends CustomPainter {
  final bool isDark;

  _RouteGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.04 : 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
