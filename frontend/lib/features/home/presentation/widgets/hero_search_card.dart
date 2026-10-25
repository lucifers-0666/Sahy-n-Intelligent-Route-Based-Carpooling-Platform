import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../../app/config/app_region.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/location/data/providers/geolocator_provider.dart';
import '../../../../core/location/domain/gps_provider.dart';
import '../../../../core/network/api_config.dart';
import '../../../../shared/models/location_model.dart';
import '../../../../shared/widgets/bento/bento_widgets.dart';
import '../../../../shared/widgets/journey_location_card.dart';
import '../../../rides/presentation/widgets/location_search_bottom_sheet.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/l10n_extension.dart';

enum _ActiveLocationField { none, origin, destination }

/// Premium Smartphone-Native Hero Route Search Bento Card for Sahyan.
/// Features a unified connected origin-to-destination selector, tactile animated swap,
/// inline autocomplete with debounced geocoding and verified transport hubs,
/// frequent corridor chips, dual-cell parameter controls, and primary search action.
class HeroSearchCard extends StatefulWidget {
  final TextEditingController originController;
  final TextEditingController destinationController;
  final VoidCallback onSwap;
  final ValueChanged<Map<String, dynamic>> onSelectCorridor;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final VoidCallback onPickDateTime;
  final int selectedSeats;
  final ValueChanged<int> onSeatsChanged;
  final VoidCallback onSearch;
  final List<Map<String, dynamic>> popularCorridors;
  final VoidCallback? onTapPickup;
  final VoidCallback? onTapDestination;
  final ValueChanged<LocationModel>? onOriginLocationSelected;
  final ValueChanged<LocationModel>? onDestinationLocationSelected;
  final bool enableInlineAutocomplete;
  final bool isLoading;
  final VoidCallback? onOpenDateTime;
  final VoidCallback? onOpenPassengers;

  const HeroSearchCard({
    super.key,
    required this.originController,
    required this.destinationController,
    required this.onSwap,
    required this.onSelectCorridor,
    required this.selectedDate,
    required this.selectedTime,
    required this.onPickDateTime,
    required this.selectedSeats,
    required this.onSeatsChanged,
    required this.onSearch,
    this.popularCorridors = const [
      {'from': 'Bhuj', 'to': 'Ahmd', 'price': 150},
      {'from': 'Ahmedabad', 'to': 'Vadodara', 'price': 150},
      {'from': 'Surat', 'to': 'Mumbai', 'price': 380},
      {'from': 'Gandhinagar', 'to': 'Ahmedabad', 'price': 80},
      {'from': 'Rajkot', 'to': 'Ahmedabad', 'price': 250},
    ],
    this.onTapPickup,
    this.onTapDestination,
    this.onOriginLocationSelected,
    this.onDestinationLocationSelected,
    this.enableInlineAutocomplete = true,
    this.isLoading = false,
    this.onOpenDateTime,
    this.onOpenPassengers,
  });

  @override
  State<HeroSearchCard> createState() => _HeroSearchCardState();
}

class _HeroSearchCardState extends State<HeroSearchCard> {
  bool _isSearchPressed = false;

  late final FocusNode _originFocusNode;
  late final FocusNode _destFocusNode;
  _ActiveLocationField _activeField = _ActiveLocationField.none;

  List<LocationModel> _suggestions = [];
  bool _isSearching = false;
  String? _searchError;
  Timer? _debounceTimer;
  bool _isGpsLocating = false;

  static final List<LocationModel> _curatedHubs = [
    const LocationModel(
      name: 'Ahmedabad Junction',
      address: 'Kalupur, Ahmedabad, Gujarat',
      city: 'Ahmedabad',
      latitude: 23.0225,
      longitude: 72.5714,
      placeId: 'hub_amd_junction',
    ),
    const LocationModel(
      name: 'Vadodara Central Bus Station',
      address: 'Sayajigunj, Vadodara, Gujarat',
      city: 'Vadodara',
      latitude: 22.3072,
      longitude: 73.1812,
      placeId: 'hub_vadodara_central',
    ),
    const LocationModel(
      name: 'Surat Central Ring Road',
      address: 'Ring Road, Surat, Gujarat',
      city: 'Surat',
      latitude: 21.1702,
      longitude: 72.8311,
      placeId: 'hub_surat_central',
    ),
    const LocationModel(
      name: 'Rajkot Kalawad Road',
      address: 'Kalawad Road, Rajkot, Gujarat',
      city: 'Rajkot',
      latitude: 22.3039,
      longitude: 70.8022,
      placeId: 'hub_rajkot_kalawad',
    ),
    const LocationModel(
      name: 'Gandhinagar Infocity Hub',
      address: 'Infocity, Gandhinagar, Gujarat',
      city: 'Gandhinagar',
      latitude: 23.2156,
      longitude: 72.6369,
      placeId: 'hub_gnr_infocity',
    ),
    const LocationModel(
      name: 'Bhuj Bus Station',
      address: 'Station Road, Bhuj, Kutch, Gujarat',
      city: 'Bhuj',
      latitude: 23.2420,
      longitude: 69.6669,
      placeId: 'hub_bhuj_bus_station',
    ),
    ...IndiaPopularHubs.popularHubs,
  ];

  @override
  void initState() {
    super.initState();
    _originFocusNode = FocusNode();
    _destFocusNode = FocusNode();
    _originFocusNode.addListener(_handleOriginFocusChange);
    _destFocusNode.addListener(_handleDestFocusChange);
    widget.originController.addListener(_onControllerChange);
    widget.destinationController.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(HeroSearchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originController != widget.originController) {
      oldWidget.originController.removeListener(_onControllerChange);
      widget.originController.addListener(_onControllerChange);
    }
    if (oldWidget.destinationController != widget.destinationController) {
      oldWidget.destinationController.removeListener(_onControllerChange);
      widget.destinationController.addListener(_onControllerChange);
    }
  }

  void _handleOriginFocusChange() {
    if (_originFocusNode.hasFocus) {
      setState(() {
        _activeField = _ActiveLocationField.origin;
      });
      _onQueryChanged(
        widget.originController.text,
        _ActiveLocationField.origin,
      );
    }
  }

  void _handleDestFocusChange() {
    if (_destFocusNode.hasFocus) {
      setState(() {
        _activeField = _ActiveLocationField.destination;
      });
      _onQueryChanged(
        widget.destinationController.text,
        _ActiveLocationField.destination,
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _originFocusNode.removeListener(_handleOriginFocusChange);
    _destFocusNode.removeListener(_handleDestFocusChange);
    widget.originController.removeListener(_onControllerChange);
    widget.destinationController.removeListener(_onControllerChange);
    _originFocusNode.dispose();
    _destFocusNode.dispose();
    super.dispose();
  }

  void _dismissSuggestions() {
    setState(() {
      _activeField = _ActiveLocationField.none;
    });
    _originFocusNode.unfocus();
    _destFocusNode.unfocus();
  }

  void _handleSwap() {
    HapticFeedback.mediumImpact();
    widget.onSwap();
    if (_activeField != _ActiveLocationField.none) {
      final active = _activeField;
      final text = active == _ActiveLocationField.origin
          ? widget.originController.text
          : widget.destinationController.text;
      _onQueryChanged(text, active);
    }
  }

  void _onQueryChanged(String query, _ActiveLocationField field) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();

    if (trimmed.length < 2) {
      setState(() {
        _isSearching = false;
        _searchError = null;
        _suggestions = _curatedHubs;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _fetchPredictions(trimmed);
    });
  }

  Future<void> _fetchPredictions(String input) async {
    if (!mounted) return;
    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final baseUrl = ApiConfig.baseUrl;
      final uri = Uri.parse(
        '$baseUrl/rides/places/autocomplete?input=${Uri.encodeComponent(input)}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true && data['predictions'] is List) {
          final list = (data['predictions'] as List).map((item) {
            final map = item as Map<String, dynamic>;
            final rawName =
                (map['name'] as String?) ?? (map['mainText'] as String?);
            final desc =
                (map['description'] as String?) ??
                (map['secondaryText'] as String?) ??
                input;
            final name = rawName?.trim().isNotEmpty == true
                ? rawName!.trim()
                : desc.split(',').first.trim();
            final cityValue =
                (map['city'] as String?) ??
                (map['cityOrDistrict'] as String?) ??
                (map['secondaryText'] as String?)?.split(',').first.trim();
            final city = cityValue?.isNotEmpty == true
                ? cityValue!
                : AppRegion.fallbackCity;
            final lat =
                (map['latitude'] as num?)?.toDouble() ??
                AppRegion.fallbackLatitude;
            final lng =
                (map['longitude'] as num?)?.toDouble() ??
                AppRegion.fallbackLongitude;
            final placeId = map['placeId'] as String?;

            return LocationModel(
              name: name,
              address: desc,
              city: city,
              latitude: lat,
              longitude: lng,
              placeId: placeId,
            );
          }).toList();

          if (mounted) {
            setState(() {
              _suggestions = list;
              _isSearching = false;
            });
            return;
          }
        }
      }
    } catch (_) {
      // Graceful offline fallback
    }

    if (mounted) {
      final lower = input.toLowerCase();
      final local = _curatedHubs.where((h) {
        return h.name.toLowerCase().contains(lower) ||
            h.city.toLowerCase().contains(lower) ||
            h.address.toLowerCase().contains(lower);
      }).toList();

      setState(() {
        _suggestions = local;
        _isSearching = false;
        if (local.isEmpty) {
          _searchError = 'No transit corridors found for "$input"';
        }
      });
    }
  }

  void _selectSuggestion(LocationModel hub) {
    HapticFeedback.selectionClick();
    if (_activeField == _ActiveLocationField.origin) {
      widget.originController.text = hub.name;
      widget.onOriginLocationSelected?.call(hub);
      setState(() {
        _activeField = _ActiveLocationField.none;
      });
      _originFocusNode.unfocus();
      if (widget.destinationController.text.isEmpty) {
        _destFocusNode.requestFocus();
      }
    } else if (_activeField == _ActiveLocationField.destination) {
      widget.destinationController.text = hub.name;
      widget.onDestinationLocationSelected?.call(hub);
      setState(() {
        _activeField = _ActiveLocationField.none;
      });
      _destFocusNode.unfocus();
    }
  }

  Future<void> _handleGpsCurrentLocation() async {
    setState(() => _isGpsLocating = true);
    final gps = GeolocatorProvider();
    try {
      final serviceEnabled = await gps.isServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device location services are disabled.'),
            backgroundColor: Color(0xFFD32F2F),
          ),
        );
        return;
      }
      var perm = await gps.checkPermission();
      if (perm != LocationPermissionStatus.granted) {
        perm = await gps.requestPermission();
        if (perm != LocationPermissionStatus.granted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required for GPS pickup.'),
              backgroundColor: Color(0xFFD32F2F),
            ),
          );
          return;
        }
      }

      final pos = await gps.getCurrentPosition().timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );
      if (pos != null && mounted) {
        final loc = LocationModel(
          name: 'Current Location',
          address:
              'GPS (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})',
          city: AppRegion.fallbackCity,
          latitude: pos.latitude,
          longitude: pos.longitude,
          placeId: 'gps_current',
        );
        widget.originController.text = loc.name;
        widget.onOriginLocationSelected?.call(loc);
        setState(() {
          _activeField = _ActiveLocationField.none;
        });
        _originFocusNode.unfocus();
        if (widget.destinationController.text.isEmpty) {
          _destFocusNode.requestFocus();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS fix failed: $e'),
            backgroundColor: const Color(0xFFD32F2F),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGpsLocating = false);
      }
      await gps.dispose();
    }
  }

  String _formatDate(DateTime date, BuildContext context) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return context.l10n.today;
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return context.l10n.tomorrow;
    }
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = widget.selectedTime.format(context);
    final formattedDate = _formatDate(widget.selectedDate, context);

    return BentoContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      color: AppColors.white,
      borderSide: const BorderSide(color: AppColors.border, width: 0.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. Header Row: Brand Tag, Title, Subtitle + Route Corridor Badge
          // A. Header Row: Brand Tag, Title, Subtitle + Route Corridor Badge
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: 8,
            runSpacing: 8,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppColors.deepEmerald,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'SAHYĀN',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.deepEmerald,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.whereHeading,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.findRideAlongRoute,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.softMint.withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.deepEmerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      context.l10n.p2pCorridor,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepEmerald,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // B. Unified Connected Journey Location Card
          JourneyLocationCard(
            pickupController: widget.originController,
            destinationController: widget.destinationController,
            pickupFocusNode: _originFocusNode,
            destinationFocusNode: _destFocusNode,
            pickupLabel: 'PICKUP LOCATION',
            destinationLabel: 'DESTINATION HUB',
            pickupPrefix: 'FROM',
            destinationPrefix: 'TO',
            pickupHint: 'Enter pickup hub or address...',
            destinationHint: 'Where to? (Destination)...',
            surfaceColor: const Color(0xFFF8FAF8),
            borderColor: AppColors.border,
            onSwap: _handleSwap,
            onUseCurrentLocation: _handleGpsCurrentLocation,
            isGpsLoading: _isGpsLocating,
            onSelectPickupOnMap: widget.onTapPickup,
            onSelectDestinationOnMap: widget.onTapDestination,
            isPickupReadOnly:
                !widget.enableInlineAutocomplete && widget.onTapPickup != null,
            isDestinationReadOnly: !widget.enableInlineAutocomplete &&
                widget.onTapDestination != null,
            onTapPickup: () {
              if (!widget.enableInlineAutocomplete &&
                  widget.onTapPickup != null) {
                widget.onTapPickup!();
              }
            },
            onTapDestination: () {
              if (!widget.enableInlineAutocomplete &&
                  widget.onTapDestination != null) {
                widget.onTapDestination!();
              }
            },
            onPickupChanged: (val) =>
                _onQueryChanged(val, _ActiveLocationField.origin),
            onDestinationChanged: (val) =>
                _onQueryChanged(val, _ActiveLocationField.destination),
            onPickupClear: () {
              widget.originController.clear();
              _onQueryChanged('', _ActiveLocationField.origin);
              setState(() {});
            },
            onDestinationClear: () {
              widget.destinationController.clear();
              _onQueryChanged('', _ActiveLocationField.destination);
              setState(() {});
            },
          ),

          // C. Connected Suggestions Dropdown Panel
          if (_activeField != _ActiveLocationField.none) ...[
            const SizedBox(height: 8),
            _buildConnectedSuggestionsDropdown(),
          ],

          const SizedBox(height: 14),

          // D. Frequent Highway Corridors
          Row(
            children: [
              Flexible(
                child: Text(
                  context.l10n.frequentCorridors.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mutedText,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.softMint,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: widget.popularCorridors.map((c) {
                final label = '${c['from']} → ${c['to']}';
                final price = '₹${c['price']}';
                final isSelected = widget.originController.text == c['from'] &&
                    widget.destinationController.text == c['to'];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: isSelected
                        ? AppColors.primaryLight
                        : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onSelectCorridor(c);
                        if (_activeField != _ActiveLocationField.none) {
                          _dismissSuggestions();
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      splashColor: AppColors.softMint.withValues(alpha: 0.2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.deepEmerald
                                : AppColors.border,
                            width: isSelected ? 1.2 : 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.deepEmerald
                                    : AppColors.primaryText,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                price,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.deepEmerald,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),

          // E. Separate Tappable Summary Rows for Date/Time & Passengers
          Container(
            decoration: BoxDecoration(
              color: AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Column(
              children: [
                _SummarySelectionRow(
                  icon: Icons.calendar_today_rounded,
                  label: context.l10n.travelDateTime.toUpperCase(),
                  value: '$formattedDate · $formattedTime',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (widget.onOpenDateTime != null) {
                      widget.onOpenDateTime!();
                    } else {
                      widget.onPickDateTime();
                    }
                  },
                ),
                const Divider(
                  height: 1,
                  thickness: 0.8,
                  color: AppColors.border,
                ),
                _SummarySelectionRow(
                  icon: Icons.people_outline_rounded,
                  label: context.l10n.passengers.toUpperCase(),
                  value: context.l10n.seatsCount(widget.selectedSeats),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (widget.onOpenPassengers != null) {
                      widget.onOpenPassengers!();
                    } else {
                      widget.onSeatsChanged(
                        widget.selectedSeats >= 6 ? 1 : widget.selectedSeats + 1,
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // F. Primary Search CTA Button
          GestureDetector(
            onTapDown: (_) => setState(() => _isSearchPressed = true),
            onTapUp: (_) => setState(() => _isSearchPressed = false),
            onTapCancel: () => setState(() => _isSearchPressed = false),
            child: AnimatedScale(
              scale: _isSearchPressed ? 0.98 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: widget.isLoading ? null : widget.onSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepEmerald,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.deepEmerald.withValues(
                      alpha: 0.6,
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: AppColors.softMint,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                context.l10n.findMatchingRides,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedSuggestionsDropdown() {
    final isOrigin = _activeField == _ActiveLocationField.origin;
    final title = isOrigin
        ? 'PICKUP CORRIDORS & HUBS'
        : 'DESTINATION HUBS';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.deepEmerald.withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryText.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOrigin
                          ? Icons.trip_origin_rounded
                          : Icons.location_on_rounded,
                      size: 13,
                      color: AppColors.deepEmerald,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepEmerald,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.deepEmerald,
                            ),
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: _dismissSuggestions,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.lightSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Origin Quick Action: GPS Location Tile
          if (isOrigin) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: Material(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _isGpsLocating ? null : _handleGpsCurrentLocation,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: _isGpsLocating
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        AppColors.deepEmerald,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location_rounded,
                                    size: 15,
                                    color: AppColors.deepEmerald,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Use Current GPS Location',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepEmerald,
                                ),
                              ),
                              Text(
                                'Detect exact nearby pickup point via device GPS',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 10.5,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.mutedText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Divider(
              height: 12,
              thickness: 0.6,
              color: AppColors.border,
            ),
          ],

          // Suggestions List / States
          if (_suggestions.isEmpty && !_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  _searchError ?? 'No matching corridors found',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: _suggestions.length > 5 ? 5 : _suggestions.length,
              separatorBuilder: (ctx, idx) => const Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.border,
              ),
              itemBuilder: (context, index) {
                final hub = _suggestions[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _selectSuggestion(hub),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.lightSurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.border,
                                width: 0.6,
                              ),
                            ),
                            child: const Icon(
                              Icons.place_outlined,
                              size: 17,
                              color: AppColors.deepEmerald,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hub.name,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryText,
                                    letterSpacing: -0.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  hub.address,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 11,
                                    color: AppColors.mutedText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              hub.city,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.deepEmerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// Tappable Selection Summary Row for Date/Time and Passenger selection.
class _SummarySelectionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SummarySelectionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppColors.deepEmerald,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
