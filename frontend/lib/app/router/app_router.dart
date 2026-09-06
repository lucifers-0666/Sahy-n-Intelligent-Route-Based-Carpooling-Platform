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
import 'package:sahyan/features/profile/presentation/screens/profile_screen.dart';
import 'package:sahyan/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:sahyan/features/profile/presentation/screens/emergency_contacts_screen.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/features/vehicles/presentation/screens/my_vehicles_screen.dart';
import 'package:sahyan/features/vehicles/presentation/screens/add_vehicle_screen.dart';
import 'package:sahyan/features/vehicles/presentation/screens/edit_vehicle_screen.dart';
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
      path: '/search-results',
      builder: (context, state) => const SearchResultsScreen(),
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

    // Bottom Navigation Shell
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: Find Ride (Home)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Tab 2: Offer Ride
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/offer-ride',
              builder: (context, state) => const OfferRideScreen(),
            ),
          ],
        ),
        // Tab 3: My Bookings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/my-bookings',
              builder: (context, state) => const MyBookingsScreen(),
            ),
          ],
        ),
        // Tab 4: Profile
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
