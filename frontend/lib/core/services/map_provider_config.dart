import 'package:flutter/material.dart';

/// Supported production map tile styles
enum MapProviderType {
  /// Clean, high-legibility vector-styled raster tiles optimal for mobility & routing
  cartoPositron,

  /// Detailed road and landmark tiles with subtle colored terrain
  cartoVoyager,

  /// Canonical OpenStreetMap standard tiles
  osmStandard,

  /// High-contrast dark theme tiles for night journeys
  cartoDark,
}

/// Metadata and tile configuration for a map provider
class MapTileConfig {
  final MapProviderType type;
  final String displayName;
  final String urlTemplate;
  final List<String> subdomains;
  final int maxZoom;
  final String attributionText;
  final String userAgentPackageName;
  final Color backgroundColor;

  const MapTileConfig({
    required this.type,
    required this.displayName,
    required this.urlTemplate,
    this.subdomains = const ['a', 'b', 'c', 'd'],
    this.maxZoom = 19,
    required this.attributionText,
    this.userAgentPackageName = 'com.sahyan.sahyan',
    this.backgroundColor = const Color(0xFFF1F5F9),
  });
}

/// Centralized Map Provider Abstraction for Sahyān.
///
/// Decouples UI widgets, GPS telematics, and ride search from any single tile source.
/// Allows dynamic runtime switching, custom tile endpoints, and graceful failover.
class MapProviderConfig {
  static MapProviderType _currentProvider = MapProviderType.cartoVoyager;

  static MapProviderType get currentProvider => _currentProvider;

  static void setProvider(MapProviderType type) {
    _currentProvider = type;
  }

  /// Preset configurations with verified OpenStreetMap and CARTO licenses
  static final Map<MapProviderType, MapTileConfig> providers = {
    MapProviderType.cartoVoyager: const MapTileConfig(
      type: MapProviderType.cartoVoyager,
      displayName: 'Sahyān Road',
      urlTemplate:
          'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
      subdomains: ['a', 'b', 'c', 'd'],
      maxZoom: 20,
      attributionText: '© OpenStreetMap contributors, © CARTO',
      backgroundColor: Color(0xFFF8FAFC),
    ),
    MapProviderType.cartoPositron: const MapTileConfig(
      type: MapProviderType.cartoPositron,
      displayName: 'Clean Navigation',
      urlTemplate:
          'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
      subdomains: ['a', 'b', 'c', 'd'],
      maxZoom: 20,
      attributionText: '© OpenStreetMap contributors, © CARTO',
      backgroundColor: Color(0xFFF1F5F9),
    ),
    MapProviderType.osmStandard: const MapTileConfig(
      type: MapProviderType.osmStandard,
      displayName: 'OpenStreetMap',
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: [],
      maxZoom: 19,
      attributionText: '© OpenStreetMap contributors',
      backgroundColor: Color(0xFFE2E8F0),
    ),
    MapProviderType.cartoDark: const MapTileConfig(
      type: MapProviderType.cartoDark,
      displayName: 'Night Voyage',
      urlTemplate:
          'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
      subdomains: ['a', 'b', 'c', 'd'],
      maxZoom: 20,
      attributionText: '© OpenStreetMap contributors, © CARTO',
      backgroundColor: Color(0xFF0F172A),
    ),
  };

  /// Get active tile configuration
  static MapTileConfig get activeConfig =>
      providers[_currentProvider] ?? providers[MapProviderType.cartoVoyager]!;

  /// Get tile configuration tailored for current app brightness
  static MapTileConfig configForBrightness(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return providers[MapProviderType.cartoDark]!;
    }
    return activeConfig;
  }
}
