import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/agency/presentation/pages/agency_dashboard_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/driver/presentation/pages/driver_dashboard_page.dart';
import '../../features/farmer/presentation/pages/farmer_dashboard_page.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (BuildContext context, GoRouterState state) {
      final status = authState.status;
      final location = state.matchedLocation;

      final isAuthRoute = location == RouteNames.login || location == RouteNames.register;
      final isSplash = location == RouteNames.splash;
      final isOtp = location == RouteNames.verifyOtp;

      if (status == AuthStatus.initial || status == AuthStatus.loading) {
        return isSplash ? null : RouteNames.splash;
      }

      if (status == AuthStatus.requiresOtp) {
        return isOtp ? null : RouteNames.verifyOtp;
      }

      if (status == AuthStatus.unauthenticated || status == AuthStatus.error) {
        return isAuthRoute ? null : RouteNames.login;
      }

      if (status == AuthStatus.authenticated) {
        final role = authState.user?.role.toUpperCase() ?? 'FARMER';
        if (isAuthRoute || isSplash || isOtp) {
          switch (role) {
            case 'AGENCY':
              return RouteNames.agencyHome;
            case 'DRIVER':
              return RouteNames.driverHome;
            case 'ADMIN':
              return RouteNames.adminHome;
            case 'FARMER':
            default:
              return RouteNames.farmerHome;
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RouteNames.verifyOtp,
        builder: (context, state) => const OtpVerificationPage(),
      ),
      // Role Protected Routes
      GoRoute(
        path: RouteNames.farmerHome,
        builder: (context, state) => const FarmerDashboardPage(),
      ),
      GoRoute(
        path: RouteNames.agencyHome,
        builder: (context, state) => const AgencyDashboardPage(),
      ),
      GoRoute(
        path: RouteNames.driverHome,
        builder: (context, state) => const DriverDashboardPage(),
      ),
      GoRoute(
        path: RouteNames.adminHome,
        builder: (context, state) => const AdminDashboardPage(),
      ),
    ],
  );
});
