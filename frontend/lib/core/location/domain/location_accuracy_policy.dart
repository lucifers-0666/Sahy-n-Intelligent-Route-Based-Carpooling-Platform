enum LocationAccuracyTier {
  excellent,
  good,
  acceptable,
  poor,
  invalid,
}

/// Centralized policy for GPS accuracy thresholding and confidence classification
class LocationAccuracyPolicy {
  static const double kExcellentThresholdMeters = 10.0;
  static const double kGoodThresholdMeters = 20.0;
  static const double kAcceptableThresholdMeters = 50.0;
  static const double kInvalidThresholdMeters = 100.0;

  /// Classify accuracy in meters into confidence tier
  static LocationAccuracyTier classify(double accuracyMeters) {
    if (accuracyMeters <= kExcellentThresholdMeters) {
      return LocationAccuracyTier.excellent;
    }
    if (accuracyMeters <= kGoodThresholdMeters) {
      return LocationAccuracyTier.good;
    }
    if (accuracyMeters <= kAcceptableThresholdMeters) {
      return LocationAccuracyTier.acceptable;
    }
    if (accuracyMeters <= kInvalidThresholdMeters) {
      return LocationAccuracyTier.poor;
    }
    return LocationAccuracyTier.invalid;
  }

  /// Check if accuracy is suitable for precision pickup/drop confirmation (<= 20m)
  static bool isAcceptableForPickup(double accuracyMeters) {
    return accuracyMeters <= kGoodThresholdMeters;
  }

  /// Check if accuracy is acceptable for live ride tracking (<= 50m)
  static bool isAcceptableForTracking(double accuracyMeters) {
    return accuracyMeters <= kAcceptableThresholdMeters;
  }

  /// Human readable label for accuracy tier
  static String getTierLabel(LocationAccuracyTier tier) {
    switch (tier) {
      case LocationAccuracyTier.excellent:
        return 'High Accuracy (<=10m)';
      case LocationAccuracyTier.good:
        return 'Good Accuracy (<=20m)';
      case LocationAccuracyTier.acceptable:
        return 'Acceptable (<=50m)';
      case LocationAccuracyTier.poor:
        return 'Degraded (>50m)';
      case LocationAccuracyTier.invalid:
        return 'Invalid (>100m)';
    }
  }
}
