import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/shared/models/location_model.dart';

/// Pre-curated, verified Gujarat highway transport hubs and intercity nodes
class GujaratCorridorHubs {
  static const List<LocationModel> popularHubs = [
    LocationModel(
      name: 'Iscon Cross Roads',
      address: 'Iscon Cross Roads, SG Highway, Ahmedabad',
      city: 'Ahmedabad',
      latitude: 23.0270,
      longitude: 72.5080,
      placeId: 'hub_amd_iscon',
    ),
    LocationModel(
      name: 'Kalawad Road',
      address: 'Kalawad Road, KKV Hall Jn, Rajkot',
      city: 'Rajkot',
      latitude: 22.2850,
      longitude: 70.7720,
      placeId: 'hub_raj_kalawad',
    ),
    LocationModel(
      name: 'Majura Gate',
      address: 'Majura Gate, Ring Road, Surat',
      city: 'Surat',
      latitude: 21.1764,
      longitude: 72.8223,
      placeId: 'hub_sur_majura',
    ),
    LocationModel(
      name: 'Alkapuri',
      address: 'Alkapuri, RC Dutt Road, Vadodara',
      city: 'Vadodara',
      latitude: 22.3072,
      longitude: 73.1812,
      placeId: 'hub_bdq_alkapuri',
    ),
    LocationModel(
      name: 'Jubilee Ground',
      address: 'Jubilee Ground, Station Road, Bhuj',
      city: 'Bhuj',
      latitude: 23.2420,
      longitude: 69.6669,
      placeId: 'hub_bhuj_jubilee',
    ),
    LocationModel(
      name: 'GIFT City',
      address: 'GIFT City Tower 1, Gandhinagar',
      city: 'Gandhinagar',
      latitude: 23.1610,
      longitude: 72.6840,
      placeId: 'hub_gnr_gift',
    ),
    LocationModel(
      name: 'Limbdi Toll Plaza',
      address: 'NH47 Limbdi Bypass, Limbdi',
      city: 'Limbdi',
      latitude: 22.5645,
      longitude: 71.8080,
      placeId: 'hub_lmb_toll',
    ),
    LocationModel(
      name: 'Chotila Highway Circle',
      address: 'NH47 Chotila Junction, Chotila',
      city: 'Chotila',
      latitude: 22.4225,
      longitude: 71.1925,
      placeId: 'hub_cht_circle',
    ),
  ];
}

class LocationSearchBottomSheet extends StatefulWidget {
  final String title;
  final String? initialQuery;
  final bool isPickup;

  const LocationSearchBottomSheet({
    super.key,
    this.title = 'Select Location',
    this.initialQuery,
    this.isPickup = true,
  });

  static Future<LocationModel?> show({
    required BuildContext context,
    String title = 'Select Location',
    String? initialQuery,
    bool isPickup = true,
  }) {
    return showModalBottomSheet<LocationModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationSearchBottomSheet(
        title: title,
        initialQuery: initialQuery,
        isPickup: isPickup,
      ),
    );
  }

  @override
  State<LocationSearchBottomSheet> createState() =>
      _LocationSearchBottomSheetState();
}

class _LocationSearchBottomSheetState extends State<LocationSearchBottomSheet> {
  late final TextEditingController _searchController;
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _query = widget.initialQuery ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<LocationModel> get _filteredResults {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return GujaratCorridorHubs.popularHubs;
    }

    final matched = GujaratCorridorHubs.popularHubs.where((hub) {
      return hub.name.toLowerCase().contains(query) ||
          hub.address.toLowerCase().contains(query) ||
          hub.city.toLowerCase().contains(query);
    }).toList();

    // If query does not match any known hub, offer ad-hoc custom location
    if (matched.isEmpty) {
      return [
        LocationModel(
          name: _query.trim(),
          address: '${_query.trim()}, Gujarat',
          city: 'Gujarat',
          latitude: 23.0225,
          longitude: 72.5714,
          placeId: 'custom_${_query.hashCode.abs()}',
        ),
      ];
    }
    return matched;
  }

  Future<void> _handleUseCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled on your device.'),
            backgroundColor: SahyanColors.urgentCoral,
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission was denied.'),
              backgroundColor: SahyanColors.urgentCoral,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied. Please enable in Settings.'),
            backgroundColor: SahyanColors.urgentCoral,
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );

      final currentLoc = LocationModel(
        name: 'Current Location',
        address: 'GPS (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})',
        city: 'Current Area',
        latitude: position.latitude,
        longitude: position.longitude,
        placeId: 'gps_current',
      );

      if (mounted) {
        Navigator.of(context).pop(currentLoc);
      }
    } catch (e) {
      // Fallback to Ahmedabad hub if location resolution fails
      if (mounted) {
        const fallback = LocationModel(
          name: 'Current Location (Ahmedabad)',
          address: 'SG Highway, Ahmedabad, Gujarat',
          city: 'Ahmedabad',
          latitude: 23.0270,
          longitude: 72.5080,
          placeId: 'gps_fallback',
        );
        Navigator.of(context).pop(fallback);
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: SahyanColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: SahyanColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: widget.isPickup
                            ? SahyanColors.primaryDark
                            : SahyanColors.primaryMint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: SahyanColors.textMain,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: SahyanColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: SahyanColors.canvas,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SahyanColors.border, width: 0.8),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: SahyanColors.textMain,
                ),
                decoration: InputDecoration(
                  hintText: 'Search city, landmark, or corridor...',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: SahyanColors.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: SahyanColors.primaryDark,
                    size: 22,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel, size: 18, color: SahyanColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (val) {
                  setState(() => _query = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // "Use Current Location" Tactile Capsule
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Material(
              color: SahyanColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _isLocating ? null : _handleUseCurrentLocation,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: SahyanColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: _isLocating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: SahyanColors.primaryDark,
                                ),
                              )
                            : const Icon(
                                Icons.my_location_rounded,
                                size: 16,
                                color: SahyanColors.primaryDark,
                              ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Use Current GPS Location',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: SahyanColors.primaryDark,
                              ),
                            ),
                            Text(
                              'Accurate pickup detection via device GPS',
                              style: TextStyle(
                                fontSize: 11,
                                color: SahyanColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: SahyanColors.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Section Header: Popular Gujarat Corridors
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text(
                  _query.isEmpty ? 'POPULAR GUJARAT CORRIDORS' : 'SEARCH RESULTS',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: SahyanColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Corridor / Autocomplete List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _filteredResults.length,
              separatorBuilder: (ctx, idx) => const Divider(
                color: SahyanColors.border,
                height: 1,
                thickness: 0.6,
              ),
              itemBuilder: (ctx, idx) {
                final hub = _filteredResults[idx];
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: SahyanColors.chipBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: SahyanColors.border,
                          width: 0.6,
                        ),
                      ),
                      child: const Icon(
                        Icons.place_outlined,
                        size: 20,
                        color: SahyanColors.primaryDark,
                      ),
                    ),
                    title: Text(
                      hub.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: SahyanColors.textMain,
                      ),
                    ),
                    subtitle: Text(
                      hub.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: SahyanColors.textMuted,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: SahyanColors.canvas,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: SahyanColors.border,
                          width: 0.6,
                        ),
                      ),
                      child: Text(
                        hub.city,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: SahyanColors.primaryDark,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop(hub);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
