import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/sahyan_app_bar.dart';
import '../../../../core/widgets/sahyan_button.dart';
import '../../../../core/widgets/sahyan_card.dart';
import '../rides_provider.dart';

class FilterRidesScreen extends ConsumerStatefulWidget {
  const FilterRidesScreen({super.key});

  @override
  ConsumerState<FilterRidesScreen> createState() => _FilterRidesScreenState();
}

class _FilterRidesScreenState extends ConsumerState<FilterRidesScreen> {
  late double _maxPickupDistance;
  late int _timeWindowHours;
  late int _seats;
  double _maxContribution = 500;
  String _departureSegment = 'Anytime';
  String _routeMatchTier = 'Direct';
  String _vehiclePreference = 'Any';
  String _minRating = '4.5+';
  bool _flexibleTiming = true;
  bool _verifiedOnly = true;
  bool _prefAc = true;
  bool _prefQuiet = false;
  bool _prefLuggage = false;
  bool _prefWomenOnly = false;

  @override
  void initState() {
    super.initState();
    final query = ref.read(rideSearchQueryProvider);
    _maxPickupDistance = query.maxPickupDistanceKm;
    _timeWindowHours = query.timeWindowHours;
    _seats = query.seats;
  }

  void _handleReset() {
    setState(() {
      _maxPickupDistance = 30.0;
      _timeWindowHours = 4;
      _seats = 1;
      _maxContribution = 500;
      _departureSegment = 'Anytime';
      _routeMatchTier = 'Direct';
      _vehiclePreference = 'Any';
      _minRating = 'Any';
      _flexibleTiming = true;
      _verifiedOnly = false;
      _prefAc = false;
      _prefQuiet = false;
      _prefLuggage = false;
      _prefWomenOnly = false;
    });
  }

  void _handleApply() {
    final current = ref.read(rideSearchQueryProvider);
    ref.read(rideSearchQueryProvider.notifier).state = current.copyWith(
      maxPickupDistanceKm: _maxPickupDistance,
      timeWindowHours: _timeWindowHours,
      seats: _seats,
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/search-results');
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(rideSearchQueryProvider);
    final originText = query.origin.isNotEmpty ? query.origin : 'Ahmedabad';
    final destText = query.destination.isNotEmpty ? query.destination : 'Rajkot';

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: SahyanAppBar(
        title: 'Filter Rides',
        showBackButton: true,
        actions: [
          TextButton.icon(
            onPressed: _handleReset,
            icon: const Icon(
              Icons.restart_alt_rounded,
              size: 16,
              color: AppColors.primaryForest,
            ),
            label: Text(
              'Reset',
              style: AppTypography.button.copyWith(
                color: AppColors.primaryForest,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.containerMargin,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active Corridor Preview Banner
                    SahyanCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.softForest,
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                            child: const Icon(
                              Icons.alt_route_rounded,
                              color: AppColors.primaryForest,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$originText to $destText',
                                  style: AppTypography.cardTitle.copyWith(
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Express Corridor · Real-time Matches',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Section 1: Departure Time Window
                    _buildSectionHeader(
                      'DEPARTURE WINDOW',
                      'Filter by time of day',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        'Anytime',
                        'Morning (6 AM - 12 PM)',
                        'Afternoon (12 PM - 6 PM)',
                        'Evening (6 PM - 12 AM)',
                      ].map((seg) {
                        final isSelected = _departureSegment == seg;
                        return ChoiceChip(
                          label: Text(seg),
                          selected: isSelected,
                          selectedColor: AppColors.softForest,
                          backgroundColor: AppColors.white,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primaryForest
                                : AppColors.border,
                          ),
                          labelStyle: AppTypography.caption.copyWith(
                            color: isSelected
                                ? AppColors.primaryForest
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _departureSegment = seg);
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.primaryForest,
                      title: Text(
                        'Flexible timing (+/- 30 mins)',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Accommodates minor highway traffic buffers',
                        style: AppTypography.caption,
                      ),
                      value: _flexibleTiming,
                      onChanged: (v) => setState(() => _flexibleTiming = v),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Route Match Tier
                    _buildSectionHeader(
                      'ROUTE MATCH TIER',
                      'Overlap with your corridor itinerary',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        'Direct (95%+)',
                        'Highway (80%+)',
                        'Any Match',
                      ].map((tier) {
                        final isSelected = _routeMatchTier == tier;
                        return ChoiceChip(
                          label: Text(tier),
                          selected: isSelected,
                          selectedColor: AppColors.softForest,
                          backgroundColor: AppColors.white,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primaryForest
                                : AppColors.border,
                          ),
                          labelStyle: AppTypography.caption.copyWith(
                            color: isSelected
                                ? AppColors.primaryForest
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _routeMatchTier = tier);
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Section 2: Max Contribution Fair-Share Slider
                    _buildSectionHeader(
                      'MAX CONTRIBUTION',
                      'Fair-share fuel and toll split per seat',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SahyanCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Per Seat Cap',
                                  style: AppTypography.secondary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '₹${_maxContribution.toInt()}',
                                style: AppTypography.cardTitle.copyWith(
                                  color: AppColors.primaryForest,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _maxContribution,
                            min: 200,
                            max: 1000,
                            divisions: 16,
                            activeColor: AppColors.primaryForest,
                            inactiveColor: AppColors.border,
                            onChanged: (val) =>
                                setState(() => _maxContribution = val),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('₹200', style: AppTypography.caption),
                              Text('Avg ₹450', style: AppTypography.caption),
                              Text('₹1000', style: AppTypography.caption),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Section 3: Seats Needed
                    _buildSectionHeader('SEATS NEEDED', 'Total seats together'),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [1, 2, 3, 4].map((count) {
                        final isSelected = _seats == count;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                            ),
                            child: InkWell(
                              onTap: () => setState(() => _seats = count),
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryForest
                                      : AppColors.white,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.md,
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryForest
                                        : AppColors.border,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$count Seat${count > 1 ? 's' : ''}',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: isSelected
                                        ? AppColors.white
                                        : AppColors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Section 4: Safety & Driver Verification
                    _buildSectionHeader(
                      'SAFETY & VERIFICATION',
                      'Trust standards',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SahyanCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: AppColors.primaryForest,
                            title: Text(
                              'Verified Members Only',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Govt ID DigiLocker authenticated hosts only',
                              style: AppTypography.caption,
                            ),
                            value: _verifiedOnly,
                            onChanged: (v) => setState(() => _verifiedOnly = v),
                          ),
                          const Divider(color: AppColors.border),
                          const SizedBox(height: AppSpacing.xs),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Driver Rating',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: ['4.8+', '4.5+', 'Any'].map((rating) {
                                  final isSel = _minRating == rating;
                                  return ChoiceChip(
                                    label: Text(rating),
                                    selected: isSel,
                                    selectedColor: AppColors.softForest,
                                    backgroundColor: AppColors.warmBackground,
                                    side: BorderSide(
                                      color: isSel
                                          ? AppColors.primaryForest
                                          : AppColors.border,
                                    ),
                                    labelStyle: AppTypography.caption.copyWith(
                                      color: isSel
                                          ? AppColors.primaryForest
                                          : AppColors.textPrimary,
                                      fontWeight: isSel
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    onSelected: (val) {
                                      if (val) setState(() => _minRating = rating);
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Section 5: Vehicle Preference
                    _buildSectionHeader(
                      'VEHICLE PREFERENCE',
                      'Powertrain and body style',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: ['Any', 'Sedan / SUV', 'EV (Electric)'].map((
                        veh,
                      ) {
                        final isSel = _vehiclePreference == veh;
                        return ChoiceChip(
                          label: Text(veh),
                          selected: isSel,
                          selectedColor: AppColors.softForest,
                          backgroundColor: AppColors.white,
                          side: BorderSide(
                            color: isSel
                                ? AppColors.primaryForest
                                : AppColors.border,
                          ),
                          labelStyle: AppTypography.caption.copyWith(
                            color: isSel
                                ? AppColors.primaryForest
                                : AppColors.textPrimary,
                            fontWeight: isSel
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _vehiclePreference = veh);
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Section 6: Comfort & Co-Traveler Preferences
                    _buildSectionHeader(
                      'AMENITIES & PREFERENCES',
                      'Ride environment',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _buildFilterFilterChip('AC Equipped', _prefAc, (v) {
                          setState(() => _prefAc = v);
                        }),
                        _buildFilterFilterChip('Quiet Ride', _prefQuiet, (v) {
                          setState(() => _prefQuiet = v);
                        }),
                        _buildFilterFilterChip('Luggage Space', _prefLuggage, (
                          v,
                        ) {
                          setState(() => _prefLuggage = v);
                        }),
                        _buildFilterFilterChip(
                          'Women-Only Ride',
                          _prefWomenOnly,
                          (v) {
                            setState(() => _prefWomenOnly = v);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.containerMargin,
                vertical: AppSpacing.md,
              ),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: SahyanButton(
                      text: 'Reset',
                      variant: SahyanButtonVariant.outline,
                      onPressed: _handleReset,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: SahyanButton(
                      text: 'Show Matching Rides',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _handleApply,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        Text(subtitle, style: AppTypography.caption),
      ],
    );
  }

  Widget _buildFilterFilterChip(
    String label,
    bool isSelected,
    ValueChanged<bool> onChanged,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.softForest,
      backgroundColor: AppColors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primaryForest : AppColors.border,
      ),
      labelStyle: AppTypography.caption.copyWith(
        color: isSelected ? AppColors.primaryForest : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: onChanged,
    );
  }
}
