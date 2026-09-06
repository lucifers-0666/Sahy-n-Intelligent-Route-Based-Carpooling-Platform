import 'package:equatable/equatable.dart';
import 'package:sahyan/shared/models/ride_model.dart';

class RideSearchResult extends Equatable {
  final RideModel ride;
  final double pickupDistanceKm;
  final double destinationDistanceKm;
  final int departureDifferenceMinutes;
  final int availableSeats;
  final String matchPreview;

  const RideSearchResult({
    required this.ride,
    required this.pickupDistanceKm,
    required this.destinationDistanceKm,
    required this.departureDifferenceMinutes,
    required this.availableSeats,
    required this.matchPreview,
  });

  factory RideSearchResult.fromJson(Map<String, dynamic> json) {
    final rawRide = json['ride'] is Map<String, dynamic>
        ? json['ride'] as Map<String, dynamic>
        : json;

    return RideSearchResult(
      ride: RideModel.fromJson(rawRide),
      pickupDistanceKm: (json['pickupDistanceKm'] as num?)?.toDouble() ?? 0.0,
      destinationDistanceKm:
          (json['destinationDistanceKm'] as num?)?.toDouble() ?? 0.0,
      departureDifferenceMinutes:
          (json['departureDifferenceMinutes'] as num?)?.toInt() ?? 0,
      availableSeats:
          (json['availableSeats'] as num?)?.toInt() ??
          (rawRide['availableSeats'] as num?)?.toInt() ??
          1,
      matchPreview: json['matchPreview'] as String? ?? 'Available Route',
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
  ];
}
