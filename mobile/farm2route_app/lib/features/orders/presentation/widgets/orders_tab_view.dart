import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

class OrdersTabView extends StatelessWidget {
  final VoidCallback? onSwitchToMap;

  const OrdersTabView({super.key, this.onSwitchToMap});

  @override
  Widget build(BuildContext context) {
    final activeOrders = [
      {
        'trackingNumber': 'F2R-8849-LK',
        'crop': 'Carrots & Fresh Leeks',
        'weight': '4,800 kg',
        'lorry': 'WP-NB-4412 (Isuzu Elf 10-T)',
        'driver': 'Kamal Silva',
        'origin': 'Dambulla DEC Hub',
        'destination': 'Colombo Manning Market',
        'status': 'IN_TRANSIT',
        'statusLabel': 'In Transit • On Schedule',
        'statusColor': AppColors.primary,
        'eta': '1 hr 35 min',
        'dispatchedAt': '04:30 AM Today',
      },
      {
        'trackingNumber': 'F2R-7721-LK',
        'crop': 'Highland Beetroots',
        'weight': '3,200 kg',
        'lorry': 'CP-DA-8821 (Tata LPT 6-T)',
        'driver': 'Sunil Wickramasinghe',
        'origin': 'Nuwara Eliya Hub',
        'destination': 'Dambulla DEC Hub',
        'status': 'IN_TRANSIT',
        'statusLabel': 'In Transit • Approaching Naula',
        'statusColor': const Color(0xFFE08A00),
        'eta': '38 min',
        'dispatchedAt': '05:15 AM Today',
      },
      {
        'trackingNumber': 'F2R-6512-LK',
        'crop': 'Jaffna Red Onions',
        'weight': '2,500 kg',
        'lorry': 'NP-GH-3190 (Canter 4-T)',
        'driver': 'Ramesh Rajan',
        'origin': 'Jaffna Market Hub',
        'destination': 'Dambulla DEC Hub',
        'status': 'SCHEDULED',
        'statusLabel': 'Scheduled for Dispatch',
        'statusColor': const Color(0xFF1B4965),
        'eta': 'Tomorrow 06:00 AM',
        'dispatchedAt': 'Departure Pending',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded, color: AppColors.primaryDark, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Freight Dispatches',
                            style: AppTextStyles.headingMedium.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Active Agricultural Cargo Shipments & Tracking',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '3 Shipments',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Orders List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: activeOrders.length,
                itemBuilder: (context, index) {
                  final order = activeOrders[index];
                  final statusColor = order['statusColor'] as Color;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8EFE9), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Tracking Number and Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order['trackingNumber'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                order['statusLabel'] as String,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Crop and Weight
                        Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.black54),
                            const SizedBox(width: 6),
                            Text(
                              '${order['crop']} • ${order['weight']}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Route
                        Row(
                          children: [
                            const Icon(Icons.route_outlined, size: 16, color: Colors.black54),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${order['origin']} ➔ ${order['destination']}',
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Assigned Lorry & Driver
                        Row(
                          children: [
                            const Icon(Icons.local_shipping_rounded, size: 16, color: AppColors.primaryDark),
                            const SizedBox(width: 6),
                            Text(
                              '${order['lorry']} • Driver: ${order['driver']}',
                              style: const TextStyle(fontSize: 11, color: Colors.black54),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Bottom Actions: ETA & Track on Map
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ETA: ${order['eta']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: onSwitchToMap ??
                                  () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Opening Live GPS Map...'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                              icon: const Icon(Icons.map_rounded, size: 14),
                              label: const Text('Track Lorry on Map'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                backgroundColor: AppColors.primaryDark,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
