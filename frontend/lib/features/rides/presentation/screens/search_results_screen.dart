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

/// Redesigned Search Results screen matching the Sahyān Stitch & Figma mobile UI concept.
/// Incorporates live search query tags, quick filter sheet, empty/error state widgets, and floating nav clearance.
class SearchResultsScreen extends ConsumerWidget {
  const SearchResultsScreen({super.key});

  void _showFilterModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (ctx) => const SearchFiltersBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(rideSearchQueryProvider);
    final searchResultsAsync = ref.watch(searchRidesProvider);
    final formattedDate = DateFormat('dd MMM yyyy').format(query.date);

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        backgroundColor: AppColors.warmBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
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
                    color: AppColors.primaryForest,
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
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: AppColors.softForest,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.primaryForest,
                  size: 20,
                ),
                tooltip: 'Filter Search',
                onPressed: () => _showFilterModal(context, ref),
              ),
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
                        'No drivers are scheduled between ${query.origin} and ${query.destination} within ±${query.timeWindowHours}h and ${query.maxPickupDistanceKm.toInt()}km radius.',
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
                        color: AppColors.primaryForest,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
              left: AppSpacing.containerMargin,
              right: AppSpacing.containerMargin,
              top: AppSpacing.md,
              bottom: 110.0, // Floating bottom nav clearance
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
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
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
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
                              ? AppColors.primaryForest
                              : AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.softForest,
                      backgroundColor: AppColors.warmBackground,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryForest
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
                        '± $hours hrs',
                        style: AppTypography.caption.copyWith(
                          color: isSelected
                              ? AppColors.primaryForest
                              : AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.softForest,
                      backgroundColor: AppColors.warmBackground,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryForest
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
                              ? AppColors.primaryForest
                              : AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.softForest,
                      backgroundColor: AppColors.warmBackground,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryForest
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
