import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:sahyan/app/theme/app_colors.dart';
import 'package:sahyan/app/theme/app_radii.dart';
import 'package:sahyan/app/theme/app_spacing.dart';
import 'package:sahyan/app/theme/app_typography.dart';
import 'package:sahyan/core/services/route_service.dart';
import 'package:sahyan/core/widgets/sahyan_button.dart';
import 'package:sahyan/core/widgets/sahyan_empty_state.dart';
import 'package:sahyan/core/widgets/sahyan_error_state.dart';
import 'package:sahyan/core/widgets/sahyan_loading_state.dart';
import 'package:sahyan/shared/models/location_model.dart';
import 'package:sahyan/shared/widgets/full_screen_route_map_sheet.dart';
import 'package:sahyan/shared/widgets/ride_card.dart';
import 'package:sahyan/shared/widgets/sahyan_route_map.dart';
import '../rides_provider.dart';

/// Redesigned Uber-style Split-Screen Search Results screen matching the Sahyan mobility engine.
/// Upper 45% viewport embeds SayanRouteMap; lower half is an interactive DraggableScrollableSheet
/// containing filtered candidate ride cards and radar corridor expansion controls.
class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  String _selectedQuickFilter = 'All';
  String _selectedSort = 'Best Match';
  double _corridorRadius = 30.0;
  List<ll.LatLng> _corridorPolylinePoints = [];
  bool _isFetchingCorridorPolyline = false;
  String _lastFetchedRouteKey = '';

  @override
  void initState() {
    super.initState();
    _corridorRadius = ref.read(rideSearchQueryProvider).maxPickupDistanceKm;
  }

  void _fetchCorridorPolylineIfNeeded(
    LocationModel origin,
    LocationModel destination,
  ) {
    final routeKey =
        '${origin.latitude},${origin.longitude}->${destination.latitude},${destination.longitude}';
    if (_lastFetchedRouteKey == routeKey || _isFetchingCorridorPolyline) return;
    if (origin.latitude == 0.0 && origin.longitude == 0.0) return;
    if (destination.latitude == 0.0 && destination.longitude == 0.0) return;

    _lastFetchedRouteKey = routeKey;
    _isFetchingCorridorPolyline = true;
    RouteService.fetchRealRoadPolyline(
      origin: origin,
      destination: destination,
    ).then((res) {
      if (mounted && res.points.isNotEmpty) {
        setState(() {
          _corridorPolylinePoints = res.points;
        });
      }
    }).catchError((_) {}).whenComplete(() {
      _isFetchingCorridorPolyline = false;
    });
  }

  LocationModel _resolveLocation(
    LocationModel? loc,
    String text,
    bool isOrigin,
  ) {
    if (loc != null && (loc.latitude != 0 || loc.longitude != 0)) {
      return loc;
    }
    final lower = text.toLowerCase();
    if (lower.contains('kalawad') || lower.contains('rajkot')) {
      return LocationModel.fromCoordinates(
        name: text.isNotEmpty ? text : 'Kalawad Road, Rajkot',
        latitude: 22.2837,
        longitude: 70.7684,
      );
    }
    if (lower.contains('sg highway') || lower.contains('ahmedabad')) {
      return LocationModel.fromCoordinates(
        name: text.isNotEmpty ? text : 'SG Highway, Ahmedabad',
        latitude: 23.0300,
        longitude: 72.5075,
      );
    }
    if (lower.contains('madhapar')) {
      return LocationModel.fromCoordinates(
        name: text.isNotEmpty ? text : 'Madhapar Chowk, Rajkot',
        latitude: 22.3168,
        longitude: 70.7836,
      );
    }
    if (lower.contains('dhrol')) {
      return LocationModel.fromCoordinates(
        name: text.isNotEmpty ? text : 'Dhrol',
        latitude: 22.5645,
        longitude: 70.4147,
      );
    }
    if (lower.contains('digjam') || lower.contains('jamnagar')) {
      return LocationModel.fromCoordinates(
        name: text.isNotEmpty ? text : 'Digjam Circle, Jamnagar',
        latitude: 22.4647,
        longitude: 70.0712,
      );
    }
    if (lower.contains('trikon baug')) {
      return LocationModel.fromCoordinates(
        name: text.isNotEmpty ? text : 'Trikon Baug, Rajkot',
        latitude: 22.3000,
        longitude: 70.8022,
      );
    }
    if (lower.contains('aiims') || lower.contains('khandheri')) {
      return LocationModel.fromCoordinates(
        name: text.isNotEmpty ? text : 'AIIMS Rajkot / Khandheri',
        latitude: 22.3850,
        longitude: 70.7420,
      );
    }
    if (lower.contains('bopal')) {
      return LocationModel.fromCoordinates(
        name: text.isNotEmpty ? text : 'Bopal, Ahmedabad',
        latitude: 23.0350,
        longitude: 72.4650,
      );
    }
    if (lower.contains('gift') || lower.contains('gandhinagar')) {
      return LocationModel.fromCoordinates(
        name: text.isNotEmpty ? text : 'GIFT City, Gandhinagar',
        latitude: 23.1600,
        longitude: 72.6840,
      );
    }
    if (lower.contains('prahlad')) {
      return LocationModel.fromCoordinates(
        name: text.isNotEmpty ? text : 'Prahlad Nagar, Ahmedabad',
        latitude: 23.0125,
        longitude: 72.5100,
      );
    }
    if (lower.contains('alkapuri') || lower.contains('vadodara')) {
      return LocationModel.fromCoordinates(
        name: text.isNotEmpty ? text : 'Alkapuri, Vadodara',
        latitude: 22.3100,
        longitude: 73.1800,
      );
    }
    if (lower.contains('majura') || lower.contains('surat')) {
      return LocationModel.fromCoordinates(
        name: text.isNotEmpty ? text : 'Majura Gate, Surat',
        latitude: 21.1800,
        longitude: 72.8200,
      );
    }
    if (lower.contains('bhuj') || lower.contains('jubilee')) {
      return LocationModel.fromCoordinates(
        name: text.isNotEmpty ? text : 'Jubilee Ground, Bhuj',
        latitude: 23.2420,
        longitude: 69.6669,
      );
    }
    if (lower.contains('gandhidham')) {
      return LocationModel.fromCoordinates(
        name: text.isNotEmpty ? text : 'Gandhidham',
        latitude: 23.0753,
        longitude: 70.1337,
      );
    }
    if (lower.contains('geeta mandir')) {
      return LocationModel.fromCoordinates(
        name: text.isNotEmpty ? text : 'Geeta Mandir, Ahmedabad',
        latitude: 23.0135,
        longitude: 72.5890,
      );
    }
    if (isOrigin) {
      return LocationModel.fromCoordinates(
        name: text.isNotEmpty ? text : 'Ahmedabad',
        latitude: 23.0225,
        longitude: 72.5714,
      );
    } else {
      return LocationModel.fromCoordinates(
        name: text.isNotEmpty ? text : 'Rajkot',
        latitude: 22.3039,
        longitude: 70.8022,
      );
    }
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.deepEmerald,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 44,
        height: 4.5,
        margin: const EdgeInsets.only(top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }

  Widget _buildRouteSummaryBar(
    LocationModel origin,
    LocationModel destination,
    RideSearchQuery query,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.deepEmerald,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${origin.city.isNotEmpty ? origin.city : origin.name} \u2794 ${destination.city.isNotEmpty ? destination.city : destination.name} \u2022 ${query.seats} Seat${query.seats > 1 ? 's' : ''}',
              style: AppTypography.cardTitle.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.primaryText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          'All',
          'Earliest',
          'Lowest Fare',
          'AC',
          'Verified Driver',
        ].map((filterLabel) {
          final isSelected = _selectedQuickFilter == filterLabel;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filterLabel),
              selected: isSelected,
              selectedColor: AppColors.deepEmerald,
              backgroundColor: AppColors.white,
              labelStyle: AppTypography.caption.copyWith(
                color: isSelected ? AppColors.white : AppColors.primaryText,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.deepEmerald : AppColors.border,
                width: 0.8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              onSelected: (_) {
                setState(() => _selectedQuickFilter = filterLabel);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRadarCorridorSliderCard(RideSearchQuery query) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.radar_rounded,
                color: AppColors.deepEmerald,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Radar Corridor Radius: ${_corridorRadius.toInt()} km',
                  style: AppTypography.cardTitle.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  final next = (_corridorRadius + 20.0).clamp(10.0, 100.0);
                  setState(() => _corridorRadius = next);
                  ref.read(rideSearchQueryProvider.notifier).state =
                      query.copyWith(
                    maxPickupDistanceKm: next,
                    maxDropDistanceKm: next,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.softMint.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text(
                    '+20 km Expansion',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.deepEmerald,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.deepEmerald,
              thumbColor: AppColors.deepEmerald,
              inactiveTrackColor: AppColors.border,
              overlayColor: AppColors.deepEmerald.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: _corridorRadius.clamp(10.0, 100.0),
              min: 10.0,
              max: 100.0,
              divisions: 9,
              label: '${_corridorRadius.toInt()} km',
              onChanged: (val) {
                setState(() => _corridorRadius = val);
              },
              onChangeEnd: (val) {
                ref.read(rideSearchQueryProvider.notifier).state =
                    query.copyWith(
                  maxPickupDistanceKm: val,
                  maxDropDistanceKm: val,
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '10 km (Exact)',
                style: AppTypography.caption.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              Text(
                '100 km (Wide Corridor)',
                style: AppTypography.caption.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(rideSearchQueryProvider);
    final searchResultsAsync = ref.watch(searchRidesProvider);
    final formattedDate = DateFormat('dd MMM yyyy').format(query.date);

    final hasCustomFilters = query.maxPickupDistanceKm != 30.0 ||
        query.timeWindowHours != 4 ||
        query.seats != 1;

    final effectiveOrigin = _resolveLocation(
      query.originLocation,
      query.origin,
      true,
    );
    final effectiveDestination = _resolveLocation(
      query.destinationLocation,
      query.destination,
      false,
    );

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
          List<ll.LatLng> polylinePoints = const [];
          List<LocationModel> stopovers = const [];
          if (results.isNotEmpty) {
            final firstRide = results.first.ride;
            stopovers = firstRide.stopovers;
            final encoded = firstRide.route?.encodedPolyline;
            if (encoded != null && encoded.isNotEmpty) {
              polylinePoints = RouteService.decodePolyline(encoded)
                  .map((p) => ll.LatLng(p.latitude, p.longitude))
                  .toList();
            }
          }
          if (polylinePoints.isEmpty) {
            if (_corridorPolylinePoints.isNotEmpty) {
              polylinePoints = _corridorPolylinePoints;
            } else {
              _fetchCorridorPolylineIfNeeded(
                effectiveOrigin,
                effectiveDestination,
              );
              polylinePoints = const [];
            }
          }

          final filteredResults = results.where((r) {
            if (_selectedQuickFilter == 'Earliest' ||
                _selectedQuickFilter == 'Lowest Fare') {
              return true;
            }
            if (_selectedQuickFilter == 'AC') {
              return r.ride.amenities.contains('AC');
            }
            if (_selectedQuickFilter == 'Verified Driver') {
              return r.ride.isDriverVerified;
            }
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

          filteredResults.sort((a, b) {
            if (_selectedQuickFilter == 'Earliest' ||
                _selectedSort == 'Earliest Departure') {
              return a.ride.dateTime.compareTo(b.ride.dateTime);
            }
            if (_selectedQuickFilter == 'Lowest Fare' ||
                _selectedSort == 'Lowest Price') {
              return a.ride.contributionPerSeat.compareTo(
                b.ride.contributionPerSeat,
              );
            }
            final scoreA =
                a.match?.score ?? (100 - (a.pickupDistanceKm * 10).toInt());
            final scoreB =
                b.match?.score ?? (100 - (b.pickupDistanceKm * 10).toInt());
            return scoreB.compareTo(scoreA);
          });

          return Stack(
            children: [
              // Top Interactive Map (Upper 45-48% Viewport)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.48,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SayanRouteMap(
                        origin: effectiveOrigin,
                        destination: effectiveDestination,
                        polylinePoints: polylinePoints,
                        stopovers: stopovers,
                        interactive: true,
                        showControls: false,
                        vehicleTypeCode: results.isNotEmpty ? results.first.ride.vehicle.vehicleType : null,
                      ),
                    ),
                    Positioned(
                      right: 14,
                      top: 14,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMapActionButton(
                            icon: Icons.open_in_full_rounded,
                            tooltip: 'Expand 3D Map',
                            onTap: () {
                              FullScreenRouteMapSheet.show(
                                context: context,
                                origin: effectiveOrigin,
                                destination: effectiveDestination,
                                polylinePoints: polylinePoints,
                                stopovers: stopovers,
                                routeTitle:
                                    '${effectiveOrigin.name} \u2794 ${effectiveDestination.name}',
                                distanceKm: 215.0,
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildMapActionButton(
                            icon: Icons.my_location_rounded,
                            tooltip: 'My Location',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Centered on pickup location',
                                  ),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Draggable Bottom Sheet
              DraggableScrollableSheet(
                initialChildSize: 0.55,
                minChildSize: 0.30,
                maxChildSize: 0.92,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: results.isEmpty
                        ? ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 8,
                              bottom: 90,
                            ),
                            children: [
                              _buildDragHandle(),
                              _buildRouteSummaryBar(
                                effectiveOrigin,
                                effectiveDestination,
                                query,
                              ),
                              _buildQuickFilterChips(),
                              const SizedBox(height: 12),
                              SahyanEmptyState(
                                icon: Icons.directions_car_outlined,
                                title: 'No Planned Rides Found',
                                description:
                                    'No drivers are scheduled between ${query.origin} and ${query.destination} within +/-${query.timeWindowHours}h and ${query.maxPickupDistanceKm.toInt()}km radius.',
                                actionText: 'Broaden Search (50 km)',
                                onAction: () {
                                  ref
                                      .read(rideSearchQueryProvider.notifier)
                                      .state = query.copyWith(
                                    maxPickupDistanceKm: 50.0,
                                    maxDropDistanceKm: 50.0,
                                    timeWindowHours: 12,
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildRadarCorridorSliderCard(query),
                              const SizedBox(height: 12),
                              SahyanButton(
                                text: 'Post Wanted Ride',
                                variant: SahyanButtonVariant.outline,
                                icon: Icons.add_road_rounded,
                                onPressed: () {
                                  context.push('/offer-ride');
                                },
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: TextButton(
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
                              ),
                            ],
                          )
                        : RefreshIndicator(
                            color: AppColors.deepEmerald,
                            onRefresh: () async {
                              ref.invalidate(searchRidesProvider);
                              await ref.read(searchRidesProvider.future);
                            },
                            child: ListView.builder(
                              controller: scrollController,
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 8,
                                bottom: 90,
                              ),
                              itemCount: filteredResults.isEmpty
                                  ? 2
                                  : filteredResults.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildDragHandle(),
                                      _buildRouteSummaryBar(
                                        effectiveOrigin,
                                        effectiveDestination,
                                        query,
                                      ),
                                      _buildQuickFilterChips(),
                                      const SizedBox(height: AppSpacing.xs),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: AppSpacing.sm,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${filteredResults.length} available ride${filteredResults.length == 1 ? '' : 's'}',
                                              style: AppTypography.caption
                                                  .copyWith(
                                                color: AppColors.mutedText,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            PopupMenuButton<String>(
                                              initialValue: _selectedSort,
                                              tooltip: 'Sort Rides',
                                              onSelected: (val) {
                                                setState(
                                                  () => _selectedSort = val,
                                                );
                                              },
                                              child: Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.sort_rounded,
                                                    size: 14,
                                                    color:
                                                        AppColors.deepEmerald,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _selectedSort,
                                                    style: AppTypography
                                                        .caption
                                                        .copyWith(
                                                      color: AppColors
                                                          .deepEmerald,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons.arrow_drop_down,
                                                    size: 16,
                                                    color:
                                                        AppColors.deepEmerald,
                                                  ),
                                                ],
                                              ),
                                              itemBuilder: (ctx) => const [
                                                PopupMenuItem(
                                                  value: 'Best Match',
                                                  child: Text(
                                                    'Best Match (Recommended)',
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value:
                                                      'Earliest Departure',
                                                  child: Text(
                                                    'Earliest Departure',
                                                  ),
                                                ),
                                                PopupMenuItem(
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
                                    margin: const EdgeInsets.only(
                                      top: AppSpacing.lg,
                                    ),
                                    padding:
                                        const EdgeInsets.all(AppSpacing.lg),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.card,
                                      ),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
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
                                          style: AppTypography.bodyLarge
                                              .copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryText,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Try clearing the quick filter to see all ${results.length} scheduled rides.',
                                          style: AppTypography.caption
                                              .copyWith(
                                            color: AppColors.mutedText,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        TextButton(
                                          onPressed: () {
                                            setState(
                                              () =>
                                                  _selectedQuickFilter = 'All',
                                            );
                                          },
                                          child: Text(
                                            'Show All ${results.length} Rides',
                                            style: AppTypography.bodyMedium
                                                .copyWith(
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
                                  showRequestSeatButton: true,
                                  onTap: () {
                                    ref
                                        .read(selectedRideProvider.notifier)
                                        .state = result.ride;
                                    ref
                                        .read(
                                          selectedSearchResultProvider.notifier,
                                        )
                                        .state = result;
                                    context.push('/ride-details');
                                  },
                                );
                              },
                            ),
                          ),
                  );
                },
              ),
            ],
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
