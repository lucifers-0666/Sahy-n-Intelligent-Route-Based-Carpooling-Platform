import 'package:flutter_test/flutter_test.dart';
import 'package:sahyan/features/settings/domain/support_ticket_model.dart';

void main() {
  group('SupportTicketModel Serialization', () {
    test('parses support ticket and conversation messages', () {
      final json = {
        '_id': 'tkt_1001',
        'ticketNumber': 'TKT-20261028-0001',
        'category': 'ride_issue',
        'priority': 'high',
        'status': 'in_progress',
        'subject': 'Driver changed pickup route unexpectedly',
        'description': 'Driver diverted by 8km causing 35 minute delay.',
        'booking': {
          '_id': 'b_7766',
          'pickupAddress': 'SG Highway, Ahmedabad',
          'dropoffAddress': 'Gandhinagar Sector 11',
        },
        'messages': [
          {
            '_id': 'msg_01',
            'senderRole': 'user',
            'senderName': 'Aarav Patel',
            'message': 'Driver diverted by 8km causing 35 minute delay.',
            'createdAt': '2026-10-28T10:00:00.000Z',
          },
          {
            '_id': 'msg_02',
            'senderRole': 'admin',
            'senderName': 'Operations Desk',
            'message': 'We are examining GPS telematics with the driver.',
            'createdAt': '2026-10-28T10:15:00.000Z',
          }
        ],
        'resolutionNotes': null,
        'createdAt': '2026-10-28T10:00:00.000Z',
        'updatedAt': '2026-10-28T10:15:00.000Z',
      };

      final ticket = SupportTicketModel.fromJson(json);

      expect(ticket.id, 'tkt_1001');
      expect(ticket.ticketNumber, 'TKT-20261028-0001');
      expect(ticket.category, 'ride_issue');
      expect(ticket.priority, 'high');
      expect(ticket.status, 'in_progress');
      expect(ticket.messages.length, 2);
      expect(ticket.messages.first.senderRole, 'user');
      expect(ticket.messages.last.senderRole, 'admin');
      expect(ticket.bookingPickup, 'SG Highway, Ahmedabad');
      expect(ticket.bookingDrop, 'Gandhinagar Sector 11');
    });

    test('parses resolved ticket status accurately', () {
      final json = {
        '_id': 'tkt_1002',
        'ticketNumber': 'TKT-20261028-0002',
        'category': 'payment_inquiry',
        'priority': 'medium',
        'status': 'resolved',
        'subject': 'Escrow release confirmation',
        'description': 'Trip was completed and PIN verified.',
        'messages': [],
        'resolutionNotes': 'Escrow ledger verified and released.',
        'createdAt': '2026-10-28T08:00:00.000Z',
        'updatedAt': '2026-10-28T09:30:00.000Z',
      };

      final ticket = SupportTicketModel.fromJson(json);

      expect(ticket.status, 'resolved');
      expect(ticket.resolutionNotes, 'Escrow ledger verified and released.');
    });
  });
}
