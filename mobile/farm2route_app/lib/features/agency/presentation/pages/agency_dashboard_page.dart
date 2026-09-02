import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AgencyDashboardPage extends ConsumerWidget {
  const AgencyDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agency Fleet Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentDark, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logistics Fleet Management',
                    style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Company: ${authState.user?.fullName ?? "Agency"}',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Operations', style: AppTextStyles.headingSmall),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.directions_bus, color: AppColors.primary),
              title: const Text('Manage Vehicles'),
              subtitle: const Text('Fleet capacity & maintenance'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.badge, color: AppColors.primary),
              title: const Text('Registered Drivers'),
              subtitle: const Text('Driver KYC & status'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.inventory, color: AppColors.primary),
              title: const Text('Incoming Bookings'),
              subtitle: const Text('Review and accept transport requests'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
