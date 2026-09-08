import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/agency/data/models/agency_response_model.dart';
import '../../features/agency/presentation/pages/agency_dashboard_page.dart';
import '../../features/agency/presentation/screens/agency_pending_review_screen.dart';
import '../../features/agency/presentation/screens/agency_signup_form_screen.dart';
import '../../features/agency/presentation/screens/agency_signup_screen.dart';
import '../../features/agency/presentation/screens/agency_verify_screen.dart';
import '../../features/auth/presentation/pages/landing_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/driver/presentation/pages/driver_dashboard_page.dart';
import '../../features/farmer/presentation/pages/farmer_dashboard_page.dart';
import '../../features/farmer/presentation/screens/farmer_details_screen.dart';
import '../../features/farmer/presentation/screens/farmer_hauler_results_screen.dart';
import '../../features/farmer/presentation/screens/farmer_landing_screen.dart';
import '../../features/farmer/presentation/screens/farmer_login_screen.dart';
import '../../features/farmer/presentation/screens/farmer_otp_verify_screen.dart';
import '../../features/farmer/presentation/screens/farmer_package_details_screen.dart';
import '../../features/farmer/presentation/screens/farmer_phone_entry_screen.dart';
import '../../features/landing/presentation/screens/public_landing_screen.dart';
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
          location == RouteNames.agencySignup ||
          location == RouteNames.agencySignupForm ||
          location == RouteNames.agencyVerify ||
          location == RouteNames.agencyPendingReview ||
          location == RouteNames.farmerLanding ||
          location == RouteNames.farmerLogin ||
          location == RouteNames.farmerPhoneEntry ||
          location == RouteNames.farmerOtpVerify ||
          location == RouteNames.farmerDetails ||
          location == RouteNames.landing;
      final isSplash = location == RouteNames.splash;
      final isOtp = location == RouteNames.verifyOtp;

      if (status == AuthStatus.initial || status == AuthStatus.loading) {
        if (isAuthRoute) return null;
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
          child: const PublicLandingScreen(),
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
        path: RouteNames.agencySignup,
        builder: (context, state) => const AgencySignupFormScreen(),
      ),
      GoRoute(
        path: RouteNames.agencySignupForm,
        builder: (context, state) => const AgencySignupFormScreen(),
      ),
      GoRoute(
        path: RouteNames.agencyVerify,
        builder: (context, state) => AgencyVerifyScreen(
          agencyData: state.extra is AgencyResponseModel
              ? state.extra as AgencyResponseModel
              : null,
        ),
      ),
      GoRoute(
        path: RouteNames.agencyPendingReview,
        builder: (context, state) => const AgencyPendingReviewScreen(),
      ),
      GoRoute(
        path: RouteNames.farmerLanding,
        builder: (context, state) => const FarmerLandingScreen(),
      ),
      GoRoute(
        path: RouteNames.farmerLogin,
        builder: (context, state) => const FarmerLoginScreen(),
      ),
      GoRoute(
        path: RouteNames.farmerPhoneEntry,
        builder: (context, state) => const FarmerPhoneEntryScreen(),
      ),
      GoRoute(
        path: RouteNames.farmerOtpVerify,
        builder: (context, state) => const FarmerOtpVerifyScreen(),
      ),
      GoRoute(
        path: RouteNames.farmerDetails,
        builder: (context, state) => const FarmerDetailsScreen(),
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
        path: RouteNames.farmerHaulerResults,
        builder: (context, state) => const FarmerHaulerResultsScreen(),
      ),
      GoRoute(
        path: RouteNames.farmerPackageDetails,
        builder: (context, state) => const FarmerPackageDetailsScreen(),
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
