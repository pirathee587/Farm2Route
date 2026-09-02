import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Operations Panel'),
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
                color: const Color(0xFF2C3E50),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Farm2Route System Administration',
                    style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Platform Verification, Compliance, and Moderation',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Moderation & Approvals', style: AppTextStyles.headingSmall),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.verified_user, color: AppColors.primary),
              title: const Text('Agency & Driver KYC Verification'),
              subtitle: const Text('Review uploaded business documents'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.warning, color: AppColors.error),
              title: const Text('Incident Resolution'),
              subtitle: const Text('Investigate disputes & delays'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.history_edu, color: AppColors.primary),
              title: const Text('Audit Trail Logs'),
              subtitle: const Text('Inspect immutable platform actions'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
