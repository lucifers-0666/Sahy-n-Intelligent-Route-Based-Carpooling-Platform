import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahyan/app/theme/app_theme.dart';
import 'package:sahyan/features/vehicles/domain/vehicle_model.dart';
import 'package:sahyan/features/vehicles/data/vehicle_repository.dart';
import 'package:sahyan/features/vehicles/presentation/vehicle_provider.dart';
import 'package:sahyan/features/vehicles/presentation/screens/my_vehicles_screen.dart';
import 'package:sahyan/features/vehicles/presentation/screens/add_vehicle_screen.dart';
import 'package:sahyan/features/vehicles/presentation/screens/edit_vehicle_screen.dart';
import 'package:sahyan/features/auth/presentation/auth_provider.dart';
import 'package:sahyan/features/auth/data/auth_repository.dart';
import 'package:sahyan/core/storage/secure_storage_service.dart';
import 'package:sahyan/core/network/api_client.dart';
import 'package:sahyan/shared/models/user_model.dart';
import 'package:sahyan/core/widgets/app_text_field.dart';

class MockSecureStorageService implements SecureStorageService {
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<String?> getToken() async => 'fake_token';
  @override
  Future<void> deleteToken() async {}
  @override
  Future<void> saveUser(UserModel user) async {}
  @override
  Future<UserModel?> getUser() async => null;
  @override
  Future<void> deleteUser() async {}
  @override
  Future<void> clearSession() async {}
  @override
  Future<void> setCompletedOnboarding(bool completed) async {}
  @override
  Future<bool> hasCompletedOnboarding() async => true;
}

class MockAuthRepository implements AuthRepository {
  final UserModel Function()? userGetter;
  MockAuthRepository([this.userGetter]);

  @override
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async => {};
  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async => {};
  @override
  Future<Map<String, dynamic>> sendOtp(String phone) async => {};
  @override
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async => {};
  @override
  Future<Map<String, dynamic>> forgotPassword(String email) async => {};
  @override
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async => {};
  @override
  Future<UserModel> getProfile() async => userGetter != null
      ? userGetter!()
      : const UserModel(
          id: 'u123',
          name: 'Arjun Patel',
          phone: '+919876543210',
          email: 'arjun@example.com',
          city: 'Ahmedabad',
          verificationStatus: UserVerificationStatus.verified,
          rating: 4.9,
          totalRides: 14,
        );
}

class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier(AuthState initialState)
    : super(
        repository: MockAuthRepository(),
        storageService: MockSecureStorageService(),
        apiClient: ApiClient(),
      ) {
    state = initialState;
  }

  @override
  Future<void> checkAuthStatus() async {}
}

class MockVehicleRepository implements VehicleRepository {
  List<VehicleModel> vehicles = [
    const VehicleModel(
      id: 'v_1',
      ownerId: 'u123',
      registrationNumber: 'GJ01AB1234',
      vehicleType: 'hatchback',
      make: 'Maruti Suzuki',
      model: 'Swift VXI',
      year: 2023,
      color: 'Arctic White',
      seatCapacity: 4,
      status: 'active',
    ),
  ];

  @override
  Future<List<VehicleModel>> getVehicles() async => vehicles;

  @override
  Future<VehicleModel> getVehicleById(String id) async {
    return vehicles.firstWhere((v) => v.id == id);
  }

  @override
  Future<Map<String, dynamic>> createVehicle({
    required String registrationNumber,
    required String vehicleType,
    required String make,
    required String model,
    required int year,
    required String color,
    required int seatCapacity,
    String? vehicleImage,
  }) async {
    final newVehicle = VehicleModel(
      id: 'v_${DateTime.now().millisecondsSinceEpoch}',
      ownerId: 'u123',
      registrationNumber: registrationNumber,
      vehicleType: vehicleType,
      make: make,
      model: model,
      year: year,
      color: color,
      seatCapacity: seatCapacity,
      status: 'active',
    );
    vehicles = [newVehicle, ...vehicles];
    return {
      'vehicle': newVehicle,
      'user': {
        'id': 'u123',
        'name': 'Arjun Patel',
        'phone': '+919876543210',
        'email': 'arjun@example.com',
        'city': 'Ahmedabad',
        'capabilities': {'canRide': true, 'canDrive': true},
        'driverProfile': {'onboardingStatus': 'approved'},
      },
    };
  }

  @override
  Future<VehicleModel> updateVehicle({
    required String id,
    String? registrationNumber,
    String? vehicleType,
    String? make,
    String? model,
    int? year,
    String? color,
    int? seatCapacity,
    String? vehicleImage,
    String? status,
  }) async {
    final index = vehicles.indexWhere((v) => v.id == id);
    if (index == -1) throw Exception('Vehicle not found');

    final updated = vehicles[index].copyWith(
      registrationNumber: registrationNumber,
      vehicleType: vehicleType,
      make: make,
      model: model,
      year: year,
      color: color,
      seatCapacity: seatCapacity,
      vehicleImage: vehicleImage,
      status: status,
    );
    vehicles[index] = updated;
    return updated;
  }

  @override
  Future<Map<String, dynamic>> deleteVehicle(String id) async {
    vehicles.removeWhere((v) => v.id == id);
    return {'success': true, 'remainingVehicles': vehicles.length};
  }
}

Widget createVehicleTestApp({
  required Widget child,
  required MockVehicleRepository vehicleRepo,
  double textScaleFactor = 1.0,
}) {
  return ProviderScope(
    overrides: [
      vehicleRepositoryProvider.overrideWithValue(vehicleRepo),
      secureStorageServiceProvider.overrideWithValue(
        MockSecureStorageService(),
      ),
      authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      apiClientProvider.overrideWithValue(ApiClient()),
      authProvider.overrideWith((ref) {
        return TestAuthNotifier(
          const AuthState(
            status: AuthStatus.authenticated,
            user: UserModel(
              id: 'u123',
              name: 'Arjun Patel',
              phone: '+919876543210',
              email: 'arjun@example.com',
              city: 'Ahmedabad',
              verificationStatus: UserVerificationStatus.verified,
              rating: 4.9,
              totalRides: 14,
              canDrive: true,
              driverOnboardingStatus: 'approved',
            ),
            token: 'fake_token',
          ),
        );
      }),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScaleFactor)),
        child: child,
      ),
    ),
  );
}

void main() {
  group('MyVehiclesScreen Rendering & CRUD Interactions', () {
    late MockVehicleRepository mockRepo;

    setUp(() {
      mockRepo = MockVehicleRepository();
    });

    testWidgets('Renders empty state when user has no vehicles', (
      tester,
    ) async {
      mockRepo.vehicles = [];

      await tester.pumpWidget(
        createVehicleTestApp(
          child: const MyVehiclesScreen(),
          vehicleRepo: mockRepo,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('My Vehicles'), findsOneWidget);
      expect(find.text('No Vehicles Registered'), findsOneWidget);
      expect(find.text('Add Your First Vehicle'), findsOneWidget);
    });

    testWidgets('Renders populated fleet list with vehicle cards', (
      tester,
    ) async {
      await tester.pumpWidget(
        createVehicleTestApp(
          child: const MyVehiclesScreen(),
          vehicleRepo: mockRepo,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('My Vehicles'), findsOneWidget);
      expect(find.text('Registered Fleet (1)'), findsOneWidget);
      expect(find.text('Maruti Suzuki Swift VXI'), findsOneWidget);
      expect(find.text('GJ01AB1234'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Hatchback'), findsOneWidget);
      expect(find.text('2023'), findsOneWidget);
      expect(find.text('Arctic White'), findsOneWidget);
      expect(find.text('4 Seats'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Add Another Vehicle'), findsOneWidget);
    });

    testWidgets('Delete vehicle dialog confirms and deletes vehicle', (
      tester,
    ) async {
      await tester.pumpWidget(
        createVehicleTestApp(
          child: const MyVehiclesScreen(),
          vehicleRepo: mockRepo,
        ),
      );
      await tester.pump();
      await tester.pump();

      final deleteBtn = find.text('Delete');
      await tester.scrollUntilVisible(deleteBtn, 100);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('Delete Vehicle'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to delete Maruti Suzuki Swift VXI (GJ01AB1234)? This will remove the vehicle from your fleet.',
        ),
        findsOneWidget,
      );

      // Tap confirm Delete inside dialog
      final confirmDeleteBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Delete'),
      );
      await tester.tap(confirmDeleteBtn);
      await tester.pump();
      await tester.pump();

      expect(mockRepo.vehicles.length, 0);
      expect(find.text('No Vehicles Registered'), findsOneWidget);
    });
  });

  group('AddVehicleScreen Form & Validation', () {
    late MockVehicleRepository mockRepo;

    setUp(() {
      mockRepo = MockVehicleRepository();
    });

    testWidgets('Validates required fields on empty submit', (tester) async {
      await tester.pumpWidget(
        createVehicleTestApp(
          child: const AddVehicleScreen(),
          vehicleRepo: mockRepo,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Add Vehicle'), findsOneWidget);
      expect(find.text('Vehicle Information'), findsOneWidget);

      final registerBtn = find.text('Register Vehicle');
      await tester.ensureVisible(registerBtn);
      await tester.tap(registerBtn);
      await tester.pumpAndSettle();

      expect(find.text('Make required'), findsOneWidget);
      expect(find.text('Model required'), findsOneWidget);
      expect(find.text('Registration number is required'), findsOneWidget);
    });

    testWidgets('Fills form, modifies seat capacity, and registers vehicle', (
      tester,
    ) async {
      await tester.pumpWidget(
        createVehicleTestApp(
          child: const AddVehicleScreen(),
          vehicleRepo: mockRepo,
        ),
      );
      await tester.pump();
      await tester.pump();

      // Enter Make
      final makeField = find.widgetWithText(AppTextField, 'Make');
      await tester.ensureVisible(makeField);
      await tester.enterText(
        find.descendant(of: makeField, matching: find.byType(TextFormField)),
        'Hyundai',
      );

      // Enter Model
      final modelField = find.widgetWithText(AppTextField, 'Model');
      await tester.ensureVisible(modelField);
      await tester.enterText(
        find.descendant(of: modelField, matching: find.byType(TextFormField)),
        'Creta SX',
      );

      // Enter Registration
      final regField = find.widgetWithText(AppTextField, 'Registration Number');
      await tester.ensureVisible(regField);
      await tester.enterText(
        find.descendant(of: regField, matching: find.byType(TextFormField)),
        'GJ01CD5678',
      );

      // Enter Year
      final yearField = find.widgetWithText(AppTextField, 'Manufacturing Year');
      await tester.ensureVisible(yearField);
      await tester.enterText(
        find.descendant(of: yearField, matching: find.byType(TextFormField)),
        '2023',
      );

      // Enter Color
      final colorField = find.widgetWithText(AppTextField, 'Color');
      await tester.ensureVisible(colorField);
      await tester.enterText(
        find.descendant(of: colorField, matching: find.byType(TextFormField)),
        'Phantom Black',
      );

      // Scroll down to seat counter and submit button
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Increase seat capacity from 4 to 5
      final addSeatBtn = find.widgetWithIcon(
        IconButton,
        Icons.add_circle_outline_rounded,
      );
      await tester.tap(addSeatBtn);
      await tester.pumpAndSettle();

      expect(find.text('5 Passenger Seats'), findsOneWidget);

      final registerBtn = find.text('Register Vehicle');
      await tester.tap(registerBtn);
      await tester.pump();
      await tester.pump();

      expect(mockRepo.vehicles.length, 2);
      expect(mockRepo.vehicles.first.make, 'Hyundai');
      expect(mockRepo.vehicles.first.model, 'Creta SX');
      expect(mockRepo.vehicles.first.registrationNumber, 'GJ01CD5678');
      expect(mockRepo.vehicles.first.seatCapacity, 5);
    });
  });

  group('EditVehicleScreen Form & Validation', () {
    late MockVehicleRepository mockRepo;
    const testVehicle = VehicleModel(
      id: 'v_1',
      ownerId: 'u123',
      registrationNumber: 'GJ01AB1234',
      vehicleType: 'hatchback',
      make: 'Maruti Suzuki',
      model: 'Swift VXI',
      year: 2023,
      color: 'Arctic White',
      seatCapacity: 4,
      status: 'active',
    );

    setUp(() {
      mockRepo = MockVehicleRepository();
    });

    testWidgets('Pre-populates fields and saves updated vehicle', (
      tester,
    ) async {
      await tester.pumpWidget(
        createVehicleTestApp(
          child: const EditVehicleScreen(vehicle: testVehicle),
          vehicleRepo: mockRepo,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Edit Vehicle'), findsOneWidget);
      expect(find.text('Update Vehicle Details'), findsOneWidget);
      expect(find.text('Maruti Suzuki'), findsOneWidget);
      expect(find.text('Swift VXI'), findsOneWidget);

      // Change color
      final colorField = find.widgetWithText(AppTextField, 'Color');
      await tester.ensureVisible(colorField);
      await tester.enterText(
        find.descendant(of: colorField, matching: find.byType(TextFormField)),
        'Silky Silver',
      );

      // Toggle status switch
      final statusSwitch = find.byType(Switch);
      await tester.ensureVisible(statusSwitch);
      await tester.tap(statusSwitch);
      await tester.pump();

      final saveBtn = find.text('Save Changes');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();
      await tester.pump();

      expect(mockRepo.vehicles.first.color, 'Silky Silver');
      expect(mockRepo.vehicles.first.status, 'inactive');
    });
  });

  group('Responsive Layout Testing Across Viewports & 1.5x Text Scaling', () {
    final viewports = [
      const Size(320, 568), // 320dp Compact
      const Size(360, 640), // 360dp Small
      const Size(390, 844), // 390dp Standard
      const Size(412, 915), // 412dp Large
      const Size(600, 1024), // 600dp Tablet
    ];

    const testVehicle = VehicleModel(
      id: 'v_1',
      ownerId: 'u123',
      registrationNumber: 'GJ01AB1234',
      vehicleType: 'hatchback',
      make: 'Maruti Suzuki',
      model: 'Swift VXI',
      year: 2023,
      color: 'Arctic White',
      seatCapacity: 4,
      status: 'active',
    );

    for (final size in viewports) {
      testWidgets(
        'MyVehiclesScreen renders without overflow at ${size.width}x${size.height}',
        (tester) async {
          final mockRepo = MockVehicleRepository();
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            createVehicleTestApp(
              child: const MyVehiclesScreen(),
              vehicleRepo: mockRepo,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('My Vehicles'), findsOneWidget);
        },
      );

      testWidgets(
        'AddVehicleScreen renders without overflow at ${size.width}x${size.height}',
        (tester) async {
          final mockRepo = MockVehicleRepository();
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            createVehicleTestApp(
              child: const AddVehicleScreen(),
              vehicleRepo: mockRepo,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Add Vehicle'), findsOneWidget);
        },
      );

      testWidgets(
        'EditVehicleScreen renders without overflow at ${size.width}x${size.height}',
        (tester) async {
          final mockRepo = MockVehicleRepository();
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(
            createVehicleTestApp(
              child: const EditVehicleScreen(vehicle: testVehicle),
              vehicleRepo: mockRepo,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Edit Vehicle'), findsOneWidget);
        },
      );
    }

    testWidgets(
      'MyVehiclesScreen renders without overflow under 1.5x text scaling',
      (tester) async {
        final mockRepo = MockVehicleRepository();
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createVehicleTestApp(
            child: const MyVehiclesScreen(),
            vehicleRepo: mockRepo,
            textScaleFactor: 1.5,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('My Vehicles'), findsOneWidget);
      },
    );

    testWidgets(
      'AddVehicleScreen renders without overflow under 1.5x text scaling',
      (tester) async {
        final mockRepo = MockVehicleRepository();
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createVehicleTestApp(
            child: const AddVehicleScreen(),
            vehicleRepo: mockRepo,
            textScaleFactor: 1.5,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Add Vehicle'), findsOneWidget);
      },
    );

    testWidgets(
      'EditVehicleScreen renders without overflow under 1.5x text scaling',
      (tester) async {
        final mockRepo = MockVehicleRepository();
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createVehicleTestApp(
            child: const EditVehicleScreen(vehicle: testVehicle),
            vehicleRepo: mockRepo,
            textScaleFactor: 1.5,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Edit Vehicle'), findsOneWidget);
      },
    );
  });
}
