import 'package:flutter/material.dart';

/// Five-Section Skeleton Outline Loader for Android / Flutter.
/// Displays an elegant shimmer outline across the 5 primary wizard sections
/// when remote or geospatial content is resolving.
class SahyanFiveSectionSkeleton extends StatefulWidget {
  const SahyanFiveSectionSkeleton({super.key});

  @override
  State<SahyanFiveSectionSkeleton> createState() =>
      _SahyanFiveSectionSkeletonState();
}

class _SahyanFiveSectionSkeletonState extends State<SahyanFiveSectionSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        final shimmerColor = Color.lerp(
          const Color(0xFFEEF2EF),
          const Color(0xFFF9FAF9),
          _pulseAnimation.value,
        )!;

        final blockColor = Color.lerp(
          const Color(0xFFE2E8E4),
          const Color(0xFFEAEFEA),
          _pulseAnimation.value,
        )!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1 Outline: Vehicle Garage Bento Card
            _buildSection1VehicleBentoOutline(shimmerColor, blockColor),
            const SizedBox(height: 20),

            // Section 2 Outline: Unified Transit Route Rail Card
            _buildSection2TransitRailOutline(shimmerColor, blockColor),
            const SizedBox(height: 14),

            // Section 3 Outline: Frequent Corridor Quick Chips
            _buildSection3CorridorChipsOutline(shimmerColor, blockColor),
            const SizedBox(height: 18),

            // Section 4 Outline: Integrated Route Mini-Map Card
            _buildSection4MiniMapOutline(shimmerColor, blockColor),
            const SizedBox(height: 24),

            // Section 5 Outline: Action Navigation CTA Button
            _buildSection5ActionCtaOutline(shimmerColor, blockColor),
          ],
        );
      },
    );
  }

  // --- 1. Vehicle Garage Bento Card Skeleton ---
  Widget _buildSection1VehicleBentoOutline(Color shimmer, Color block) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: shimmer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8E4), width: 0.8),
      ),
      child: Row(
        children: [
          // Vehicle Avatar Placeholder
          Container(
            width: 52,
            height: 40,
            decoration: BoxDecoration(
              color: block,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 14),
          // Vehicle Details Bar Placeholders
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: block,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: block,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          // Capacity Badge Placeholder
          Container(
            width: 64,
            height: 24,
            decoration: BoxDecoration(
              color: block,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Unified Transit Route Rail Card Skeleton ---
  Widget _buildSection2TransitRailOutline(Color shimmer, Color block) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: shimmer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8E4), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Rail Indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: block,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 2,
                  height: 44,
                  color: block.withValues(alpha: 0.6),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: block,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Right Input Placeholders
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: block,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: block,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Frequent Corridor Quick Chips Skeleton ---
  Widget _buildSection3CorridorChipsOutline(Color shimmer, Color block) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: List.generate(4, (index) {
          final widths = [84.0, 110.0, 116.0, 102.0];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: widths[index % widths.length],
              height: 32,
              decoration: BoxDecoration(
                color: shimmer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8E4), width: 0.8),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- 4. Route Mini-Map Card Skeleton ---
  Widget _buildSection4MiniMapOutline(Color shimmer, Color block) {
    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: shimmer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8E4), width: 0.8),
      ),
      child: Stack(
        children: [
          // Floating Telemetry Pill Placeholder
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 160,
              height: 28,
              decoration: BoxDecoration(
                color: block,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Floating Expand Button Placeholder
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 90,
              height: 28,
              decoration: BoxDecoration(
                color: block,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Center Road Geometry Line Placeholder
          Center(
            child: Container(
              width: 140,
              height: 4,
              decoration: BoxDecoration(
                color: block,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. Action Navigation CTA Skeleton ---
  Widget _buildSection5ActionCtaOutline(Color shimmer, Color block) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: block,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
