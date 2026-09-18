import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../../../shared/widgets/agrizel_pill_button.dart';

class DriverPodDashboardPage extends ConsumerWidget {
  const DriverPodDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mockTrips = [
      {
        'id': 'book-8842',
        'ref': 'Trip #FR-90097',
        'cargo': '3.5 Tons Fresh Cabbage',
        'origin': 'Green Valley Farm, Nuwara Eliya',
        'destination': 'Dambulla Wholesale Hub',
        'recipient': 'Sunil Perera (+94771234567)',
        'status': 'PENDING_SUBMISSION',
        'statusLabel': 'POD Pending Submission',
        'statusColor': const Color(0xFFE08A00),
      },
      {
        'id': 'F2R-8849-LK',
        'ref': 'Trip #F2R-8849-LK',
        'cargo': 'Carrots & Fresh Leeks (4,800 kg)',
        'origin': 'Dambulla DEC Hub',
        'destination': 'Colombo Manning Market',
        'recipient': 'Kamal Silva (+94719876543)',
        'status': 'DELIVERED',
        'statusLabel': 'Delivered & Verified',
        'statusColor': AppColors.success,
      },
      {
        'id': 'F2R-7721-LK',
        'ref': 'Trip #F2R-7721-LK',
        'cargo': 'Highland Beetroots (3,200 kg)',
        'origin': 'Nuwara Eliya Hub',
        'destination': 'Dambulla DEC Hub',
        'recipient': 'Anura Wickrama (+94723334444)',
        'status': 'CONFIRMED',
        'statusLabel': 'Farmer Confirmed',
        'statusColor': AppColors.primary,
      },
      {
        'id': 'F2R-6512-LK',
        'ref': 'Trip #F2R-6512-LK',
        'cargo': 'Jaffna Red Onions (2,500 kg)',
        'origin': 'Jaffna Market Hub',
        'destination': 'Dambulla DEC Hub',
        'recipient': 'Ramesh Rajan (+94778889999)',
        'status': 'DISPUTED',
        'statusLabel': 'Disputed by Farmer',
        'statusColor': AppColors.error,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        title: const Text('Driver POD Hub'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Metric Summary Cards Header
              Row(
                children: [
                  Expanded(
                    child: AgrizelCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.assignment_turned_in_rounded,
                              color: AppColors.primary, size: 22),
                          const SizedBox(height: 6),
                          Text('14',
                              style: AppTextStyles.headingMedium
                                  .copyWith(fontWeight: FontWeight.bold)),
                          Text('PODs Uploaded', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AgrizelCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 22),
                          const SizedBox(height: 6),
                          Text('12',
                              style: AppTextStyles.headingMedium
                                  .copyWith(fontWeight: FontWeight.bold)),
                          Text('Farmer Confirmed', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AgrizelCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.error, size: 22),
                          const SizedBox(height: 6),
                          Text('1',
                              style: AppTextStyles.headingMedium
                                  .copyWith(fontWeight: FontWeight.bold)),
                          Text('Disputed', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 2. Active Haul POD Spotlight Card
              Text('Active Haul - Immediate Action Required',
                  style: AppTextStyles.headingSmall),
              const SizedBox(height: 10),
              AgrizelCard(
                color: Colors.white,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFFFB74D), width: 1),
                          ),
                          child: const Text(
                            'DELIVERY PENDING POD',
                            style: TextStyle(
                              color: Color(0xFFE65100),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text('book-8842',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textLight)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '3.5 Tons Fresh Cabbage',
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.route_outlined,
                            size: 16, color: Colors.black54),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Green Valley Farm ➔ Dambulla Wholesale Hub',
                            style: AppTextStyles.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: AgrizelPillButton(
                        key: const Key('btn_submit_active_pod'),
                        text: 'Submit Proof of Delivery',
                        icon: Icons.qr_code_scanner_rounded,
                        onPressed: () {
                          context.push(RouteNames.podSubmitWithId('book-8842'));
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. POD Submissions History List
              Text('Recent POD Submissions', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),

              ...mockTrips.map((trip) {
                final statusColor = trip['statusColor'] as Color;
                final isPendingSubmit = trip['status'] == 'PENDING_SUBMISSION';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8EFE9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            trip['ref'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: statusColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              trip['statusLabel'] as String,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        trip['cargo'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 15, color: Colors.black54),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Recipient: ${trip['recipient']}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final bId = trip['id'] as String;
                                if (isPendingSubmit) {
                                  context.push(
                                      RouteNames.podSubmitWithId(bId));
                                } else {
                                  context.push(
                                      RouteNames.farmerPodReviewWithId(bId));
                                }
                              },
                              icon: Icon(
                                isPendingSubmit
                                    ? Icons.file_upload_outlined
                                    : Icons.visibility_outlined,
                                size: 14,
                              ),
                              label: Text(isPendingSubmit
                                  ? 'Upload POD'
                                  : 'View POD Details'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                foregroundColor: AppColors.primaryDark,
                                side: const BorderSide(
                                    color: AppColors.primaryDark),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
