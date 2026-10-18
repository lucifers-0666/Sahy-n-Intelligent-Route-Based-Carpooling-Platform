import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_radii.dart';
import 'package:sahyan/app/theme/app_spacing.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/sahyan_button.dart';
import 'package:sahyan/core/widgets/sahyan_empty_state.dart';
import 'package:sahyan/core/widgets/sahyan_error_state.dart';
import 'package:sahyan/core/widgets/sahyan_loading_state.dart';
import 'package:sahyan/shared/widgets/ride_card.dart';
import '../rides_provider.dart';

/// Redesigned Search Results screen matching the Sahyan Stitch and Figma mobile UI concept.
/// Incorporates live search query tags, quick filter sheet, sorting options, and empty/error states.
class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  String _selectedQuickFilter = 'All';
  String _selectedSort = 'Best Match';

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(rideSearchQueryProvider);
    final searchResultsAsync = ref.watch(searchRidesProvider);
    final formattedDate = DateFormat('dd MMM yyyy').format(query.date);

    final hasCustomFilters = query.maxPickupDistanceKm != 30.0 ||
        query.timeWindowHours != 4 ||
        query.seats != 1;

    return Scaffold(
      backgroundColor: AppColors.lightSurface,
      appBar: AppBar(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.primaryText,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    query.origin.isNotEmpty ? query.origin : 'Anywhere',
                    style: AppTypography.sectionHeader.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.deepEmerald,
                  ),
                ),
                Flexible(
                  child: Text(
                    query.destination.isNotEmpty
                        ? query.destination
                        : 'Anywhere',
                    style: AppTypography.sectionHeader.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '$formattedDate • ${query.seats} Seat${query.seats > 1 ? 's' : ''}',
              style: AppTypography.caption.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Material(
                  color: hasCustomFilters
                      ? AppColors.softMint.withValues(alpha: 0.3)
                      : AppColors.white,
                  shape: const CircleBorder(),
                  elevation: 0.5,
                  child: IconButton(
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.deepEmerald,
                      size: 20,
                    ),
                    tooltip: 'Filter Search',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: AppColors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppRadii.lg),
                          ),
                        ),
                        builder: (ctx) => const SearchFiltersBottomSheet(),
                      );
                    },
                  ),
                ),
                if (hasCustomFilters)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.deepEmerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: searchResultsAsync.when(
        data: (results) {
          if (results.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: AppSpacing.containerMargin,
                right: AppSpacing.containerMargin,
                top: AppSpacing.xl,
                bottom: 110.0,
              ),
              child: Column(
                children: [
                  SahyanEmptyState(
                    icon: Icons.directions_car_outlined,
                    title: 'No Planned Rides Found',
                    description:
                        'No drivers are scheduled between ${query.origin} and ${query.destination} within +/-${query.timeWindowHours}h and ${query.maxPickupDistanceKm.toInt()}km radius.',
                    actionText: 'Broaden Search (50 km)',
                    onAction: () {
                      ref.read(rideSearchQueryProvider.notifier).state = query
                          .copyWith(
                            maxPickupDistanceKm: 50.0,
                            maxDropDistanceKm: 50.0,
                            timeWindowHours: 12,
                          );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    child: Text(
                      'Change Route or Date',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.deepEmerald,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // In-memory quick filter application
          final filteredResults = results.where((r) {
            if (_selectedQuickFilter == 'Direct Only') {
              return r.pickupDistanceKm <= 2.0;
            }
            if (_selectedQuickFilter == 'High Match') {
              return (r.match?.score ?? 0) >= 80;
            }
            if (_selectedQuickFilter == 'Under \u20B9350') {
              return r.ride.contributionPerSeat <= 350;
            }
            return true;
          }).toList();

          // In-memory sorting application
          filteredResults.sort((a, b) {
            if (_selectedSort == 'Earliest Departure') {
              return a.ride.dateTime.compareTo(b.ride.dateTime);
            }
            if (_selectedSort == 'Lowest Price') {
              return a.ride.contributionPerSeat.compareTo(
                b.ride.contributionPerSeat,
              );
            }
            // Best Match default
            final scoreA = a.match?.score ?? (100 - (a.pickupDistanceKm * 10).toInt());
            final scoreB = b.match?.score ?? (100 - (b.pickupDistanceKm * 10).toInt());
            return scoreB.compareTo(scoreA);
          });

          return RefreshIndicator(
            color: AppColors.deepEmerald,
            onRefresh: () async {
              ref.invalidate(searchRidesProvider);
              await ref.read(searchRidesProvider.future);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(
                left: AppSpacing.containerMargin,
                right: AppSpacing.containerMargin,
                top: AppSpacing.sm,
                bottom: 110.0, // Floating bottom nav clearance
              ),
              itemCount: filteredResults.isEmpty ? 2 : filteredResults.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            'All',
                            'Direct Only',
                            'High Match',
                            'Under \u20B9350',
                          ].map((filterLabel) {
                            final isSelected =
                                _selectedQuickFilter == filterLabel;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(filterLabel),
                                selected: isSelected,
                                selectedColor: AppColors.deepEmerald,
                                backgroundColor: AppColors.white,
                                labelStyle: AppTypography.caption.copyWith(
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.primaryText,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.deepEmerald
                                      : AppColors.border,
                                  width: 0.8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.full,
                                  ),
                                ),
                                onSelected: (_) {
                                  setState(
                                    () => _selectedQuickFilter = filterLabel,
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Results summary & sort indicator
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${filteredResults.length} available ride${filteredResults.length == 1 ? '' : 's'}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.mutedText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            PopupMenuButton<String>(
                              initialValue: _selectedSort,
                              tooltip: 'Sort Rides',
                              onSelected: (val) {
                                setState(() => _selectedSort = val);
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.sort_rounded,
                                    size: 14,
                                    color: AppColors.deepEmerald,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _selectedSort,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.deepEmerald,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    size: 16,
                                    color: AppColors.deepEmerald,
                                  ),
                                ],
                              ),
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'Best Match',
                                  child: Text('Best Match (Recommended)'),
                                ),
                                const PopupMenuItem(
                                  value: 'Earliest Departure',
                                  child: Text('Earliest Departure'),
                                ),
                                const PopupMenuItem(
                                  value: 'Lowest Price',
                                  child: Text('Lowest Price'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                if (filteredResults.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(top: AppSpacing.lg),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.filter_list_off_rounded,
                          size: 36,
                          color: AppColors.mutedText,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'No rides match "$_selectedQuickFilter"',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try clearing the quick filter to see all ${results.length} scheduled rides.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.mutedText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedQuickFilter = 'All');
                          },
                          child: Text(
                            'Show All ${results.length} Rides',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.deepEmerald,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final result = filteredResults[index - 1];
                return RideCard(
                  ride: result.ride,
                  searchResult: result,
                  onTap: () {
                    ref.read(selectedRideProvider.notifier).state = result.ride;
                    ref.read(selectedSearchResultProvider.notifier).state =
                        result;
                    context.push('/ride-details');
                  },
                );
              },
            ),
          );
        },
        loading: () => const SahyanLoadingState(
          message: 'Finding matching rides along your corridor...',
        ),
        error: (err, stack) => SahyanErrorState(
          title: 'Unable to load rides',
          message:
              'Please verify network connectivity and ensure the backend service is running.',
          retryLabel: 'Retry Search',
          onRetry: () => ref.invalidate(searchRidesProvider),
        ),
      ),
    );
  }
}

/// Filter bottom sheet matching Stitch Filter Rides specifications.
class SearchFiltersBottomSheet extends ConsumerStatefulWidget {
  const SearchFiltersBottomSheet({super.key});

  @override
  ConsumerState<SearchFiltersBottomSheet> createState() =>
      _SearchFiltersBottomSheetState();
}

class _SearchFiltersBottomSheetState
    extends ConsumerState<SearchFiltersBottomSheet> {
  late double _selectedPickupDist;
  late int _selectedWindow;
  late int _selectedSeats;

  @override
  void initState() {
    super.initState();
    final currentQuery = ref.read(rideSearchQueryProvider);
    _selectedPickupDist = currentQuery.maxPickupDistanceKm;
    _selectedWindow = currentQuery.timeWindowHours;
    _selectedSeats = currentQuery.seats;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.containerMargin,
            right: AppSpacing.containerMargin,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.base,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Search Filters',
                        style: AppTypography.sectionHeader.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppColors.primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.primaryText,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),

                // Pickup Search Radius
                Text(
                  'Pickup Deviation Radius',
                  style: AppTypography.fieldLabel.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [15.0, 30.0, 50.0].map((dist) {
                    final isSelected = _selectedPickupDist == dist;
                    return ChoiceChip(
                      label: Text(
                        '${dist.toInt()} km',
                        style: AppTypography.caption.copyWith(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.primaryText,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.deepEmerald,
                      backgroundColor: AppColors.lightSurface,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.deepEmerald
                            : AppColors.border,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedPickupDist = dist);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Time Window
                Text(
                  'Departure Time Window',
                  style: AppTypography.fieldLabel.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [2, 4, 8].map((hours) {
                    final isSelected = _selectedWindow == hours;
                    return ChoiceChip(
                      label: Text(
                        '+/- $hours hrs',
                        style: AppTypography.caption.copyWith(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.primaryText,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.deepEmerald,
                      backgroundColor: AppColors.lightSurface,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.deepEmerald
                            : AppColors.border,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedWindow = hours);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Passenger Count
                Text(
                  'Seats Required',
                  style: AppTypography.fieldLabel.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [1, 2, 3, 4].map((s) {
                    final isSelected = _selectedSeats == s;
                    return ChoiceChip(
                      label: Text(
                        '$s Seat${s > 1 ? 's' : ''}',
                        style: AppTypography.caption.copyWith(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.primaryText,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.deepEmerald,
                      backgroundColor: AppColors.lightSurface,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.deepEmerald
                            : AppColors.border,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedSeats = s);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),

                SahyanButton(
                  text: 'Apply Filters',
                  size: SahyanButtonSize.regular,
                  onPressed: () {
                    final currentQuery = ref.read(rideSearchQueryProvider);
                    ref
                        .read(rideSearchQueryProvider.notifier)
                        .state = currentQuery.copyWith(
                      maxPickupDistanceKm: _selectedPickupDist,
                      timeWindowHours: _selectedWindow,
                      seats: _selectedSeats,
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
