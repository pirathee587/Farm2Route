import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/agency/presentation/pages/agency_portal_page.dart';
import '../../features/agency/presentation/pages/driver_vehicle_pages.dart';
import '../../features/agency/presentation/pages/package_pages.dart';
import '../../features/agency/presentation/pages/booking_pages.dart';
import '../../features/agency/presentation/pages/assignment_page.dart';
import '../../features/agency/presentation/pages/maintenance_pages.dart';
import '../../features/agency/presentation/pages/finance_pages.dart';
import '../../features/agency/presentation/pages/reviews_notifications_pages.dart';
import '../../features/auth/presentation/pages/landing_page.dart';
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

      final isAuthRoute = location == RouteNames.login ||
          location == RouteNames.register ||
          location == RouteNames.landing;
      final isSplash = location == RouteNames.splash;
      final isOtp = location == RouteNames.verifyOtp;

      if (status == AuthStatus.initial || status == AuthStatus.loading) {
        return isSplash ? null : RouteNames.splash;
      }

      if (status == AuthStatus.requiresOtp) {
        return isOtp ? null : RouteNames.verifyOtp;
      }

      if (status == AuthStatus.unauthenticated || status == AuthStatus.error) {
        if (isSplash) {
          return RouteNames.landing;
        }
        return isAuthRoute ? null : RouteNames.landing;
      }

      if (status == AuthStatus.authenticated) {
        final role = authState.user?.role.toUpperCase() ?? 'FARMER';
        final isAgencyRoute = location.startsWith('/agency');
        if (isAgencyRoute && role != 'AGENCY') {
          switch (role) {
            case 'ADMIN':
              return RouteNames.adminHome;
            case 'DRIVER':
              return RouteNames.driverHome;
            default:
              return RouteNames.farmerHome;
          }
        }
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
        path: RouteNames.landing,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LandingPage(),
          transitionDuration: const Duration(milliseconds: 700),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.fastOutSlowIn,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.06),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
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
        builder: (context, state) =>
            const AgencyPortalPage(section: 'dashboard'),
      ),
      ...[
        'drivers',
        'vehicles',
        'packages',
        'bookings',
        'assignments',
        'maintenance',
        'finance',
        'reviews',
        'notifications',
        'profile'
      ].map((section) => GoRoute(
          path: '/agency/$section',
          builder: (context, state) => AgencyPortalPage(section: section))),
      GoRoute(
          path: '/agency/drivers/new',
          builder: (context, state) => const DriverFormPage()),
      GoRoute(
          path: '/agency/drivers/:id/edit',
          builder: (context, state) =>
              DriverFormPage(id: state.pathParameters['id'])),
      GoRoute(
          path: '/agency/drivers/:id/reviews',
          builder: (context, state) =>
              AgencyDriverReviewsPage(driverId: state.pathParameters['id']!)),
      GoRoute(
          path: '/agency/drivers/:id/documents',
          builder: (context, state) =>
              DriverDocumentsPage(id: state.pathParameters['id']!)),
      GoRoute(
          path: '/agency/drivers/:id',
          builder: (context, state) =>
              DriverDetailsPage(id: state.pathParameters['id']!)),
      GoRoute(
          path: '/agency/vehicles/new',
          builder: (context, state) => const VehicleFormPage()),
      GoRoute(
          path: '/agency/vehicles/:id/edit',
          builder: (context, state) =>
              VehicleFormPage(id: state.pathParameters['id'])),
      GoRoute(
          path: '/agency/vehicles/:id/kyc',
          builder: (context, state) =>
              VehicleKycPage(id: state.pathParameters['id']!)),
      GoRoute(
          path: '/agency/vehicles/:id',
          builder: (context, state) =>
              VehicleDetailsPage(id: state.pathParameters['id']!)),
      GoRoute(
          path: '/agency/vehicles/:id/maintenance/new',
          builder: (context, state) =>
              MaintenanceFormPage(vehicleId: state.pathParameters['id']!)),
      GoRoute(
          path: '/agency/vehicles/:id/maintenance/:maintenanceId/edit',
          builder: (context, state) => MaintenanceFormPage(
              vehicleId: state.pathParameters['id']!,
              maintenanceId: state.pathParameters['maintenanceId'])),
      GoRoute(
          path: '/agency/vehicles/:id/maintenance/:maintenanceId',
          builder: (context, state) => MaintenanceDetailsPage(
              vehicleId: state.pathParameters['id']!,
              maintenanceId: state.pathParameters['maintenanceId']!)),
      GoRoute(
          path: '/agency/vehicles/:id/maintenance',
          builder: (context, state) =>
              VehicleMaintenancePage(vehicleId: state.pathParameters['id']!)),
      GoRoute(
          path: '/agency/finance/transactions',
          builder: (context, state) => const FinanceTransactionsPage()),
      GoRoute(
          path: '/agency/finance/withdrawals/new',
          builder: (context, state) => const WithdrawalFormPage()),
      GoRoute(
          path: '/agency/finance/withdrawals',
          builder: (context, state) => const FinanceWithdrawalsPage()),
      GoRoute(
          path: '/agency/reviews',
          builder: (context, state) => const AgencyReviewsPage()),
      GoRoute(
          path: '/agency/notifications',
          builder: (context, state) => const AgencyNotificationsPage()),
      GoRoute(
          path: '/agency/packages/new',
          builder: (context, state) => const PackageFormPage()),
      GoRoute(
          path: '/agency/packages/:id/edit',
          builder: (context, state) =>
              PackageFormPage(id: state.pathParameters['id'])),
      GoRoute(
          path: '/agency/packages/:id',
          builder: (context, state) =>
              PackageDetailsPage(id: state.pathParameters['id']!)),
      GoRoute(
          path: '/agency/bookings/:id',
          builder: (context, state) =>
              BookingDetailsPage(id: state.pathParameters['id']!)),
      GoRoute(
          path: '/agency/bookings/:id/assignment',
          builder: (context, state) =>
              AssignmentPage(bookingId: state.pathParameters['id']!)),
      GoRoute(
          path: '/agency/:resource/:id',
          builder: (context, state) => AgencyPortalPage(
              section: state.pathParameters['resource'] ?? 'dashboard')),
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
