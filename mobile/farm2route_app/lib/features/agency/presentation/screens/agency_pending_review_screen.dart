import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../../../shared/widgets/agrizel_pill_button.dart';
import '../../../../shared/widgets/farm2route_logo.dart';
import '../providers/agency_verify_provider.dart';

class AgencyPendingReviewScreen extends ConsumerWidget {
  const AgencyPendingReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verifyState = ref.watch(agencyVerifyNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Center(
                child: Farm2RouteLogo(
                  size: 64,
                  showWordmark: false,
                ),
              ),
              const SizedBox(height: 24),

              // Central badge
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.primary,
                      size: 52,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Application Submitted!',
                style: AppTextStyles.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your contact credentials have been verified. Your logistics agency profile has been submitted to the platform administration for approval.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Status Details Card
              AgrizelCard(
                borderRadius: 20,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Steps & Timeline',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildTimelineItem(
                      icon: Icons.check_circle_rounded,
                      iconColor: AppColors.primary,
                      title: 'Dual Verification Complete',
                      subtitle: 'Phone (+94) and email addresses are verified.',
                      isCompleted: true,
                    ),
                    const SizedBox(height: 14),
                    _buildTimelineItem(
                      icon: Icons.schedule_rounded,
                      iconColor: AppColors.warning,
                      title: 'Admin Background Review',
                      subtitle: 'Verification of business registration number and operational coverage (24-48 hrs).',
                      isCompleted: false,
                    ),
                    const SizedBox(height: 14),
                    _buildTimelineItem(
                      icon: Icons.local_shipping_outlined,
                      iconColor: AppColors.textLight,
                      title: 'Fleet Activation & Dispatch',
                      subtitle: 'Receive notification to sign in, deploy vehicles, and accept agricultural freight bids.',
                      isCompleted: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Rejection notice if any
              if (verifyState.status == 'REJECTED') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Application Declined',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Reason: Your registration could not be verified at this time.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // CTA Buttons
              AgrizelPillButton(
                key: const Key('agency_back_to_login_button'),
                text: 'Back to Sign In',
                onPressed: () {
                  context.go(RouteNames.login);
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('agency_refresh_status_button'),
                onPressed: () =>
                    ref.read(agencyVerifyNotifierProvider.notifier).checkStatus(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Check Review Status'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isCompleted,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
