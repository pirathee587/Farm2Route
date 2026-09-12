// ==============================================================================
// Farmer Feature Route Configuration
// ==============================================================================
// Defines the entry route and sub-routes for the Farmer user persona,
// keeping farmer onboarding and portal completely segregated from Agency and Admin.
// ==============================================================================

import 'package:go_router/go_router.dart';
import '../../app/router/route_names.dart';
import 'presentation/screens/farmer_dashboard_screen.dart';
import 'presentation/screens/farmer_details_screen.dart';
import 'presentation/screens/farmer_hauler_results_screen.dart';
import 'presentation/screens/farmer_landing_screen.dart';
import 'presentation/screens/farmer_login_screen.dart';
import 'presentation/screens/farmer_otp_verify_screen.dart';
import 'presentation/screens/farmer_package_details_screen.dart';
import 'presentation/screens/farmer_phone_entry_screen.dart';

class FarmerRoutes {
  /// The initial welcome entry point for farmers (Uber/PickMe style landing)
  static const String initialRoute = RouteNames.farmerLanding;

  /// All routes belonging strictly to the Farmer feature
  static List<RouteBase> get routes => [
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
          path: RouteNames.farmerHome,
          builder: (context, state) => const FarmerDashboardScreen(),
        ),
        GoRoute(
          path: RouteNames.farmerHaulerResults,
          builder: (context, state) => const FarmerHaulerResultsScreen(),
        ),
        GoRoute(
          path: RouteNames.farmerPackageDetails,
          builder: (context, state) => const FarmerPackageDetailsScreen(),
        ),
      ];
}
