import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/auth_provider.dart';

enum AccessMode { authenticated, guest }

enum OperationalMode { rider, driver }

class UserModeState {
  final AccessMode accessMode;
  final OperationalMode operationalMode;
  final String? pendingProtectedIntent;

  const UserModeState({
    this.accessMode = AccessMode.authenticated,
    this.operationalMode = OperationalMode.rider,
    this.pendingProtectedIntent,
  });

  bool get isGuest => accessMode == AccessMode.guest;
  bool get isAuthenticated => accessMode == AccessMode.authenticated;
  bool get isDriverMode => operationalMode == OperationalMode.driver;
  bool get isRiderMode => operationalMode == OperationalMode.rider;

  UserModeState copyWith({
    AccessMode? accessMode,
    OperationalMode? operationalMode,
    String? pendingProtectedIntent,
    bool clearPendingIntent = false,
  }) {
    return UserModeState(
      accessMode: accessMode ?? this.accessMode,
      operationalMode: operationalMode ?? this.operationalMode,
      pendingProtectedIntent: clearPendingIntent
          ? null
          : (pendingProtectedIntent ?? this.pendingProtectedIntent),
    );
  }
}

class UserModeNotifier extends StateNotifier<UserModeState> {
  UserModeNotifier() : super(const UserModeState());

  void setGuestMode() {
    state = state.copyWith(accessMode: AccessMode.guest);
  }

  void setAuthenticatedMode() {
    state = state.copyWith(accessMode: AccessMode.authenticated);
  }

  void clearGuestMode() {
    state = state.copyWith(
      accessMode: AccessMode.authenticated,
      clearPendingIntent: true,
    );
  }

  void setOperationalMode(OperationalMode mode) {
    state = state.copyWith(operationalMode: mode);
  }

  void setPendingProtectedIntent(String? intentRoute) {
    state = state.copyWith(pendingProtectedIntent: intentRoute);
  }

  void clearPendingIntent() {
    state = state.copyWith(clearPendingIntent: true);
  }

  void resetOnLogout() {
    state = const UserModeState(
      accessMode: AccessMode.authenticated,
      operationalMode: OperationalMode.rider,
    );
  }
}

final userModeProvider = StateNotifierProvider<UserModeNotifier, UserModeState>(
  (ref) {
    final notifier = UserModeNotifier();
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && next.user != null) {
        notifier.setAuthenticatedMode();
        notifier.clearPendingIntent();
      } else if (next.status == AuthStatus.unauthenticated) {
        notifier.resetOnLogout();
      }
    });
    return notifier;
  },
);
