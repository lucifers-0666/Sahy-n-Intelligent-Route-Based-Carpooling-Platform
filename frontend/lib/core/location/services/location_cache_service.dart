import '../domain/models/location_point.dart';

/// In-memory & local cache for last known GPS coordinates and routes
class LocationCacheService {
  LocationCacheService._internal();
  static final LocationCacheService instance = LocationCacheService._internal();

  LocationPoint? _lastKnownLocation;
  DateTime? _lastLocationTime;

  LocationPoint? get lastKnownLocation => _lastKnownLocation;
  DateTime? get lastLocationTime => _lastLocationTime;

  bool get hasLocation => _lastKnownLocation != null;

  int get locationAgeSeconds {
    if (_lastLocationTime == null) return 999999;
    return DateTime.now().difference(_lastLocationTime!).inSeconds;
  }

  void saveLocation(LocationPoint point) {
    _lastKnownLocation = point;
    _lastLocationTime = DateTime.now();
  }

  void clear() {
    _lastKnownLocation = null;
    _lastLocationTime = null;
  }
}
