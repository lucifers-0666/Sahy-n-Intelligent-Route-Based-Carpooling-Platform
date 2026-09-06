import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/widgets/primary_button.dart';
import 'package:sahyan/shared/widgets/ride_card.dart';
import '../rides_provider.dart';

class SearchResultsScreen extends ConsumerWidget {
  const SearchResultsScreen({super.key});

  void _showFilterModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${query.origin} → ${query.destination}',
              style: AppTypography.sectionHeader.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$formattedDate • ${query.seats} Seat${query.seats > 1 ? 's' : ''}',
              style: AppTypography.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.tune_rounded,
              color: AppColors.primaryForest,
            ),
            onPressed: () => _showFilterModal(context, ref),
          ),
        ],
      ),
      body: searchResultsAsync.when(
        data: (results) {
          if (results.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.softForest,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_car_outlined,
                        size: 48,
                        color: AppColors.primaryForest,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Planned Rides Found',
                      style: AppTypography.sectionHeader.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No drivers are scheduled between ${query.origin} and ${query.destination} within ±${query.timeWindowHours}h and ${query.maxPickupDistanceKm.toInt()}km radius.',
                      style: AppTypography.secondary,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryForest),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(
                        Icons.zoom_out_map_rounded,
                        color: AppColors.primaryForest,
                        size: 18,
                      ),
                      label: Text(
                        'Broaden Search (50 km)',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primaryForest,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        ref.read(rideSearchQueryProvider.notifier).state = query
                            .copyWith(
                              maxPickupDistanceKm: 50.0,
                              maxDropDistanceKm: 50.0,
                              timeWindowHours: 12,
                            );
                      },
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'Change Route or Date',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primaryForest,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryForest),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: AppColors.mutedRust,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to load rides',
                  style: AppTypography.sectionHeader,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please verify network connectivity and ensure the backend service is running.',
                  style: AppTypography.secondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryForest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Retry Search',
                    style: TextStyle(color: AppColors.white),
                  ),
                  onPressed: () {
                    ref.invalidate(searchRidesProvider);
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
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Search Filters',
                        style: AppTypography.sectionHeader.copyWith(
                          fontWeight: FontWeight.bold,
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
                const SizedBox(height: 14),

                // Pickup Search Radius
                Text(
                  'Pickup Deviation Radius',
                  style: AppTypography.fieldLabel,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [15.0, 30.0, 50.0].map((dist) {
                    final isSelected = _selectedPickupDist == dist;
                    return ChoiceChip(
                      label: Text(
                        '${dist.toInt()} km',
                        style: AppTypography.caption,
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.softForest,
                      backgroundColor: AppColors.warmBackground,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedPickupDist = dist);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Time Window
                Text('Departure Time Window', style: AppTypography.fieldLabel),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [2, 4, 8].map((hours) {
                    final isSelected = _selectedWindow == hours;
                    return ChoiceChip(
                      label: Text('± $hours hrs', style: AppTypography.caption),
                      selected: isSelected,
                      selectedColor: AppColors.softForest,
                      backgroundColor: AppColors.warmBackground,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedWindow = hours);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Passenger Count
                Text('Seats Required', style: AppTypography.fieldLabel),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [1, 2, 3, 4].map((s) {
                    final isSelected = _selectedSeats == s;
                    return ChoiceChip(
                      label: Text(
                        '$s Seat${s > 1 ? 's' : ''}',
                        style: AppTypography.caption,
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.softForest,
                      backgroundColor: AppColors.warmBackground,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedSeats = s);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                PrimaryButton(
                  text: 'Apply Filters',
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
