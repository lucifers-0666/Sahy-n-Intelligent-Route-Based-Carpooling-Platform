class AdminStatsModel {
  final int totalUsers;
  final int verifiedDrivers;
  final int pendingVerifications;
  final int activeJourneys;
  final int scheduledRides;
  final int completedRides;
  final int completedBookings;
  final int openReports;
  final double totalFuelSplit;
  final double totalCo2SavedKg;
  final String databaseStatus;
  final int uptimeSeconds;
  final String apiVersion;

  const AdminStatsModel({
    this.totalUsers = 0,
    this.verifiedDrivers = 0,
    this.pendingVerifications = 0,
    this.activeJourneys = 0,
    this.scheduledRides = 0,
    this.completedRides = 0,
    this.completedBookings = 0,
    this.openReports = 0,
    this.totalFuelSplit = 0.0,
    this.totalCo2SavedKg = 0.0,
    this.databaseStatus = 'connected',
    this.uptimeSeconds = 0,
    this.apiVersion = '1.0.0',
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    final health = json['systemHealth'] as Map<String, dynamic>? ?? {};
    return AdminStatsModel(
      totalUsers: json['totalUsers'] as int? ?? 0,
      verifiedDrivers: json['verifiedDrivers'] as int? ?? 0,
      pendingVerifications: json['pendingVerifications'] as int? ?? 0,
      activeJourneys: json['activeJourneys'] as int? ?? 0,
      scheduledRides: json['scheduledRides'] as int? ?? 0,
      completedRides: json['completedRides'] as int? ?? 0,
      completedBookings: json['completedBookings'] as int? ?? 0,
      openReports: json['openReports'] as int? ?? 0,
      totalFuelSplit: (json['totalFuelSplit'] as num?)?.toDouble() ?? 0.0,
      totalCo2SavedKg: (json['totalCo2SavedKg'] as num?)?.toDouble() ?? 0.0,
      databaseStatus: health['database'] as String? ?? 'connected',
      uptimeSeconds: health['uptimeSeconds'] as int? ?? 0,
      apiVersion: health['apiVersion'] as String? ?? '1.0.0',
    );
  }
}

class DriverVerificationItem {
  final String id;
  final String name;
  final String phone;
  final String email;
  final bool isVerified;
  final bool canDrive;
  final String onboardingStatus; // 'submitted', 'approved', 'rejected', 'not_started'
  final String licenseNumber;
  final String licenseDocUrl;
  final String rcDocUrl;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehiclePlate;
  final String rejectionReason;
  final DateTime createdAt;

  const DriverVerificationItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.isVerified,
    required this.canDrive,
    required this.onboardingStatus,
    this.licenseNumber = '',
    this.licenseDocUrl = '',
    this.rcDocUrl = '',
    this.vehicleMake,
    this.vehicleModel,
    this.vehiclePlate,
    this.rejectionReason = '',
    required this.createdAt,
  });

  factory DriverVerificationItem.fromJson(Map<String, dynamic> json) {
    final driverProfile = json['driverProfile'] as Map<String, dynamic>? ?? {};
    final capabilities = json['capabilities'] as Map<String, dynamic>? ?? {};
    final vehicle = json['vehicle'] as Map<String, dynamic>? ?? {};

    return DriverVerificationItem(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      name: (json['name'] ?? 'Applicant') as String,
      phone: (json['phone'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      isVerified: json['isVerified'] as bool? ?? false,
      canDrive: capabilities['canDrive'] as bool? ?? false,
      onboardingStatus: (driverProfile['onboardingStatus'] ?? 'submitted') as String,
      licenseNumber: (driverProfile['licenseNumber'] ?? '') as String,
      licenseDocUrl: (driverProfile['licenseDocUrl'] ?? '') as String,
      rcDocUrl: (driverProfile['rcDocUrl'] ?? '') as String,
      vehicleMake: vehicle['make'] as String?,
      vehicleModel: vehicle['model'] as String?,
      vehiclePlate: vehicle['registrationNumber'] as String?,
      rejectionReason: (driverProfile['rejectionReason'] ?? '') as String,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  DriverVerificationItem copyWith({
    bool? isVerified,
    bool? canDrive,
    String? onboardingStatus,
    String? rejectionReason,
  }) {
    return DriverVerificationItem(
      id: id,
      name: name,
      phone: phone,
      email: email,
      isVerified: isVerified ?? this.isVerified,
      canDrive: canDrive ?? this.canDrive,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      licenseNumber: licenseNumber,
      licenseDocUrl: licenseDocUrl,
      rcDocUrl: rcDocUrl,
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      vehiclePlate: vehiclePlate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt,
    );
  }
}

class AdminRideItem {
  final String id;
  final String driverName;
  final String driverPhone;
  final double driverRating;
  final String originName;
  final String destinationName;
  final DateTime departureTime;
  final String status; // 'scheduled', 'boarding', 'active', 'completed', 'cancelled'
  final int totalSeats;
  final int availableSeats;
  final double contributionPerSeat;
  final String? vehiclePlate;

  const AdminRideItem({
    required this.id,
    required this.driverName,
    required this.driverPhone,
    required this.driverRating,
    required this.originName,
    required this.destinationName,
    required this.departureTime,
    required this.status,
    required this.totalSeats,
    required this.availableSeats,
    required this.contributionPerSeat,
    this.vehiclePlate,
  });

  factory AdminRideItem.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] as Map<String, dynamic>? ?? {};
    final origin = json['origin'] as Map<String, dynamic>? ?? {};
    final dest = json['destination'] as Map<String, dynamic>? ?? {};
    final vehicle = json['vehicle'] as Map<String, dynamic>? ?? {};

    return AdminRideItem(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      driverName: (driver['name'] ?? 'Driver') as String,
      driverPhone: (driver['phone'] ?? '') as String,
      driverRating: (driver['rating'] is Map ? (driver['rating']['average'] as num?)?.toDouble() : (driver['rating'] as num?)?.toDouble()) ?? 4.9,
      originName: (origin['name'] ?? 'Origin') as String,
      destinationName: (dest['name'] ?? 'Destination') as String,
      departureTime: json['departureTime'] != null
          ? DateTime.tryParse(json['departureTime'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: (json['status'] ?? 'scheduled') as String,
      totalSeats: json['totalSeats'] as int? ?? 3,
      availableSeats: json['availableSeats'] as int? ?? 3,
      contributionPerSeat: (json['contributionPerSeat'] as num?)?.toDouble() ?? 250.0,
      vehiclePlate: vehicle['registrationNumber'] as String?,
    );
  }

  AdminRideItem copyWith({String? status}) {
    return AdminRideItem(
      id: id,
      driverName: driverName,
      driverPhone: driverPhone,
      driverRating: driverRating,
      originName: originName,
      destinationName: destinationName,
      departureTime: departureTime,
      status: status ?? this.status,
      totalSeats: totalSeats,
      availableSeats: availableSeats,
      contributionPerSeat: contributionPerSeat,
      vehiclePlate: vehiclePlate,
    );
  }
}

class AdminReportItem {
  final String id;
  final String reporterName;
  final String reporterPhone;
  final String reportedUserName;
  final String type; // 'sos_trigger', 'safety_concern', 'reported_review', 'driver_conduct'
  final String title;
  final String description;
  final String severity; // 'low', 'medium', 'high', 'critical'
  final String status; // 'open', 'investigating', 'resolved', 'dismissed'
  final String resolutionNotes;
  final DateTime createdAt;

  const AdminReportItem({
    required this.id,
    required this.reporterName,
    this.reporterPhone = '',
    this.reportedUserName = '',
    required this.type,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    this.resolutionNotes = '',
    required this.createdAt,
  });

  factory AdminReportItem.fromJson(Map<String, dynamic> json) {
    final reporter = json['reporter'] as Map<String, dynamic>? ?? {};
    final reported = json['reportedUser'] as Map<String, dynamic>? ?? {};

    return AdminReportItem(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      reporterName: (reporter['name'] ?? 'User') as String,
      reporterPhone: (reporter['phone'] ?? '') as String,
      reportedUserName: (reported['name'] ?? 'User') as String,
      type: (json['type'] ?? 'safety_concern') as String,
      title: (json['title'] ?? 'Incident Report') as String,
      description: (json['description'] ?? '') as String,
      severity: (json['severity'] ?? 'medium') as String,
      status: (json['status'] ?? 'open') as String,
      resolutionNotes: (json['resolutionNotes'] ?? '') as String,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  AdminReportItem copyWith({String? status, String? resolutionNotes}) {
    return AdminReportItem(
      id: id,
      reporterName: reporterName,
      reporterPhone: reporterPhone,
      reportedUserName: reportedUserName,
      type: type,
      title: title,
      description: description,
      severity: severity,
      status: status ?? this.status,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      createdAt: createdAt,
    );
  }
}
