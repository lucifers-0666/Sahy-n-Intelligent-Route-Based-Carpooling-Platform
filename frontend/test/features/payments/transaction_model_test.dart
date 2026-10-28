import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/features/payments/domain/transaction_model.dart';

void main() {
  group('TransactionModel Serialization', () {
    test('parses from valid backend JSON payload', () {
      final json = {
        '_id': 'tx_998877',
        'bookingId': 'book_123',
        'rideId': 'ride_456',
        'amount': 285.50,
        'currency': 'INR',
        'status': 'escrow_held',
        'paymentMethod': 'upi',
        'gatewayReference': 'pay_sim_00192',
        'gatewayOrderId': 'order_sahyan_981',
        'isSandbox': true,
        'createdAt': '2026-10-28T10:00:00.000Z',
      };

      final tx = TransactionModel.fromJson(json);

      expect(tx.id, 'tx_998877');
      expect(tx.bookingId, 'book_123');
      expect(tx.amount, 285.50);
      expect(tx.currency, 'INR');
      expect(tx.status, TransactionStatus.escrowHeld);
      expect(tx.isSandbox, true);
      expect(tx.gatewayReference, 'pay_sim_00192');
    });

    test('handles settled status and live clearing flag', () {
      final json = {
        '_id': 'tx_112233',
        'amount': 450,
        'currency': 'INR',
        'status': 'settled_to_driver',
        'paymentMethod': 'card',
        'gatewayReference': 'razorpay_live_7721',
        'isSandbox': false,
        'createdAt': '2026-10-28T09:00:00.000Z',
      };

      final tx = TransactionModel.fromJson(json);

      expect(tx.status, TransactionStatus.settledToDriver);
      expect(tx.isSandbox, false);
      expect(tx.gatewayReference, 'razorpay_live_7721');
    });

    test('defaults unknown status to pending', () {
      final json = {
        '_id': 'tx_fallback',
        'amount': 100,
        'status': 'UNKNOWN_STATE',
        'createdAt': '2026-10-28T08:00:00.000Z',
      };

      final tx = TransactionModel.fromJson(json);
      expect(tx.status, TransactionStatus.pending);
    });
  });
}
