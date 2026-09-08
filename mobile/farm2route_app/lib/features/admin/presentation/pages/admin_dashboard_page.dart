import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Admin Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.primary, width: 1.5),
                        ),
                        child: const Center(
                          child: Icon(Icons.shield_outlined,
                              color: AppColors.primary, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('System Administration',
                              style: AppTextStyles.headingSmall),
                          Text('Platform Compliance & Governance',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.error),
                    tooltip: 'Sign Out',
                    onPressed: () =>
                        ref.read(authNotifierProvider.notifier).logout(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Platform Overview Counters (Agrizel Clean Aesthetic)
              Text('Platform Metrics', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard('Farmers', '1,240',
                        Icons.agriculture_rounded, AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard('Agencies', '85',
                        Icons.business_rounded, AppColors.accentDark),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard('Drivers', '412',
                        Icons.local_shipping_rounded, AppColors.info),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 3. Verification & KYC Action Queue
              Text('Pending Approvals & Verification',
                  style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),

              AgrizelCard(
                onTap: () {},
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_user_outlined,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Agency & Vehicle KYC',
                              style: AppTextStyles.bodyLarge
                                  .copyWith(fontWeight: FontWeight.bold)),
                          Text(
                              '5 business registration & emissions certificates pending review',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('5 NEW',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              AgrizelCard(
                onTap: () {},
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFEBEE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.report_problem_outlined,
                          color: AppColors.error, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Active Trip Incidents & Disputes',
                              style: AppTextStyles.bodyLarge
                                  .copyWith(fontWeight: FontWeight.bold)),
                          Text(
                              '1 cargo delay flag requiring settlement moderation',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('1 ACTION',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. Financial & Commission Ledger
              AgrizelCard(
                color: Colors.white,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Commission Clearing House',
                            style: AppTextStyles.bodyLarge
                                .copyWith(fontWeight: FontWeight.bold)),
                        Text('This Month', style: AppTextStyles.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Platform Gross Freight',
                                style: AppTextStyles.bodySmall),
                            Text('\$142,800',
                                style: AppTextStyles.headingMedium
                                    .copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Net Commission (3%)',
                                style: AppTextStyles.bodySmall),
                            Text(
                              '\$4,284',
                              style: AppTextStyles.headingMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String label, String count, IconData icon, Color color) {
    return AgrizelCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(count,
              style: AppTextStyles.headingSmall
                  .copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
