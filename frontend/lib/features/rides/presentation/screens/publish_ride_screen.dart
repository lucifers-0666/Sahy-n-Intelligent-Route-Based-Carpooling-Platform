import 'package:flutter/material.dart';
import 'package:sahyan/features/rides/presentation/screens/offer_ride_screen.dart';

export 'package:sahyan/features/rides/presentation/screens/offer_ride_screen.dart';

/// Screen for publishing and offering carpool rides on Sahyān.
///
/// Features the canonical 3-step wizard workflow (Vehicle & Route, Schedule & Seats,
/// Review & Publish) with live OSRM polyline rendering and fare telemetry.
class PublishRideScreen extends StatelessWidget {
  const PublishRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OfferRideScreen();
  }
}
