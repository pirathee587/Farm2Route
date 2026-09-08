import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'login_required_sheet.dart';

class LandingTopBar extends ConsumerWidget {
  const LandingTopBar({super.key});

  void _navigateToRoleHome(BuildContext context, String? role) {
    final cleanRole = (role ?? '').toUpperCase();
    if (cleanRole == 'AGENCY') {
      context.go(RouteNames.agencyHome);
    } else if (cleanRole == 'ADMIN') {
      context.go(RouteNames.adminHome);
    } else if (cleanRole == 'DRIVER') {
      context.go(RouteNames.driverHome);
    } else {
      context.go(RouteNames.farmerHome);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isAuthenticated = authState.status == AuthStatus.authenticated;
    final role = authState.user?.role.toUpperCase() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          // Left: Guest / Profile Avatar
          InkWell(
            onTap: () {
              if (isAuthenticated) {
                _navigateToRoleHome(context, role);
              } else {
                LoginRequiredBottomSheet.show(context);
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isAuthenticated
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.surfaceSubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAuthenticated ? Icons.business_center_rounded : Icons.person_outline_rounded,
                color: isAuthenticated ? AppColors.primary : AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Center-Left: App Logo "🌾 Farm2Route"
          InkWell(
            onTap: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🌾',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Farm',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: '2',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Route',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          if (isAuthenticated) ...[
            // Authenticated: Direct CTA to Agency Portal or Dashboard
            SizedBox(
              height: 34,
              child: ElevatedButton.icon(
                key: const Key('landing_top_portal_button'),
                onPressed: () => _navigateToRoleHome(context, role),
                icon: const Icon(Icons.dashboard_rounded, size: 16),
                label: Text(
                  role == 'AGENCY'
                      ? 'Agency Portal'
                      : role == 'ADMIN'
                          ? 'Admin Portal'
                          : role == 'DRIVER'
                              ? 'Driver Portal'
                              : 'My Dashboard',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  elevation: 0,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Unauthenticated Right: [ Login ] Pill Button
            SizedBox(
              height: 34,
              child: OutlinedButton(
                key: const Key('landing_top_login_button'),
                onPressed: () => context.push(RouteNames.login),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  side: const BorderSide(color: AppColors.border, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                ),
                child: Text(
                  'Log in',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Right: [ Sign Up ] Filled Black/Green Button
            SizedBox(
              height: 34,
              child: ElevatedButton(
                key: const Key('landing_top_signup_button'),
                onPressed: () => context.push(RouteNames.register),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  elevation: 0,
                  backgroundColor: AppColors.textPrimary, // Uber Eats signature sleek black button
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Sign up',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
