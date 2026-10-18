import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sahyan/features/auth/presentation/screens/splash_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/auth_decision_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/login_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/register_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/otp_screen.dart';
import 'package:sahyan/features/home/presentation/screens/home_screen.dart';
import 'package:sahyan/features/home/presentation/screens/travel_date_time_screen.dart';
import 'package:sahyan/features/home/presentation/screens/passenger_selection_screen.dart';
import 'package:sahyan/features/rides/presentation/screens/search_results_screen.dart';
import 'package:sahyan/features/rides/presentation/screens/offer_ride_screen.dart';
import 'package:sahyan/features/rides/presentation/screens/ride_details_screen.dart';
import 'package:sahyan/features/rides/presentation/screens/seat_selection_screen.dart';
import 'package:sahyan/features/bookings/presentation/screens/confirm_pay_screen.dart';
import 'package:sahyan/features/bookings/presentation/screens/booking_confirmation_screen.dart';
import 'package:sahyan/features/bookings/presentation/screens/my_bookings_screen.dart';
import 'package:sahyan/features/bookings/presentation/screens/booking_details_screen.dart';
import 'package:sahyan/features/bookings/presentation/screens/driver_rides_screen.dart';
import 'package:sahyan/features/bookings/presentation/screens/driver_request_details_screen.dart';
import 'package:sahyan/features/bookings/domain/booking_model.dart';
import 'package:sahyan/features/profile/presentation/screens/profile_screen.dart';
import 'package:sahyan/features/profile/presentation/screens/driver_onboarding_screen.dart';
import 'package:sahyan/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:sahyan/features/profile/presentation/screens/emergency_contacts_screen.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/features/vehicles/presentation/screens/my_vehicles_screen.dart';
import 'package:sahyan/features/vehicles/presentation/screens/add_vehicle_screen.dart';
import 'package:sahyan/features/vehicles/presentation/screens/edit_vehicle_screen.dart';
import 'package:sahyan/features/notifications/domain/notification_model.dart';
import 'package:sahyan/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:sahyan/features/notifications/presentation/screens/notification_details_screen.dart';
import 'package:sahyan/features/messaging/domain/messaging_model.dart';
import 'package:sahyan/features/messaging/presentation/screens/messages_screen.dart';
import 'package:sahyan/features/messaging/presentation/screens/chat_detail_screen.dart';
import 'package:sahyan/features/trip/presentation/screens/active_journey_screen.dart';
import 'package:sahyan/features/trip/presentation/screens/journey_completed_screen.dart';
import 'package:sahyan/features/trip/presentation/screens/trip_safety_screen.dart';
import 'package:sahyan/features/trip/presentation/screens/live_ride_tracking_screen.dart';
import 'package:sahyan/features/settings/presentation/screens/settings_screen.dart';
import 'package:sahyan/features/profile/presentation/screens/saved_places_screen.dart';
import 'package:sahyan/features/profile/presentation/screens/reviews_ratings_screen.dart';
import 'package:sahyan/features/rides/presentation/screens/ride_history_screen.dart';
import 'package:sahyan/features/payments/presentation/screens/payment_methods_screen.dart';
import 'package:sahyan/features/payments/presentation/screens/payment_checkout_screen.dart';
import 'package:sahyan/features/payments/presentation/screens/driver_payout_screen.dart';
import 'package:sahyan/features/payments/presentation/screens/payout_account_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/auth_success_screen.dart';
import 'package:sahyan/features/profile/presentation/screens/personal_details_screen.dart';
import 'package:sahyan/features/rides/presentation/screens/filter_rides_screen.dart';
import 'package:sahyan/features/rides/presentation/screens/ride_published_screen.dart';
import 'package:sahyan/features/rides/domain/ride_model.dart';
import 'package:sahyan/features/bookings/presentation/screens/booking_request_screen.dart';
import 'package:sahyan/features/bookings/presentation/screens/cancel_booking_screen.dart';
import 'package:sahyan/features/trip/presentation/screens/driver_active_ride_screen.dart';
import 'package:sahyan/features/trip/presentation/screens/safety_center_screen.dart';
import 'package:sahyan/features/settings/presentation/screens/help_support_screen.dart';
import 'package:sahyan/features/home/presentation/screens/system_states_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/welcome_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/welcome_back_screen.dart';
import 'package:sahyan/features/auth/presentation/screens/account_suspended_screen.dart';
import 'package:sahyan/features/trip/presentation/screens/gps_diagnostic_screen.dart';
import 'package:sahyan/features/profile/presentation/screens/privacy_permissions_screen.dart';
import 'package:sahyan/shared/widgets/app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

void navigateToSuspendedScreen(String reason, [String? suspendedAt]) {
  appRouter.go(
    '/account-suspended',
    extra: {'reason': reason, 'suspendedAt': suspendedAt},
  );
}

CustomTransitionPage<void> _buildFadeThroughPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  final disableAnimations =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  if (disableAnimations) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: Duration.zero,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          child,
    );
  }

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeIn = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final fadeOut = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: fadeIn,
        child: FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.0).animate(fadeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(fadeIn),
            child: child,
          ),
        ),
      );
    },
  );
}

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/account-suspended',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final reason =
            extra?['reason'] as String? ??
            'Account suspended by administration.';
        final suspendedAt = extra?['suspendedAt'] as String?;
        return AccountSuspendedScreen(reason: reason, suspendedAt: suspendedAt);
      },
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth-entry',
      builder: (context, state) => const AuthDecisionScreen(),
    ),
    GoRoute(
      path: '/welcome',
      pageBuilder: (context, state) => _buildFadeThroughPage(
        context: context,
        state: state,
        child: const WelcomeScreen(),
      ),
    ),
    GoRoute(
      path: '/welcome-back',
      pageBuilder: (context, state) => _buildFadeThroughPage(
        context: context,
        state: state,
        child: const WelcomeBackScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) {
        final method = state.uri.queryParameters['method'];
        return _buildFadeThroughPage(
          context: context,
          state: state,
          child: LoginScreen(initialMethod: method),
        );
      },
    ),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => _buildFadeThroughPage(
        context: context,
        state: state,
        child: const RegisterScreen(),
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      pageBuilder: (context, state) => _buildFadeThroughPage(
        context: context,
        state: state,
        child: const ForgotPasswordScreen(),
      ),
    ),
    GoRoute(
      path: '/reset-password',
      pageBuilder: (context, state) {
        final token = state.extra as String?;
        return _buildFadeThroughPage(
          context: context,
          state: state,
          child: ResetPasswordScreen(initialToken: token),
        );
      },
    ),
    GoRoute(
      path: '/otp',
      pageBuilder: (context, state) => _buildFadeThroughPage(
        context: context,
        state: state,
        child: OtpScreen(
          isRegistration: state.uri.queryParameters['flow'] == 'registration',
        ),
      ),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/emergency-contacts',
      builder: (context, state) => const EmergencyContactsScreen(),
    ),
    GoRoute(
      path: '/vehicles',
      builder: (context, state) => const MyVehiclesScreen(),
    ),
    GoRoute(
      path: '/vehicles/add',
      builder: (context, state) => const AddVehicleScreen(),
    ),
    GoRoute(
      path: '/vehicles/edit',
      builder: (context, state) {
        final vehicle = state.extra as VehicleModel;
        return EditVehicleScreen(vehicle: vehicle);
      },
    ),
    GoRoute(
      path: '/ride-details',
      builder: (context, state) => const RideDetailsScreen(),
    ),
    GoRoute(
      path: '/seat-selection',
      builder: (context, state) => const SeatSelectionScreen(),
    ),
    GoRoute(
      path: '/travel-date-time',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final initialDate = extra?['date'] as DateTime? ?? DateTime.now();
        final initialTime = extra?['time'] as TimeOfDay? ??
            const TimeOfDay(hour: 17, minute: 30);
        return TravelDateTimeScreen(
          initialDate: initialDate,
          initialTime: initialTime,
        );
      },
    ),
    GoRoute(
      path: '/passenger-selection',
      builder: (context, state) {
        final seats = state.extra as int? ?? 2;
        return PassengerSelectionScreen(initialSeats: seats);
      },
    ),
    GoRoute(
      path: '/confirm-pay',
      builder: (context, state) => const ConfirmPayScreen(),
    ),
    GoRoute(
      path: '/booking-review',
      builder: (context, state) => const ConfirmPayScreen(),
    ),
    GoRoute(
      path: '/booking-confirmation',
      builder: (context, state) => const BookingConfirmationScreen(),
    ),
    GoRoute(
      path: '/passenger/bookings',
      builder: (context, state) => const MyBookingsScreen(),
    ),
    GoRoute(
      path: '/booking-details',
      builder: (context, state) {
        final booking = state.extra as BookingModel?;
        return BookingDetailsScreen(initialBooking: booking);
      },
    ),
    GoRoute(
      path: '/driver/rides',
      builder: (context, state) => const DriverRidesScreen(),
    ),
    GoRoute(
      path: '/driver/request-details',
      builder: (context, state) {
        final request = state.extra as BookingModel?;
        return DriverRequestDetailsScreen(initialRequest: request);
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/notifications/:id',
      builder: (context, state) {
        final item = state.extra as NotificationItem?;
        return NotificationDetailsScreen(notification: item);
      },
    ),
    GoRoute(
      path: '/messages',
      builder: (context, state) => const MessagesScreen(),
    ),
    GoRoute(
      path: '/messages/:conversationId',
      builder: (context, state) {
        final conv = state.extra as Conversation?;
        final id = state.pathParameters['conversationId'];
        return ChatDetailScreen(initialConversation: conv, conversationId: id);
      },
    ),
    GoRoute(
      path: '/active-journey',
      builder: (context, state) {
        final booking = state.extra as BookingModel?;
        return ActiveJourneyScreen(initialBooking: booking);
      },
    ),
    GoRoute(
      path: '/journey-completed',
      builder: (context, state) {
        if (state.extra is BookingModel) {
          return JourneyCompletedScreen(booking: state.extra as BookingModel);
        } else if (state.extra is RideModel) {
          return JourneyCompletedScreen(ride: state.extra as RideModel);
        }
        return const JourneyCompletedScreen();
      },
    ),
    GoRoute(
      path: '/trip-safety',
      builder: (context, state) => const TripSafetyScreen(),
    ),
    GoRoute(
      path: '/live-tracking',
      builder: (context, state) {
        final booking = state.extra as BookingModel?;
        return LiveRideTrackingScreen(booking: booking);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/saved-places',
      builder: (context, state) => const SavedPlacesScreen(),
    ),
    GoRoute(
      path: '/ride-history',
      builder: (context, state) => const RideHistoryScreen(),
    ),
    GoRoute(
      path: '/reviews',
      builder: (context, state) => const ReviewsRatingsScreen(),
    ),
    GoRoute(
      path: '/payment-methods',
      builder: (context, state) => const PaymentMethodsScreen(),
    ),
    GoRoute(
      path: '/payment-checkout',
      builder: (context, state) {
        final booking = state.extra as BookingModel;
        return PaymentCheckoutScreen(booking: booking);
      },
    ),
    GoRoute(
      path: '/driver/payout',
      builder: (context, state) => const DriverPayoutScreen(),
    ),
    GoRoute(
      path: '/driver/payout-account',
      builder: (context, state) => const PayoutAccountScreen(),
    ),
    GoRoute(
      path: '/auth-success',
      builder: (context, state) => const AuthSuccessScreen(),
    ),
    GoRoute(
      path: '/personal-details',
      builder: (context, state) => const PersonalDetailsScreen(),
    ),
    GoRoute(
      path: '/driver-onboarding',
      builder: (context, state) => const DriverOnboardingScreen(),
    ),
    GoRoute(
      path: '/privacy-permissions',
      builder: (context, state) => const PrivacyPermissionsScreen(),
    ),
    GoRoute(
      path: '/filter-rides',
      builder: (context, state) => const FilterRidesScreen(),
    ),
    GoRoute(
      path: '/booking-request',
      builder: (context, state) {
        final booking = state.extra as BookingModel?;
        return BookingRequestScreen(initialBooking: booking);
      },
    ),
    GoRoute(
      path: '/cancel-booking',
      builder: (context, state) {
        final booking = state.extra as BookingModel?;
        return CancelBookingScreen(initialBooking: booking);
      },
    ),
    GoRoute(
      path: '/ride-published',
      builder: (context, state) {
        final ride = state.extra as RideModel?;
        return RidePublishedScreen(publishedRide: ride);
      },
    ),
    GoRoute(
      path: '/driver/active-ride',
      builder: (context, state) {
        final ride = state.extra as RideModel?;
        return DriverActiveRideScreen(initialRide: ride);
      },
    ),
    GoRoute(
      path: '/safety-center',
      builder: (context, state) => const SafetyCenterScreen(),
    ),
    GoRoute(
      path: '/help-support',
      builder: (context, state) => const HelpSupportScreen(),
    ),
    GoRoute(
      path: '/system-states',
      builder: (context, state) => const SystemStatesScreen(),
    ),
    GoRoute(
      path: '/gps-diagnostics',
      builder: (context, state) => const GpsDiagnosticScreen(),
    ),

    // Bottom Navigation Shell
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Tab 2: Rides (Search Results)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search-results',
              builder: (context, state) => const SearchResultsScreen(),
            ),
          ],
        ),
        // Tab 3: Offer Ride
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/offer-ride',
              builder: (context, state) => const OfferRideScreen(),
            ),
            GoRoute(
              path: '/publish-ride',
              builder: (context, state) => const OfferRideScreen(),
            ),
          ],
        ),
        // Tab 4: Bookings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/bookings',
              builder: (context, state) => const BookingsHubScreen(),
            ),
            GoRoute(
              path: '/trips',
              builder: (context, state) => const BookingsHubScreen(),
            ),
            GoRoute(
              path: '/my-trips',
              builder: (context, state) => const BookingsHubScreen(),
            ),
            GoRoute(
              path: '/my-bookings',
              builder: (context, state) => const BookingsHubScreen(),
            ),
            GoRoute(
              path: '/bookings-hub',
              builder: (context, state) => const BookingsHubScreen(),
            ),
          ],
        ),
        // Tab 5: Profile & Account
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/account',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/profile/safety',
              builder: (context, state) => const ProfileSafetyScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
