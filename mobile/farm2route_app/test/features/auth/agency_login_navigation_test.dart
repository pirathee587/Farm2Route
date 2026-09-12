import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:farm2route_app/app/router/route_names.dart';
import 'package:farm2route_app/features/auth/data/models/auth_response_model.dart';
import 'package:farm2route_app/features/auth/data/models/user_model.dart';
import 'package:farm2route_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:farm2route_app/features/auth/presentation/pages/login_page.dart';
import 'package:farm2route_app/features/auth/presentation/providers/auth_provider.dart';

class MockAuthRepository implements AuthRepository {
  UserModel? mockUser;
  bool shouldRequireOtp = false;

  @override
  Future<bool> checkAuthStatus() async => mockUser != null;

  @override
  Future<String?> getCurrentRole() async => mockUser?.role;

  @override
  Future<UserModel> getMe() async {
    if (mockUser != null) return mockUser!;
    throw Exception('Not authenticated');
  }

  @override
  Future<AuthResponseModel> login({
    required String identifier,
    required String password,
  }) async {
    final user = UserModel(
      id: 'agency-user-1',
      fullName: 'Green Route Logistics',
      phoneNumber: '+94770000002',
      email: identifier,
      role: 'AGENCY',
      status: 'ACTIVE',
      isPhoneVerified: true,
      isEmailVerified: true,
    );
    mockUser = user;
    return AuthResponseModel(
      accessToken: 'fake-jwt-token',
      requiresOtp: shouldRequireOtp,
      user: user,
    );
  }

  @override
  Future<AuthResponseModel> register({
    required String fullName,
    required String phoneNumber,
    String? email,
    required String password,
    required String role,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthResponseModel> verifyOtp({
    required String phoneNumber,
    required String otpCode,
    required String purpose,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    mockUser = null;
  }
}

void main() {
  group('Agency Login Navigation Tests', () {
    testWidgets('switching tab to Agency reveals agency login form',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially on Farmer tab
      expect(find.text('🌾 Farmer Login'), findsOneWidget);

      // Tap Agency tab
      await tester.tap(find.text('🏢 Agency & Partner'));
      await tester.pumpAndSettle();

      // Verify Agency Login form is visible
      expect(find.text('Agency Portal Sign In'), findsOneWidget);
      expect(find.text('Business Email or Phone'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In to Agency Portal'), findsOneWidget);
    });

    testWidgets('successful agency login navigates to Agency Portal',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockAuthRepository();

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (_, __) => const LoginPage(initialRole: 'AGENCY'),
          ),
          GoRoute(
            path: RouteNames.agencyHome,
            builder: (_, __) => const Scaffold(
              body: Text('Target Agency Portal Dashboard'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Verify on agency login
      expect(find.text('Agency Portal Sign In'), findsOneWidget);

      // Fill in credentials
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Business Email or Phone'),
        'info@greenroute.lk',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'Password123!',
      );

      // Tap Sign In
      await tester.tap(find.text('Sign In to Agency Portal'));
      await tester.pumpAndSettle();

      // Verify navigated to Agency Portal Dashboard
      expect(find.text('Target Agency Portal Dashboard'), findsOneWidget);
    });

    testWidgets('if already authenticated as AGENCY, opening LoginPage redirects immediately',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockAuthRepository();
      mockRepo.mockUser = UserModel(
        id: 'agency-pre-auth',
        fullName: 'Green Route Pre-Auth',
        phoneNumber: '+94770000002',
        email: 'info@greenroute.lk',
        role: 'AGENCY',
        status: 'ACTIVE',
        isPhoneVerified: true,
        isEmailVerified: true,
      );

      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (_, __) => const LoginPage(),
          ),
          GoRoute(
            path: RouteNames.agencyHome,
            builder: (_, __) => const Scaffold(
              body: Text('Auto-Redirected Agency Portal Dashboard'),
            ),
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      container.read(authNotifierProvider.notifier).setAuthenticatedUser(mockRepo.mockUser!);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Auto-Redirected Agency Portal Dashboard'), findsOneWidget);
    });
  });
}
