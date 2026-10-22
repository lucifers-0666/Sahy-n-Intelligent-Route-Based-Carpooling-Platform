import 'package:flutter/material.dart';

/// Supported production map tile styles
enum MapProviderType {
  /// Canonical OpenStreetMap standard tiles (100% free, unwatermarked)
  osmStandard,

  /// Humanitarian OpenStreetMap Team style (high-legibility colored roads & terrain, 100% free)
  osmHot,

  /// Satellite aerial imagery (ESRI World Imagery, 100% free, high-resolution)
  satellite,

  /// Topographic terrain and cycling/elevation roads
  cyclosm,

  /// Clean, high-legibility vector-styled raster tiles optimal for mobility & routing
  cartoPositron,

  /// Detailed road and landmark tiles with subtle colored terrain
  cartoVoyager,

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
/// Guarantees that the active tile layer is 100% un-watermarked, free, and accessible.
class MapProviderConfig {
  /// Optional CARTO API key if commercial CARTO basemaps are configured:
  /// flutter run --dart-define=CARTO_API_KEY=your_key_here
  static const String _envCartoKey = String.fromEnvironment('CARTO_API_KEY');
  static String _runtimeCartoKey = '';

  static void setCartoApiKey(String key) {
    _runtimeCartoKey = key.trim();
  }

  static String get cartoApiKey =>
      _runtimeCartoKey.isNotEmpty ? _runtimeCartoKey : _envCartoKey;

  static bool get hasCartoKey => cartoApiKey.isNotEmpty;

  /// Default provider is Sahyān Road (CARTO Voyager) — high-legibility road navigation.
  static MapProviderType _currentProvider = MapProviderType.cartoVoyager;

  static MapProviderType get currentProvider => _currentProvider;

  static void setProvider(MapProviderType type) {
    _currentProvider = type;
  }

  /// Preset configurations with verified OpenStreetMap and CARTO licenses
  static Map<MapProviderType, MapTileConfig> get providers => {
    MapProviderType.cartoVoyager: MapTileConfig(
      type: MapProviderType.cartoVoyager,
      displayName: 'Sahyān Road',
      urlTemplate: hasCartoKey
          ? 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png?api_key=$cartoApiKey'
          : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      maxZoom: 19,
      attributionText: '© OpenStreetMap contributors, © CARTO',
      backgroundColor: const Color(0xFFF8FAFC),
    ),
    MapProviderType.cartoPositron: MapTileConfig(
      type: MapProviderType.cartoPositron,
      displayName: 'Clean Navigation',
      urlTemplate: hasCartoKey
          ? 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png?api_key=$cartoApiKey'
          : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      maxZoom: 19,
      attributionText: '© OpenStreetMap contributors, © CARTO',
      backgroundColor: const Color(0xFFF1F5F9),
    ),
    MapProviderType.cartoDark: MapTileConfig(
      type: MapProviderType.cartoDark,
      displayName: 'Night Voyage',
      urlTemplate: hasCartoKey
          ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png?api_key=$cartoApiKey'
          : 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      maxZoom: 19,
      attributionText: '© OpenStreetMap contributors, © CARTO',
      backgroundColor: const Color(0xFF0F172A),
    ),
    MapProviderType.osmStandard: const MapTileConfig(
      type: MapProviderType.osmStandard,
      displayName: 'OpenStreetMap',
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: [],
      maxZoom: 19,
      attributionText: '© OpenStreetMap contributors',
      userAgentPackageName: 'com.sahyan.app/1.0 (contact@sahyan.app)',
      backgroundColor: Color(0xFFE2E8F0),
    ),
    MapProviderType.osmHot: const MapTileConfig(
      type: MapProviderType.osmHot,
      displayName: 'Sahyān High-Contrast',
      urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
      subdomains: ['a', 'b', 'c'],
      maxZoom: 19,
      attributionText: '© OpenStreetMap contributors, HOT style',
      userAgentPackageName: 'com.sahyan.app/1.0 (contact@sahyan.app)',
      backgroundColor: Color(0xFFF8FAFC),
    ),
    MapProviderType.satellite: const MapTileConfig(
      type: MapProviderType.satellite,
      displayName: 'Satellite Aerial',
      urlTemplate:
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      subdomains: [],
      maxZoom: 19,
      attributionText: '© Esri, Maxar, Earthstar Geographics, OpenStreetMap',
      backgroundColor: Color(0xFF0F172A),
    ),
    MapProviderType.cyclosm: const MapTileConfig(
      type: MapProviderType.cyclosm,
      displayName: 'Topographic Terrain',
      urlTemplate:
          'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
      subdomains: ['a', 'b', 'c'],
      maxZoom: 18,
      attributionText: '© OpenStreetMap contributors, CyclOSM',
      backgroundColor: Color(0xFFE2E8F0),
    ),
  };

  /// Get active tile configuration
  static MapTileConfig get activeConfig =>
      providers[_currentProvider] ?? providers[MapProviderType.osmStandard]!;

  /// Get tile configuration tailored for current app brightness
  static MapTileConfig configForBrightness(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return providers[MapProviderType.cartoDark]!;
    }
    return activeConfig;
  }
}
