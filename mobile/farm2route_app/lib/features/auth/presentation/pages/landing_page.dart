export 'package:farm2route_app/features/landing/presentation/screens/public_landing_screen.dart';

import 'package:flutter/widgets.dart';
import 'package:farm2route_app/features/landing/presentation/screens/public_landing_screen.dart';

/// Public Farm2Route landing screen (Uber Eats style agricultural transport hub)
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PublicLandingScreen();
  }
}
