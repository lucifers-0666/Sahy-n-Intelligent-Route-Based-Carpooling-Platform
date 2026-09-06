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

  factory RouteMatchFactors.fromJson(Map<String, dynamic> json) {
    return RouteMatchFactors(
      routeOverlap: (json['routeOverlap'] as num?)?.toInt() ?? 0,
      pickupDeviation: (json['pickupDeviation'] as num?)?.toInt() ?? 0,
      destinationDeviation:
          (json['destinationDeviation'] as num?)?.toInt() ?? 0,
      timeCompatibility: (json['timeCompatibility'] as num?)?.toInt() ?? 0,
      driverReliability: (json['driverReliability'] as num?)?.toInt() ?? 0,
      seatAvailability: (json['seatAvailability'] as num?)?.toInt() ?? 0,
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

  factory RouteMatchMetrics.fromJson(Map<String, dynamic> json) {
    return RouteMatchMetrics(
      routeOverlapPercentage:
          (json['routeOverlapPercentage'] as num?)?.toInt() ?? 0,
      pickupDistanceKm: (json['pickupDistanceKm'] as num?)?.toDouble() ?? 0.0,
      destinationDistanceKm:
          (json['destinationDistanceKm'] as num?)?.toDouble() ?? 0.0,
      departureDifferenceMinutes:
          (json['departureDifferenceMinutes'] as num?)?.toInt() ?? 0,
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
    final rawFactors = json['factors'] as Map<String, dynamic>? ?? {};
    final rawMetrics = json['metrics'] as Map<String, dynamic>? ?? {};
    final rawReasons =
        (json['reasons'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    return RouteMatchDetails(
      score: (json['score'] as num?)?.toInt() ?? 0,
      grade: json['grade'] as String? ?? 'Available Match',
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
    final rawRide = json['ride'] is Map<String, dynamic>
        ? json['ride'] as Map<String, dynamic>
        : json;

    final rawMatch = json['match'] as Map<String, dynamic>?;
    final parsedMatch = rawMatch != null
        ? RouteMatchDetails.fromJson(rawMatch)
        : null;

    final pickupDist =
        (json['pickupDistanceKm'] as num?)?.toDouble() ??
        parsedMatch?.metrics.pickupDistanceKm ??
        0.0;
    final destDist =
        (json['destinationDistanceKm'] as num?)?.toDouble() ??
        parsedMatch?.metrics.destinationDistanceKm ??
        0.0;
    final depDiff =
        (json['departureDifferenceMinutes'] as num?)?.toInt() ??
        parsedMatch?.metrics.departureDifferenceMinutes ??
        0;

    return RideSearchResult(
      ride: RideModel.fromJson(rawRide),
      pickupDistanceKm: pickupDist,
      destinationDistanceKm: destDist,
      departureDifferenceMinutes: depDiff,
      availableSeats:
          (json['availableSeats'] as num?)?.toInt() ??
          (rawRide['availableSeats'] as num?)?.toInt() ??
          1,
      matchPreview: json['matchPreview'] as String? ?? 'Available Route',
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
