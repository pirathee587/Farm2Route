import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../../agency/presentation/widgets/agency_pod_details_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../driver/presentation/pages/pod_submission_page.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../data/models/admin_stats_model.dart';
import '../providers/admin_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  void _showAdminPodDialog(BuildContext context) {
    final bookingIdController = TextEditingController();
    final isMobile = MediaQuery.sizeOf(context).width < 500;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Proof of Delivery (POD)',
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Booking ID or Reference to submit digital POD or inspect existing verifications:',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bookingIdController,
              decoration: const InputDecoration(
                labelText: 'Booking ID / Reference',
                hintText: 'e.g., book-8842 or BKG-8842',
                prefixIcon: Icon(Icons.receipt_long),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: isMobile
            ? [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('View POD'),
                      onPressed: () {
                        final id = bookingIdController.text.trim().isEmpty
                            ? 'book-8842'
                            : bookingIdController.text.trim();
                        Navigator.pop(c);
                        AgencyPodDetailsDialog.show(context, id, id);
                      },
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                      label: const Text('Submit POD'),
                      onPressed: () {
                        final id = bookingIdController.text.trim().isEmpty
                            ? 'book-8842'
                            : bookingIdController.text.trim();
                        Navigator.pop(c);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PodSubmissionPage(bookingId: id)),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ]
            : [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Cancel'),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                  label: const Text('Submit POD'),
                  onPressed: () {
                    final id = bookingIdController.text.trim().isEmpty
                        ? 'book-8842'
                        : bookingIdController.text.trim();
                    Navigator.pop(c);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PodSubmissionPage(bookingId: id)),
                    );
                  },
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('View POD'),
                  onPressed: () {
                    final id = bookingIdController.text.trim().isEmpty
                        ? 'book-8842'
                        : bookingIdController.text.trim();
                    Navigator.pop(c);
                    AgencyPodDetailsDialog.show(context, id, id);
                  },
                ),
              ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminStatsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.shield_outlined,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'System Administration',
                              style: AppTextStyles.headingSmall,
                            ),
                            Text(
                              'Platform Compliance & Governance',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const NotificationBell(),
                        IconButton(
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.error,
                          ),
                          tooltip: 'Sign Out',
                          onPressed: () =>
                              ref.read(authNotifierProvider.notifier).logout(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Platform Overview Counters (Agrizel Clean Aesthetic)
                Text('Platform Metrics', style: AppTextStyles.headingSmall),
                const SizedBox(height: 12),

                statsAsync.when(
                  data: (stats) => _buildMetricsRow(stats),
                  loading: () => _buildMetricsRowLoading(),
                  error: (error, stack) => _buildErrorCard(
                    context: context,
                    message: error.toString(),
                    onRetry: () => ref.invalidate(adminStatsProvider),
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Verification & KYC Action Queue
                Text(
                  'Pending Approvals & Verification',
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: 12),

                // Permanent Driver POD Action Card
                AgrizelCard(
                  key: const Key('pod_admin_action_card'),
                  onTap: () {
                    _showAdminPodDialog(context);
                  },
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: AppColors.success,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Driver: Submit & Verify Proof of Delivery (POD)',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Submit delivery signatures, photo evidence & GPS coordinates or view verifications',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'POD SYSTEM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                statsAsync.when(
                  data: (stats) => Column(
                    children: [
                      AgrizelCard(
                        key: const Key('kyc_action_card'),
                        onTap: () {
                          context.push(RouteNames.adminKyc);
                        },
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_user_outlined,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Agency & Vehicle KYC',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${stats.pendingKycs} ${stats.pendingKycs == 1 ? 'item' : 'items'} pending review',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${stats.pendingKycs} NEW',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AgrizelCard(
                        key: const Key('incidents_action_card'),
                        onTap: () {
                          context.push(RouteNames.adminIncidents);
                        },
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFEBEE),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.report_problem_outlined,
                                color: AppColors.error,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Active Trip Incidents & Disputes',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${stats.openIncidents} open ${stats.openIncidents == 1 ? 'incident' : 'incidents'} requiring moderation',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${stats.openIncidents} ACTION',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AgrizelCard(
                        key: const Key('reviews_action_card'),
                        onTap: () {
                          context.push(RouteNames.adminReviews);
                        },
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF3E0),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.rate_review_outlined,
                                color: AppColors.accent,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Review Moderation Queue',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Flagged & reported reviews queue',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AgrizelCard(
                        key: const Key('audit_logs_action_card'),
                        onTap: () {
                          context.push(RouteNames.adminAuditLogs);
                        },
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F5E9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_outlined,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Platform Audit Logs',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Compliance, system events & state diffs',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
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
                          Text(
                            'Commission Clearing House',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                              Text(
                                'Platform Gross Freight',
                                style: AppTextStyles.bodySmall,
                              ),
                              Text(
                                '\$142,800',
                                style: AppTextStyles.headingMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Net Commission (3%)',
                                style: AppTextStyles.bodySmall,
                              ),
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
      ),
    );
  }

  Widget _buildMetricsRow(AdminStatsModel stats) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Farmers',
            stats.totalFarmers.toString(),
            Icons.agriculture_rounded,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            'Agencies',
            stats.totalAgencies.toString(),
            Icons.business_rounded,
            AppColors.accentDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            'Drivers',
            stats.totalDrivers.toString(),
            Icons.local_shipping_rounded,
            AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRowLoading() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Farmers',
            '...',
            Icons.agriculture_rounded,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            'Agencies',
            '...',
            Icons.business_rounded,
            AppColors.accentDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            'Drivers',
            '...',
            Icons.local_shipping_rounded,
            AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard({
    required BuildContext context,
    required String message,
    required VoidCallback onRetry,
  }) {
    return AgrizelCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Failed to load admin stats',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
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
          Text(
            count,
            key: Key('metric_$label'),
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
