// ==============================================================================
// FarmerDashboardPage (Route Target / Backward Compatibility Adapter)
// ==============================================================================

import 'package:flutter/material.dart';
import '../screens/farmer_dashboard_screen.dart';

class FarmerDashboardPage extends StatelessWidget {
  const FarmerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FarmerDashboardScreen();
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
              // 1. Top Bar: Profile Header & Logout
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
                          child: Icon(Icons.person_outline_rounded,
                              color: AppColors.primary, size: 26),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Aiden Smith',
                            style: AppTextStyles.headingSmall,
                          ),
                          Text(
                            'Green Valley Farm • Farmer Hub',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
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

              // 2. Farmer Partner Portal Banner with Harvest Volume Stats
              AgrizelCard(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Harvest Volumes',
                            style: AppTextStyles.headingSmall),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryMuted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Active Season',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Visual Volume Bar Graph Indicator (Agrizel Theme)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildBar('May', 0.45),
                        _buildBar('Jun', 0.65),
                        _buildBar('Jul', 0.35),
                        _buildBar('Aug', 0.85, isHighlighted: true),
                        _buildBar('Sep', 0.50),
                      ],
                    ),
                    const Divider(height: 32, color: AppColors.border),
                    // Metrics Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricItem('Active Hauls', '3 Dispatches',
                            Icons.local_shipping_outlined),
                        _buildMetricItem('Delivered', '28.4 Tons',
                            Icons.check_circle_outline_rounded),
                        _buildMetricItem('Logistics Cost', '\$2,450',
                            Icons.payments_outlined),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Quick Action: Book a Logistics Truck (Primary Pill Button)
              AgrizelPillButton(
                text: 'Schedule Freight / Book a Truck',
                icon: Icons.add_circle_outline_rounded,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          const Text('Opening Freight Booking Assistant...'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // 4. Active Freight Dispatch Timeline Card (Agrizel Order Tracking Theme)
              Text('Live Shipment Pipeline', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),
              AgrizelCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Haul #FR-90097',
                              style: AppTextStyles.bodyLarge
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryMuted,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'IN TRANSIT',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '3.2 Tons Fresh Cabbage • Destination: Central Market',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    // Tracking Step Flow
                    _buildTrackingStep('Order Placed', 'June 15, 08:30 AM',
                        isCompleted: true),
                    _buildTrackingStep('Order Confirmed', 'June 15, 09:15 AM',
                        isCompleted: true),
                    _buildTrackingStep(
                        'Dispatched & Shipped', 'June 15, 10:45 AM',
                        isCompleted: true),
                    _buildTrackingStep(
                        'Out for Delivery', 'Driver Kamal • ETA 45m',
                        isCurrent: true),
                    _buildTrackingStep(
                        'Delivered & POD Verified', 'Pending arrival',
                        isPending: true, isLast: true),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 5. Farm Produce & Inventory Summary
              Text('Stored Harvest Ready for Transit',
                  style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildHarvestItem('Seasonal Cabbage', '4.2 Tons',
                        '★ 4.8', Icons.eco_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHarvestItem('Red Tomatoes', '2.8 Tons',
                        '★ 4.7', Icons.apple_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBar(String month, double pct, {bool isHighlighted = false}) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 90 * pct,
          decoration: BoxDecoration(
            color: isHighlighted
                ? AppColors.primary
                : AppColors.primaryLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        Text(month, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildMetricItem(String title, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(title, style: AppTextStyles.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingStep(
    String title,
    String subtitle, {
    bool isCompleted = false,
    bool isCurrent = false,
    bool isPending = false,
    bool isLast = false,
  }) {
    Color dotColor = AppColors.border;
    if (isCompleted) dotColor = AppColors.primary;
    if (isCurrent) dotColor = AppColors.accent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isCompleted ? AppColors.primary : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: isCurrent || isCompleted
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color:
                      isPending ? AppColors.textLight : AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isCurrent
                      ? AppColors.accentDark
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHarvestItem(
      String name, String qty, String rating, IconData icon) {
    return AgrizelCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 30, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(name,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(qty,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
              Text(rating,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.starAmber, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
