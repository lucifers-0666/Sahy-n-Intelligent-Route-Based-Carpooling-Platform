enum TransactionStatus {
  pending,
  escrowHeld,
  settledToDriver,
  refunded,
  disputed,
  failed,
}

class TransactionModel {
  final String id;
  final String? bookingId;
  final double amount;
  final String currency;
  final double platformFee;
  final String paymentMethod;
  final TransactionStatus status;
  final bool isSandbox;
  final String? gatewayOrderId;
  final String? gatewayReference;
  final String? pickupName;
  final String? dropName;
  final String? driverName;
  final String? passengerName;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    this.bookingId,
    required this.amount,
    this.currency = 'INR',
    this.platformFee = 0.0,
    required this.paymentMethod,
    required this.status,
    this.isSandbox = true,
    this.gatewayOrderId,
    this.gatewayReference,
    this.pickupName,
    this.dropName,
    this.driverName,
    this.passengerName,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    TransactionStatus parseStatus(String? val) {
      switch (val) {
        case 'escrow_held':
          return TransactionStatus.escrowHeld;
        case 'settled_to_driver':
          return TransactionStatus.settledToDriver;
        case 'refunded':
          return TransactionStatus.refunded;
        case 'disputed':
          return TransactionStatus.disputed;
        case 'failed':
          return TransactionStatus.failed;
        default:
          return TransactionStatus.pending;
      }
    }

    final bookingObj = json['bookingId'];
    String? pickup;
    String? drop;
    String? bId;

    if (bookingObj is Map<String, dynamic>) {
      bId = bookingObj['_id']?.toString();
      pickup = bookingObj['pickup']?['name']?.toString();
      drop = bookingObj['drop']?['name']?.toString();
    } else if (bookingObj != null) {
      bId = bookingObj.toString();
    }

    final driverObj = json['driverId'];
    final passengerObj = json['passengerId'];

    return TransactionModel(
      id: json['_id']?.toString() ?? '',
      bookingId: bId,
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      currency: json['currency']?.toString() ?? 'INR',
      platformFee: (json['platformFee'] is num) ? (json['platformFee'] as num).toDouble() : 0.0,
      paymentMethod: json['paymentMethod']?.toString() ?? 'upi',
      status: parseStatus(json['status']?.toString()),
      isSandbox: json['isSandbox'] ?? true,
      gatewayOrderId: json['gatewayOrderId']?.toString(),
      gatewayReference: json['gatewayReference']?.toString(),
      pickupName: pickup,
      dropName: drop,
      driverName: driverObj is Map ? driverObj['name']?.toString() : null,
      passengerName: passengerObj is Map ? passengerObj['name']?.toString() : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

