import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../../../shared/widgets/agrizel_pill_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DriverDashboardPage extends ConsumerWidget {
  const DriverDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Driver Status Header
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
                          child: Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Kamal Perera',
                            style: AppTextStyles.headingSmall,
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ONLINE • Truck #WP-4291',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                    tooltip: 'Sign Out',
                    onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Active Haul Spotlight Card (Agrizel Theme)
              AgrizelCard(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'CURRENT ASSIGNED HAUL',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          'Trip #FR-90097',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Route Timeline Visual
                    Row(
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.radio_button_checked, color: AppColors.primary, size: 18),
                            Container(width: 2, height: 28, color: AppColors.border),
                            const Icon(Icons.location_on, color: AppColors.accentDark, size: 18),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Green Valley Farm, Nuwara Eliya', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                              Text('Cargo: 3.5 Tons Fresh Cabbage', style: AppTextStyles.bodySmall),
                              const SizedBox(height: 10),
                              Text('Dambulla Dedicated Wholesale Hub', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                              Text('Expected Window: 02:30 PM Today', style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28, color: AppColors.border),
                    // Action Buttons for Driver
                    Row(
                      children: [
                        Expanded(
                          child: AgrizelPillButton(
                            text: 'Start GPS Nav',
                            height: 42,
                            icon: Icons.navigation_rounded,
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AgrizelPillButton(
                            text: 'Digital POD',
                            height: 42,
                            isOutlined: true,
                            icon: Icons.qr_code_scanner_rounded,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Launching Proof of Delivery Camera & Signature...'),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Driver Performance & Today's Earnings
              Text("Today's Haul Summary", style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AgrizelCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.payments_outlined, color: AppColors.primary, size: 22),
                          const SizedBox(height: 8),
                          Text('\$85.00', style: AppTextStyles.headingMedium.copyWith(fontWeight: FontWeight.bold)),
                          Text('Earnings Today', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AgrizelCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.route_outlined, color: AppColors.primary, size: 22),
                          const SizedBox(height: 8),
                          Text('148 km', style: AppTextStyles.headingMedium.copyWith(fontWeight: FontWeight.bold)),
                          Text('Distance Logged', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 4. Incident & Breakdown Reporting Pill
              AgrizelCard(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFEBEE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Encountered an Issue on Route?', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                          Text('Log breakdown, road block, or delay for instant agency support', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
                      onPressed: () {},
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
}
