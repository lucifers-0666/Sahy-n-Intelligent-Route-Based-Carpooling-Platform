import 'package:equatable/equatable.dart';

enum UserVerificationStatus { pending, verified, rejected }

class UserPreferences extends Equatable {
  final bool notifications;
  final bool allowSmoking;
  final bool allowPets;

  const UserPreferences({
    this.notifications = true,
    this.allowSmoking = false,
    this.allowPets = false,
  });

  factory UserPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserPreferences();
    return UserPreferences(
      notifications: json['notifications'] ?? true,
      allowSmoking: json['allowSmoking'] ?? false,
      allowPets: json['allowPets'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifications': notifications,
      'allowSmoking': allowSmoking,
      'allowPets': allowPets,
    };
  }

  UserPreferences copyWith({
    bool? notifications,
    bool? allowSmoking,
    bool? allowPets,
  }) {
    return UserPreferences(
      notifications: notifications ?? this.notifications,
      allowSmoking: allowSmoking ?? this.allowSmoking,
      allowPets: allowPets ?? this.allowPets,
    );
  }

  @override
  List<Object?> get props => [notifications, allowSmoking, allowPets];
}

class EmergencyContact extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String relationship;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship = 'Family',
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      relationship: json['relationship'] ?? 'Family',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'relationship': relationship,
    };
  }

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, relationship];
}

class UserModel extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? profilePhoto;
  final String city;
  final String bio;
  final UserVerificationStatus verificationStatus;
  final double rating;
  final int totalRides;
  final String role;
  final bool canRide;
  final bool canDrive;
  final String driverOnboardingStatus;
  final String licenseNumber;
  final String rejectionReason;
  final UserPreferences preferences;
  final List<EmergencyContact> emergencyContacts;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.profilePhoto,
    required this.city,
    this.bio = '',
    required this.verificationStatus,
    required this.rating,
    required this.totalRides,
    this.role = 'user',
    this.canRide = true,
    this.canDrive = false,
    this.driverOnboardingStatus = 'not_started',
    this.licenseNumber = '',
    this.rejectionReason = '',
    this.preferences = const UserPreferences(),
    this.emergencyContacts = const [],
  });

  bool get isVerified => verificationStatus == UserVerificationStatus.verified;
  bool get isDriverEligible => canDrive && driverOnboardingStatus == 'approved';
  bool get isDriverSubmitted => driverOnboardingStatus == 'submitted';
  bool get isDriverRejected => driverOnboardingStatus == 'rejected';
  bool get isDriverInProgress => driverOnboardingStatus == 'in_progress';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final capabilities = json['capabilities'] as Map<String, dynamic>?;
    final driverProfile = json['driverProfile'] as Map<String, dynamic>?;

    final rawContacts = json['emergencyContacts'] as List<dynamic>?;
    final contacts = rawContacts != null
        ? rawContacts
              .whereType<Map<String, dynamic>>()
              .map((c) => EmergencyContact.fromJson(c))
              .toList()
        : <EmergencyContact>[];

    return UserModel(
      id: json['id'] ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      profilePhoto: json['profilePhoto'] ?? json['profileImage'],
      city: json['city'] ?? 'Ahmedabad',
      bio: json['bio'] ?? '',
      verificationStatus: UserVerificationStatus.values.firstWhere(
        (e) => e.name == json['verificationStatus'],
        orElse: () => json['isVerified'] == true
            ? UserVerificationStatus.verified
            : UserVerificationStatus.pending,
      ),
      rating: json['rating'] is Map
          ? ((json['rating']['average'] as num?)?.toDouble() ?? 4.9)
          : ((json['rating'] as num?)?.toDouble() ?? 4.9),
      totalRides: json['rating'] is Map
          ? ((json['rating']['count'] as num?)?.toInt() ?? 0)
          : (json['totalRides'] ?? 0),
      role: json['role'] ?? 'user',
      canRide: capabilities?['canRide'] ?? json['canRide'] ?? true,
      canDrive: capabilities?['canDrive'] ?? json['canDrive'] ?? false,
      driverOnboardingStatus:
          driverProfile?['onboardingStatus'] ??
          json['driverOnboardingStatus'] ??
          'not_started',
      licenseNumber:
          driverProfile?['licenseNumber'] ?? json['licenseNumber'] ?? '',
      rejectionReason:
          driverProfile?['rejectionReason'] ?? json['rejectionReason'] ?? '',
      preferences: json['preferences'] is Map<String, dynamic>
          ? UserPreferences.fromJson(
              json['preferences'] as Map<String, dynamic>,
            )
          : const UserPreferences(),
      emergencyContacts: contacts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'profilePhoto': profilePhoto,
      'city': city,
      'bio': bio,
      'verificationStatus': verificationStatus.name,
      'rating': rating,
      'totalRides': totalRides,
      'role': role,
      'canRide': canRide,
      'canDrive': canDrive,
      'driverOnboardingStatus': driverOnboardingStatus,
      'licenseNumber': licenseNumber,
      'rejectionReason': rejectionReason,
      'preferences': preferences.toJson(),
      'emergencyContacts': emergencyContacts.map((c) => c.toJson()).toList(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? profilePhoto,
    String? city,
    String? bio,
    UserVerificationStatus? verificationStatus,
    double? rating,
    int? totalRides,
    String? role,
    bool? canRide,
    bool? canDrive,
    String? driverOnboardingStatus,
    String? licenseNumber,
    String? rejectionReason,
    UserPreferences? preferences,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      role: role ?? this.role,
      canRide: canRide ?? this.canRide,
      canDrive: canDrive ?? this.canDrive,
      driverOnboardingStatus:
          driverOnboardingStatus ?? this.driverOnboardingStatus,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      preferences: preferences ?? this.preferences,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    email,
    profilePhoto,
    city,
    bio,
    verificationStatus,
    rating,
    totalRides,
    role,
    canRide,
    canDrive,
    driverOnboardingStatus,
    licenseNumber,
    rejectionReason,
    preferences,
    emergencyContacts,
  ];
}
