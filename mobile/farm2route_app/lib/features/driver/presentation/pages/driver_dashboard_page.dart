import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../../../shared/widgets/agrizel_pill_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';

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
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 22),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Kamal Perera',
                                style: AppTextStyles.headingSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                                  Expanded(
                                    child: Text(
                                      'ONLINE • Truck #WP-4291',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const NotificationBell(),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                        tooltip: 'Sign Out',
                        onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
                      ),
                    ],
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
                              context.push(RouteNames.podSubmitWithId('book-8842'));
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2b. Dedicated POD Hub Banner Card
              AgrizelCard(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.assignment_turned_in_rounded,
                          color: AppColors.primaryDark, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Proof of Delivery (POD) Hub',
                              style: AppTextStyles.bodyLarge
                                  .copyWith(fontWeight: FontWeight.bold)),
                          Text(
                              'Manage cargo photos, signatures & delivery confirmations',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('btn_driver_pod_hub'),
                      icon: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: AppColors.primaryDark),
                      onPressed: () {
                        context.push(RouteNames.driverPodDashboard);
                      },
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
                key: const Key('btn_encountered_issue'),
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                onTap: () => _showReportIncidentSheet(context),
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
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
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

  void _showReportIncidentSheet(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    String selectedCategory = 'MECHANICAL_BREAKDOWN';
    final descController = TextEditingController();
    bool isUrgent = true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Report Route Incident / Delay',
                            style: AppTextStyles.headingSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Alert your agency dispatch team immediately about route issues.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Issue Type Dropdown
                    Text('Incident Type', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'MECHANICAL_BREAKDOWN',
                            child: Text('🔧 Mechanical Breakdown / Flat Tire', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(
                            value: 'ROAD_BLOCK', child: Text('🚧 Road Block / Detour', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(
                            value: 'ACCIDENT', child: Text('💥 Vehicle Collision / Damage', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(
                            value: 'WEATHER_DELAY', child: Text('🌧️ Flood / Severe Weather', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(
                            value: 'CARGO_ISSUE', child: Text('📦 Cargo Damage / Spill', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(
                            value: 'OTHER', child: Text('⚠️ Other Incident', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCategory = val);
                      },
                    ),

                    const SizedBox(height: 14),

                    // Description Input
                    Text('Description / Status', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Describe location, breakdown cause, or assistance needed...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Emergency Priority Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: isUrgent,
                          activeColor: AppColors.error,
                          onChanged: (val) {
                            setModalState(() => isUrgent = val ?? false);
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Request Immediate Emergency Tow / Dispatch Contact',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        key: const Key('btn_submit_route_incident'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Incident logged! Agency dispatch has been notified.'),
                              backgroundColor: AppColors.error,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Log Incident & Notify Agency'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
