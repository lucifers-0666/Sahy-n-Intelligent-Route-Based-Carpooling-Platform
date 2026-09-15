import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_repository.dart';
import '../../domain/admin_models.dart';

enum AdminTab {
  overview,
  verifications,
  rides,
  reports,
  settings,
}

class AdminState {
  final AdminTab selectedTab;
  final AdminStatsModel stats;
  final List<DriverVerificationItem> verifications;
  final List<AdminRideItem> rides;
  final List<AdminReportItem> reports;
  final bool isLoading;
  final String? errorMessage;
  final String verificationFilter;
  final String rideFilter;
  final String searchQuery;

  const AdminState({
    this.selectedTab = AdminTab.overview,
    this.stats = const AdminStatsModel(),
    this.verifications = const [],
    this.rides = const [],
    this.reports = const [],
    this.isLoading = false,
    this.errorMessage,
    this.verificationFilter = 'all',
    this.rideFilter = 'all',
    this.searchQuery = '',
  });

  AdminState copyWith({
    AdminTab? selectedTab,
    AdminStatsModel? stats,
    List<DriverVerificationItem>? verifications,
    List<AdminRideItem>? rides,
    List<AdminReportItem>? reports,
    bool? isLoading,
    String? errorMessage,
    String? verificationFilter,
    String? rideFilter,
    String? searchQuery,
  }) {
    return AdminState(
      selectedTab: selectedTab ?? this.selectedTab,
      stats: stats ?? this.stats,
      verifications: verifications ?? this.verifications,
      rides: rides ?? this.rides,
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      verificationFilter: verificationFilter ?? this.verificationFilter,
      rideFilter: rideFilter ?? this.rideFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  final AdminRepository _repository;

  AdminNotifier(this._repository) : super(const AdminState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final statsFuture = _repository.getAdminStats();
      final verificationsFuture = _repository.getVerifications(
        status: state.verificationFilter,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
      final ridesFuture = _repository.getRides(
        status: state.rideFilter,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
      final reportsFuture = _repository.getReports();

      final results = await Future.wait([
        statsFuture,
        verificationsFuture,
        ridesFuture,
        reportsFuture,
      ]);

      state = state.copyWith(
        isLoading: false,
        stats: results[0] as AdminStatsModel,
        verifications: results[1] as List<DriverVerificationItem>,
        rides: results[2] as List<AdminRideItem>,
        reports: results[3] as List<AdminReportItem>,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load admin data: $e',
      );
    }
  }

  void setTab(AdminTab tab) {
    state = state.copyWith(selectedTab: tab);
  }

  Future<void> setVerificationFilter(String filter) async {
    state = state.copyWith(verificationFilter: filter, isLoading: true);
    try {
      final items = await _repository.getVerifications(
        status: filter,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
      state = state.copyWith(isLoading: false, verifications: items);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> setRideFilter(String filter) async {
    state = state.copyWith(rideFilter: filter, isLoading: true);
    try {
      final items = await _repository.getRides(
        status: filter,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
      state = state.copyWith(isLoading: false, rides: items);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> setSearchQuery(String query) async {
    state = state.copyWith(searchQuery: query);
    if (state.selectedTab == AdminTab.verifications) {
      setVerificationFilter(state.verificationFilter);
    } else if (state.selectedTab == AdminTab.rides) {
      setRideFilter(state.rideFilter);
    }
  }

  Future<bool> approveDriver(String userId) async {
    final success = await _repository.verifyDriver(userId, 'approved');
    if (success) {
      state = state.copyWith(
        verifications: state.verifications.map((item) {
          if (item.id == userId) {
            return item.copyWith(
              isVerified: true,
              canDrive: true,
              onboardingStatus: 'approved',
            );
          }
          return item;
        }).toList(),
      );
      return true;
    }
    return false;
  }

  Future<bool> rejectDriver(String userId, String reason) async {
    final success = await _repository.verifyDriver(userId, 'rejected', reason: reason);
    if (success) {
      state = state.copyWith(
        verifications: state.verifications.map((item) {
          if (item.id == userId) {
            return item.copyWith(
              isVerified: false,
              onboardingStatus: 'rejected',
              rejectionReason: reason,
            );
          }
          return item;
        }).toList(),
      );
      return true;
    }
    return false;
  }

  Future<bool> cancelRide(String rideId, String reason) async {
    final success = await _repository.moderateRide(rideId, 'cancel', reason: reason);
    if (success) {
      state = state.copyWith(
        rides: state.rides.map((ride) {
          if (ride.id == rideId) {
            return ride.copyWith(status: 'cancelled');
          }
          return ride;
        }).toList(),
      );
      return true;
    }
    return false;
  }

  Future<bool> resolveReport(String reportId, String notes) async {
    final success = await _repository.resolveReport(reportId, 'resolved', notes: notes);
    if (success) {
      state = state.copyWith(
        reports: state.reports.map((rep) {
          if (rep.id == reportId) {
            return rep.copyWith(status: 'resolved', resolutionNotes: notes);
          }
          return rep;
        }).toList(),
      );
      return true;
    }
    return false;
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return AdminNotifier(repo);
});
