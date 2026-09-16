import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/features/bookings/domain/booking_model.dart';
import 'package:sahyan/features/payments/presentation/screens/payment_checkout_screen.dart';
import 'package:sahyan/shared/models/location_model.dart';

void main() {
  group('Phase 7 – Payment Gateway & Escrow Settlement', () {
    final testBooking = BookingModel(
      id: 'book-789',
      rideId: 'ride-123',
      passengerId: 'user-456',
      requestedSeats: 2,
      contributionPerSeat: 300.0,
      totalContribution: 600.0,
      status: BookingStatus.accepted,
      paymentStatus: 'pending',
      pickup: LocationModel.fromCoordinates(
        name: 'Ahmedabad Airport',
        latitude: 23.0225,
        longitude: 72.5714,
      ),
      drop: LocationModel.fromCoordinates(
        name: 'Rajkot Bus Stand',
        latitude: 22.3039,
        longitude: 70.8022,
      ),
      createdAt: DateTime.now(),
    );

    test('T1: BookingModel payment fields and isPaid helper', () {
      expect(testBooking.isPaid, isFalse);
      expect(testBooking.paymentStatus, 'pending');

      final paidBooking = BookingModel(
        id: testBooking.id,
        rideId: testBooking.rideId,
        passengerId: testBooking.passengerId,
        requestedSeats: testBooking.requestedSeats,
        contributionPerSeat: testBooking.contributionPerSeat,
        totalContribution: testBooking.totalContribution,
        status: testBooking.status,
        paymentStatus: 'paid',
        paymentTransactionId: 'tx-999',
        pickup: testBooking.pickup,
        drop: testBooking.drop,
        createdAt: testBooking.createdAt,
      );

      expect(paidBooking.isPaid, isTrue);
      expect(paidBooking.paymentTransactionId, 'tx-999');

      final escrowReleasedBooking = BookingModel(
        id: testBooking.id,
        rideId: testBooking.rideId,
        passengerId: testBooking.passengerId,
        requestedSeats: testBooking.requestedSeats,
        contributionPerSeat: testBooking.contributionPerSeat,
        totalContribution: testBooking.totalContribution,
        status: BookingStatus.completed,
        paymentStatus: 'escrow_released',
        pickup: testBooking.pickup,
        drop: testBooking.drop,
        createdAt: testBooking.createdAt,
      );

      expect(escrowReleasedBooking.isPaid, isTrue);
    });

    test('T2: BookingModel JSON serialization includes payment fields', () {
      final json = testBooking.toJson();
      expect(json['paymentStatus'], 'pending');

      final deserialized = BookingModel.fromJson(json);
      expect(deserialized.paymentStatus, 'pending');
      expect(deserialized.isPaid, isFalse);
    });

    testWidgets('T3: PaymentCheckoutScreen renders breakdown and escrow banner',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PaymentCheckoutScreen(booking: testBooking),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Escrow assurance
      expect(find.text('Sahyān Escrow Protection'), findsOneWidget);

      // Fare Breakdown (Base: 600, Platform: 20, Toll: 40 -> Total: 660)
      expect(find.text('₹600'), findsOneWidget);
      expect(find.text('₹20'), findsOneWidget);
      expect(find.text('₹40'), findsOneWidget);
      expect(find.text('₹660'), findsOneWidget);

      // Payment options
      expect(find.text('UPI Instant (GPay / PhonePe / Paytm)'), findsOneWidget);
      expect(find.text('Credit / Debit Card'), findsOneWidget);
      expect(find.text('Net Banking'), findsOneWidget);
    });
  });
}
