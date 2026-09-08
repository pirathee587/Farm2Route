import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_pill_button.dart';

class LoginRequiredBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;

  const LoginRequiredBottomSheet({
    super.key,
    this.title = 'Login to continue your booking',
    this.subtitle,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'Login to continue your booking',
    String? subtitle,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => LoginRequiredBottomSheet(
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Illustration Badge
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_open_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            title,
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle / Intro
          Text(
            subtitle ?? 'Welcome to Farm2Route 👋\nSign in to unlock full booking, live hauler dispatch, and direct farmer-agency payments.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Benefits checkmarks
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildBenefitRow(Icons.receipt_long_rounded, 'Instant Freight Bookings & Haulage Requests'),
                const SizedBox(height: 10),
                _buildBenefitRow(Icons.location_searching_rounded, 'Real-time GPS Tracking & Dispatch Alerts'),
                const SizedBox(height: 10),
                _buildBenefitRow(Icons.payments_outlined, 'Transparent Pricing & Digital Invoicing'),
                const SizedBox(height: 10),
                _buildBenefitRow(Icons.shield_outlined, 'Verified Drivers & Cargo Insurance Protection'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // [ Login ] Button
          AgrizelPillButton(
            key: const Key('sheet_login_button'),
            text: 'Log In',
            icon: Icons.login_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              context.push(RouteNames.login);
            },
          ),
          const SizedBox(height: 12),

          // [ Create Account ] Button
          SizedBox(
            height: 52,
            child: OutlinedButton(
              key: const Key('sheet_signup_button'),
              onPressed: () {
                Navigator.of(context).pop();
                context.push(RouteNames.register);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                foregroundColor: AppColors.primaryDark,
              ),
              child: Text(
                'Create Account',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Dismiss text
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Continue browsing as guest',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
