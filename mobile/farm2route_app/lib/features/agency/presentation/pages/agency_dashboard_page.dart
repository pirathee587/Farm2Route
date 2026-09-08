import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../../../shared/widgets/agrizel_pill_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AgencyDashboardPage extends ConsumerWidget {
  const AgencyDashboardPage({super.key});

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
              // 1. Header & Sign Out
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
                          child: Icon(Icons.business_rounded, color: AppColors.primary, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'SwiftAgri Fleet Agency',
                            style: AppTextStyles.headingSmall,
                          ),
                          Text(
                            'Fleet Logistics & Driver Management',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
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

              // 2. Earnings Wallet Card (Agrizel Clean Aesthetic)
              AgrizelCard(
                color: AppColors.primary,
                padding: const EdgeInsets.all(20),
                hasBorder: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Agency Balance',
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('VERIFIED AGENCY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$8,420.50',
                      style: AppTextStyles.displayLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AgrizelPillButton(
                            text: 'Withdraw Funds',
                            height: 38,
                            backgroundColor: Colors.white,
                            textColor: AppColors.primary,
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AgrizelPillButton(
                            text: 'Fleet Records',
                            height: 38,
                            isOutlined: true,
                            backgroundColor: Colors.white,
                            textColor: Colors.white,
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Fleet Utilization Counters
              Text('Fleet Capacity Status', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFleetCounter('Active on Road', '8 Trucks', AppColors.primary, Icons.navigation_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFleetCounter('Available', '5 Trucks', AppColors.success, Icons.check_circle_outline),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFleetCounter('Service Due', '1 Truck', AppColors.warning, Icons.build_circle_outlined),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 4. Incoming Farmer Freight Bookings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Incoming Freight Orders', style: AppTextStyles.headingSmall),
                  Text('3 PENDING', style: AppTextStyles.tagText.copyWith(color: AppColors.accentDark)),
                ],
              ),
              const SizedBox(height: 12),

              AgrizelCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Nuwara Eliya ➔ Dambulla Hub', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                        Text('\$340', style: AppTextStyles.headingSmall.copyWith(color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Farmer: Sunil Bandara • 4.5 Tons Potatoes • Pickup: Today, 3 PM', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AgrizelPillButton(
                            text: 'Assign Truck & Driver',
                            height: 38,
                            icon: Icons.assignment_turned_in_rounded,
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 10),
                        AgrizelPillButton(
                          text: 'Decline',
                          height: 38,
                          isOutlined: true,
                          backgroundColor: AppColors.error,
                          textColor: AppColors.error,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 5. Driver Fleet Quick Roster
              Text('Driver Telemetry Roster', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),
              AgrizelCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildDriverRow('Kamal Perera', 'Truck #WP-4291', 'On Route to Hub', true),
                    const Divider(height: 18, color: AppColors.border),
                    _buildDriverRow('Nuwan Silva', 'Truck #SP-8832', 'Idle at Terminal', false),
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

  Widget _buildFleetCounter(String label, String value, Color color, IconData icon) {
    return AgrizelCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildDriverRow(String name, String truck, String status, bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceSubtle,
              child: Icon(Icons.person, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                Text(truck, style: AppTextStyles.bodySmall),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryContainer : AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            status,
            style: AppTextStyles.bodySmall.copyWith(
              color: isActive ? AppColors.primaryDark : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}
