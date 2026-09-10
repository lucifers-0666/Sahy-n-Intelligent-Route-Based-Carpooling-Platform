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
import 'package:sahyan/shared/widgets/app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth-entry',
      builder: (context, state) => const AuthDecisionScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final token = state.extra as String?;
        return ResetPasswordScreen(initialToken: token);
      },
    ),
    GoRoute(path: '/otp', builder: (context, state) => const OtpScreen()),
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
      path: '/confirm-pay',
      builder: (context, state) => const ConfirmPayScreen(),
    ),
    GoRoute(
      path: '/booking-confirmation',
      builder: (context, state) => const BookingConfirmationScreen(),
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
        final booking = state.extra as BookingModel?;
        return JourneyCompletedScreen(booking: booking);
      },
    ),
    GoRoute(
      path: '/trip-safety',
      builder: (context, state) => const TripSafetyScreen(),
    ),
    GoRoute(
      path: '/live-tracking',
      builder: (context, state) => const LiveRideTrackingScreen(),
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
          ],
        ),
        // Tab 4: Bookings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/my-bookings',
              builder: (context, state) => const MyBookingsScreen(),
            ),
          ],
        ),
        // Tab 5: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
