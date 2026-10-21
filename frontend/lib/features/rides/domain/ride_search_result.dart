import 'package:equatable/equatable.dart';
import 'package:sahyan/shared/models/ride_model.dart';

class RouteMatchFactors extends Equatable {
  final int routeOverlap;
  final int pickupDeviation;
  final int destinationDeviation;
  final int timeCompatibility;
  final int driverReliability;
  final int seatAvailability;

  const RouteMatchFactors({
    required this.routeOverlap,
    required this.pickupDeviation,
    required this.destinationDeviation,
    required this.timeCompatibility,
    required this.driverReliability,
    required this.seatAvailability,
  });

  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  factory RouteMatchFactors.fromJson(Map<String, dynamic> json) {
    return RouteMatchFactors(
      routeOverlap: _parseInt(json['routeOverlap'], 0),
      pickupDeviation: _parseInt(json['pickupDeviation'], 0),
      destinationDeviation: _parseInt(json['destinationDeviation'], 0),
      timeCompatibility: _parseInt(json['timeCompatibility'], 0),
      driverReliability: _parseInt(json['driverReliability'], 0),
      seatAvailability: _parseInt(json['seatAvailability'], 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routeOverlap': routeOverlap,
      'pickupDeviation': pickupDeviation,
      'destinationDeviation': destinationDeviation,
      'timeCompatibility': timeCompatibility,
      'driverReliability': driverReliability,
      'seatAvailability': seatAvailability,
    };
  }

  @override
  List<Object?> get props => [
    routeOverlap,
    pickupDeviation,
    destinationDeviation,
    timeCompatibility,
    driverReliability,
    seatAvailability,
  ];
}

class RouteMatchMetrics extends Equatable {
  final int routeOverlapPercentage;
  final double pickupDistanceKm;
  final double destinationDistanceKm;
  final int departureDifferenceMinutes;

  const RouteMatchMetrics({
    required this.routeOverlapPercentage,
    required this.pickupDistanceKm,
    required this.destinationDistanceKm,
    required this.departureDifferenceMinutes,
  });

  static double _parseDouble(dynamic val, [double fallback = 0.0]) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? fallback;
    return fallback;
  }

  factory RouteMatchMetrics.fromJson(Map<String, dynamic> json) {
    return RouteMatchMetrics(
      routeOverlapPercentage: RouteMatchFactors._parseInt(
        json['routeOverlapPercentage'],
        0,
      ),
      pickupDistanceKm: _parseDouble(json['pickupDistanceKm'], 0.0),
      destinationDistanceKm: _parseDouble(json['destinationDistanceKm'], 0.0),
      departureDifferenceMinutes: RouteMatchFactors._parseInt(
        json['departureDifferenceMinutes'],
        0,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routeOverlapPercentage': routeOverlapPercentage,
      'pickupDistanceKm': pickupDistanceKm,
      'destinationDistanceKm': destinationDistanceKm,
      'departureDifferenceMinutes': departureDifferenceMinutes,
    };
  }

  @override
  List<Object?> get props => [
    routeOverlapPercentage,
    pickupDistanceKm,
    destinationDistanceKm,
    departureDifferenceMinutes,
  ];
}

class RouteMatchDetails extends Equatable {
  final int score;
  final String grade;
  final RouteMatchFactors factors;
  final RouteMatchMetrics metrics;
  final List<String> reasons;

  const RouteMatchDetails({
    required this.score,
    required this.grade,
    required this.factors,
    required this.metrics,
    required this.reasons,
  });

  factory RouteMatchDetails.fromJson(Map<String, dynamic> json) {
    final rawFactors = json['factors'] is Map
        ? Map<String, dynamic>.from(json['factors'] as Map)
        : <String, dynamic>{};
    final rawMetrics = json['metrics'] is Map
        ? Map<String, dynamic>.from(json['metrics'] as Map)
        : <String, dynamic>{};
    final rawReasons =
        (json['reasons'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    return RouteMatchDetails(
      score: RouteMatchFactors._parseInt(json['score'], 0),
      grade: json['grade']?.toString() ?? 'Available Match',
      factors: RouteMatchFactors.fromJson(rawFactors),
      metrics: RouteMatchMetrics.fromJson(rawMetrics),
      reasons: rawReasons,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'grade': grade,
      'factors': factors.toJson(),
      'metrics': metrics.toJson(),
      'reasons': reasons,
    };
  }

  @override
  List<Object?> get props => [score, grade, factors, metrics, reasons];
}

class RideSearchResult extends Equatable {
  final RideModel ride;
  final double pickupDistanceKm;
  final double destinationDistanceKm;
  final int departureDifferenceMinutes;
  final int availableSeats;
  final String matchPreview;
  final RouteMatchDetails? match;

  const RideSearchResult({
    required this.ride,
    required this.pickupDistanceKm,
    required this.destinationDistanceKm,
    required this.departureDifferenceMinutes,
    required this.availableSeats,
    required this.matchPreview,
    this.match,
  });

  int get matchScore => match?.score ?? 0;
  String get matchGrade => match?.grade ?? 'Available Route';
  List<String> get matchReasons => match?.reasons ?? const [];
  bool get hasMatch => match != null;

  factory RideSearchResult.fromJson(Map<String, dynamic> json) {
    final rawRide = json['ride'] is Map
        ? Map<String, dynamic>.from(json['ride'] as Map)
        : json;

    final rawMatch = json['match'] is Map
        ? Map<String, dynamic>.from(json['match'] as Map)
        : null;
    final parsedMatch = rawMatch != null
        ? RouteMatchDetails.fromJson(rawMatch)
        : null;

    final rawPickup =
        json['pickupDistanceKm'] ?? parsedMatch?.metrics.pickupDistanceKm;
    final pickupDist = rawPickup is num
        ? rawPickup.toDouble()
        : (double.tryParse(rawPickup?.toString() ?? '') ?? 0.0);

    final rawDest =
        json['destinationDistanceKm'] ?? parsedMatch?.metrics.destinationDistanceKm;
    final destDist = rawDest is num
        ? rawDest.toDouble()
        : (double.tryParse(rawDest?.toString() ?? '') ?? 0.0);

    final rawDepDiff =
        json['departureDifferenceMinutes'] ??
        parsedMatch?.metrics.departureDifferenceMinutes;
    final depDiff = rawDepDiff is num
        ? rawDepDiff.toInt()
        : (int.tryParse(rawDepDiff?.toString() ?? '') ?? 0);

    final rawSeats = json['availableSeats'] ?? rawRide['availableSeats'];
    final seats = rawSeats is num
        ? rawSeats.toInt()
        : (int.tryParse(rawSeats?.toString() ?? '') ?? 1);

    return RideSearchResult(
      ride: RideModel.fromJson(rawRide),
      pickupDistanceKm: pickupDist,
      destinationDistanceKm: destDist,
      departureDifferenceMinutes: depDiff,
      availableSeats: seats,
      matchPreview: json['matchPreview']?.toString() ?? 'Available Route',
      match: parsedMatch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ride': ride.toJson(),
      'pickupDistanceKm': pickupDistanceKm,
      'destinationDistanceKm': destinationDistanceKm,
      'departureDifferenceMinutes': departureDifferenceMinutes,
      'availableSeats': availableSeats,
      'matchPreview': matchPreview,
      if (match != null) 'match': match!.toJson(),
    };
  }

  @override
  List<Object?> get props => [
    ride,
    pickupDistanceKm,
    destinationDistanceKm,
    departureDifferenceMinutes,
    availableSeats,
    matchPreview,
    match,
  ];
}
