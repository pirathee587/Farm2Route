// ==============================================================================
// FarmerDashboardScreen
// ==============================================================================
// NOTE FOR CONTRIBUTORS:
// This screen is accessed ONLY AFTER successful farmer login or signup.
// It is completely distinct from `farmer_landing_screen.dart` (which is the
// public welcoming/entry screen with "Get Started" and "Log in" CTAs).
//
// UI ARCHITECTURE:
// 1. Top Header: Pickup farm/hub location dropdown + notification badge.
// 2. Filter Tabs: All, Express Haul, Harvests, Bulk Freight pills.
// 3. Uber-style Booking Card: Pickup, Destination, Dispatch Date with live slot
//    counts and greyed-out fully-booked dates, Weight (kg/tons toggle), Produce
//    Type dropdown, live distance & fare estimate, and "Find Available Haulers" CTA.
// 4. Featured Logistics Packages: Horizontal scroll cards with skeleton shimmer.
// 5. Recent Orders: Recent bookings with status chips.
// 6. Bottom Navigation Bar: Home, Map, Prices, Orders, Account.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../../../shared/widgets/agrizel_pill_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../market_prices/presentation/widgets/market_prices_view.dart';
import '../../../orders/presentation/widgets/orders_tab_view.dart';
import '../../../tracking/presentation/widgets/live_truck_map_view.dart';
import '../../data/models/farmer_dashboard_models.dart';
import '../providers/farmer_dashboard_provider.dart';
import 'farmer_hauler_results_screen.dart';
import 'farmer_package_details_screen.dart';

class FarmerDashboardScreen extends ConsumerStatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  ConsumerState<FarmerDashboardScreen> createState() =>
      _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends ConsumerState<FarmerDashboardScreen> {
  int _selectedBottomNav = 0; // 0: Home, 1: Map, 2: Prices, 3: Orders, 4: Account
  int _selectedFilterTab = 0;
  final TextEditingController _weightController = TextEditingController(text: '1500');

  // Pre-configured wholesale destination markets in Sri Lanka
  static const List<Map<String, String>> _wholesaleMarkets = [
    {
      'title': 'Manning Wholesale Market, Colombo',
      'city': 'Peliyagoda, Western Province',
      'desc': 'Primary National Terminal for Vegetables & Fruits',
    },
    {
      'title': 'Dambulla Dedicated Economic Centre',
      'city': 'Dambulla, Central Province',
      'desc': 'National Vegetable & Onion Trading Hub',
    },
    {
      'title': 'Kandy Central Distribution Yard',
      'city': 'Kandy, Central Province',
      'desc': 'Central Province Bulk Produce Terminal',
    },
    {
      'title': 'Nuwara Eliya Cold Logistics Center',
      'city': 'Nuwara Eliya, Central Province',
      'desc': 'Highland Vegetable Consolidation Depot',
    },
    {
      'title': 'Negombo Agro & Seafood Exchange',
      'city': 'Negombo, Western Province',
      'desc': 'Coastal & Western Retail/Wholesale Exchange',
    },
    {
      'title': 'Jaffna Regional Agro Terminal',
      'city': 'Jaffna, Northern Province',
      'desc': 'Northern Red Onion & Grain Terminal',
    },
  ];

  static const List<Map<String, String>> _pickupFarmLocations = [
    {'title': 'My Farm, Dambulla Hub', 'desc': 'Primary Registered Farm Gate'},
    {'title': 'Pelwehera Harvest Store, Dambulla', 'desc': 'Storage Shed #2'},
    {'title': 'Naula Farm Collection Point', 'desc': 'Feeder Road Plot'},
    {'title': 'Galewela Cooperative Yard', 'desc': 'Community Collection'},
  ];

  static const List<Map<String, dynamic>> _filterTabs = [
    {'name': 'All', 'icon': Icons.all_inclusive_rounded},
    {'name': 'Express Haul', 'icon': Icons.directions_run_rounded},
    {'name': 'Harvests', 'icon': Icons.eco_rounded},
    {'name': 'Bulk Freight', 'icon': Icons.local_shipping_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _weightController.addListener(() {
      final val = double.tryParse(_weightController.text);
      if (val != null) {
        ref.read(bookingFormNotifierProvider.notifier).setWeight(val);
      }
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _openPickupLocationPicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Pickup Farm Location',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: 12),
            ..._pickupFarmLocations.map((loc) {
              final isSelected =
                  ref.read(bookingFormNotifierProvider).pickupLocation ==
                      loc['title'];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryLight
                        : AppColors.surfaceSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.store_mall_directory_rounded,
                    color: isSelected
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                title: Text(
                  loc['title']!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                subtitle: Text(loc['desc']!, style: AppTextStyles.bodySmall),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref
                      .read(bookingFormNotifierProvider.notifier)
                      .setPickupLocation(loc['title']!);
                  Navigator.of(ctx).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _openDestinationMarketPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Destination Wholesale Market',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Major Dedicated Economic Centres across Sri Lanka',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: _wholesaleMarkets.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (_, index) {
                    final market = _wholesaleMarkets[index];
                    final isSelected = ref
                            .read(bookingFormNotifierProvider)
                            .destinationLocation ==
                        market['title'];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.surfaceSubtle,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_city_rounded,
                          color: isSelected
                              ? AppColors.primaryDark
                              : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        market['title']!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${market['city']} • ${market['desc']}',
                        style: AppTextStyles.bodySmall,
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                            )
                          : null,
                      onTap: () {
                        ref
                            .read(bookingFormNotifierProvider.notifier)
                            .setDestinationLocation(market['title']!);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAvailabilityDatePicker() async {
    final now = DateTime.now();
    final repo = ref.read(farmerDashboardRepositoryProvider);
    final slots = await repo.checkAvailability(now);

    if (!mounted) return;

    final selectedDate = ref.read(bookingFormNotifierProvider).dispatchDate;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Dispatch Date',
                    style: AppTextStyles.headingSmall,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Live Hauler Slots',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Dates with zero slots indicate peak market congestion.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 16),

              // Calendar Slot Grid for Next 14 Days
              SizedBox(
                height: 240,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: 14,
                  itemBuilder: (context, idx) {
                    final dayDate = now.add(Duration(days: idx));
                    final slotMatch = slots.firstWhere(
                      (s) =>
                          s.date.year == dayDate.year &&
                          s.date.month == dayDate.month &&
                          s.date.day == dayDate.day,
                      orElse: () => DispatchAvailabilitySlot(
                        date: dayDate,
                        availableSlots: (idx == 3 || idx == 10) ? 0 : 6,
                        isFullyBooked: idx == 3 || idx == 10,
                      ),
                    );

                    final isSelected = selectedDate.year == dayDate.year &&
                        selectedDate.month == dayDate.month &&
                        selectedDate.day == dayDate.day;
                    final isFull = slotMatch.isFullyBooked || slotMatch.availableSlots == 0;

                    return GestureDetector(
                      onTap: isFull
                          ? null
                          : () {
                              ref
                                  .read(bookingFormNotifierProvider.notifier)
                                  .setDispatchDate(dayDate);
                              Navigator.of(sheetCtx).pop();
                            },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isFull
                              ? const Color(0xFFF0F0F0)
                              : (isSelected
                                  ? AppColors.primaryLight
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFull
                                ? Colors.transparent
                                : (isSelected
                                    ? AppColors.primary
                                    : AppColors.border),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${dayDate.day} ${_monthName(dayDate.month)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isFull
                                    ? AppColors.textLight
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isFull
                                  ? 'Full'
                                  : '${slotMatch.availableSlots} slots',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 10,
                                color: isFull
                                    ? AppColors.error
                                    : AppColors.primaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Future<void> _handleFindHaulers() async {
    final formNotifier = ref.read(bookingFormNotifierProvider.notifier);
    final formState = ref.read(bookingFormNotifierProvider);

    if (formState.weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid harvest cargo weight'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }

    final haulers = await formNotifier.findHaulers();

    if (!mounted) return;

    // Navigate to Hauler Results Screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => FarmerHaulerResultsScreen(initialHaulers: haulers),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget activeBody;
    switch (_selectedBottomNav) {
      case 1:
        activeBody = Scaffold(
          appBar: AppBar(
            title: const Text('Live Tracking Map'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedBottomNav = 0),
            ),
          ),
          body: const LiveTruckMapView(),
        );
        break;
      case 2:
        activeBody = Scaffold(
          appBar: AppBar(
            title: const Text('Market Prices'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedBottomNav = 0),
            ),
          ),
          body: const MarketPricesView(),
        );
        break;
      case 3:
        activeBody = Scaffold(
          appBar: AppBar(
            title: const Text('My Dispatches'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedBottomNav = 0),
            ),
          ),
          body: OrdersTabView(
            onSwitchToMap: () => setState(() => _selectedBottomNav = 1),
          ),
        );
        break;
      case 4:
        activeBody = _buildAccountTab();
        break;
      case 0:
      default:
        activeBody = _buildDashboardHome();
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      body: activeBody,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            _buildBottomNavItem(Icons.home_rounded, 'Home', 0),
            _buildBottomNavItem(Icons.map_rounded, 'Map', 1),
            _buildBottomNavItem(Icons.trending_up_rounded, 'Prices', 2),
            _buildBottomNavItem(Icons.local_shipping_outlined, 'Orders', 3),
            _buildBottomNavItem(Icons.person_outline_rounded, 'Account', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHome() {
    final formState = ref.watch(bookingFormNotifierProvider);
    final packagesAsync = ref.watch(featuredPackagesProvider);
    final ordersAsync = ref.watch(recentOrdersProvider);

    return SafeArea(
      child: Column(
          children: [
            // =================================================================
            // 1. TOP HEADER (Hub Location dropdown & Notification bell)
            // =================================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Pickup Hub Selector Dropdown
                  GestureDetector(
                    onTap: _openPickupLocationPicker,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.agriculture_rounded,
                            size: 18,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PICKUP FARM GATE',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textLight,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  formState.pickupLocation,
                                  style: AppTextStyles.headingSmall.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down_rounded, size: 20),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Notification Bell with Badge
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, size: 26),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('2 upcoming dispatches scheduled'),
                              backgroundColor: AppColors.primaryDark,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: AppColors.promoRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable Dashboard Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // =========================================================
                    // 2. HORIZONTAL FILTER TABS (Chips)
                    // =========================================================
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filterTabs.length,
                        itemBuilder: (context, idx) {
                          final tab = _filterTabs[idx];
                          final isSelected = _selectedFilterTab == idx;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedFilterTab = idx),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryLight
                                    : AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(20),
                                border: isSelected
                                    ? Border.all(
                                        color: AppColors.primary,
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    tab['icon'] as IconData,
                                    size: 16,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tab['name'] as String,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.primaryDark
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // =========================================================
                    // 3. UBER-STYLE BOOKING WIDGET CARD
                    // =========================================================
                    AgrizelCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.local_shipping_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Dispatch Booking',
                                style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
                              ),
                              const Spacer(),
                              Text(
                                'Direct Farm Route',
                                style: AppTextStyles.tagText.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Pickup Location Field
                          GestureDetector(
                            onTap: _openPickupLocationPicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.circle, size: 10, color: AppColors.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Pickup', style: AppTextStyles.bodySmall),
                                        Text(
                                          formState.pickupLocation,
                                          style: AppTextStyles.bodyLarge.copyWith(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.edit_location_alt_rounded, size: 18, color: AppColors.textLight),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Destination Location Field (Searchable Wholesale Markets)
                          GestureDetector(
                            onTap: _openDestinationMarketPicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 16, color: AppColors.promoRed),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Destination Wholesale Market', style: AppTextStyles.bodySmall),
                                        Text(
                                          formState.destinationLocation,
                                          style: AppTextStyles.bodyLarge.copyWith(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.search_rounded, size: 18, color: AppColors.textLight),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Row: Dispatch Date & Cargo Weight
                          Row(
                            children: [
                              // Dispatch Date
                              Expanded(
                                flex: 3,
                                child: GestureDetector(
                                  onTap: _openAvailabilityDatePicker,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceSubtle,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Dispatch Date', style: AppTextStyles.bodySmall),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${formState.dispatchDate.day} ${_monthName(formState.dispatchDate.month)}',
                                              style: AppTextStyles.bodyLarge.copyWith(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Cargo Weight with Unit Toggle
                              Expanded(
                                flex: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceSubtle,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Cargo Weight', style: AppTextStyles.bodySmall),
                                            SizedBox(
                                              height: 32,
                                              child: TextField(
                                                controller: _weightController,
                                                keyboardType: TextInputType.number,
                                                style: AppTextStyles.bodyLarge.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                                decoration: const InputDecoration(
                                                  border: InputBorder.none,
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.zero,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Unit Toggle (kg / tons)
                                      GestureDetector(
                                        onTap: () {
                                          final nextUnit =
                                              formState.weightUnit == 'kg' ? 'tons' : 'kg';
                                          ref
                                              .read(bookingFormNotifierProvider.notifier)
                                              .setWeightUnit(nextUnit);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryContainer,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            formState.weightUnit.toUpperCase(),
                                            style: AppTextStyles.bodySmall.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primaryDark,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Produce Type dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: formState.produceType,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                onChanged: (newType) {
                                  if (newType != null) {
                                    ref
                                        .read(bookingFormNotifierProvider.notifier)
                                        .setProduceType(newType);
                                  }
                                },
                                items: const [
                                  DropdownMenuItem(
                                    value: 'VEGETABLES',
                                    child: Text('🥬 Fresh Vegetables & Greens'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'FRUITS',
                                    child: Text('🍎 Tropical Fruits & Melons'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'GRAINS',
                                    child: Text('🌾 Paddy, Rice & Grains'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'DAIRY',
                                    child: Text('🥛 Dairy & Perishables (Reefer)'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'OTHER',
                                    child: Text('📦 Other Agricultural Produce'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Live Estimated Distance & Fare Summary Banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.route_rounded, size: 16, color: AppColors.primaryDark),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${formState.fareEstimate?.distanceKm ?? 148} km • ${formState.fareEstimate?.durationText ?? '3 hr 30 min'}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Est. ${formState.fareEstimate?.formattedFare ?? 'LKR 18,500'}',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Primary CTA Button: "Find Available Haulers"
                          AgrizelPillButton(
                            text: 'Find Available Haulers',
                            isLoading: formState.isSearching,
                            icon: Icons.search_rounded,
                            onPressed: _handleFindHaulers,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // =========================================================
                    // 5. FEATURED PACKAGES SECTION (Horizontal Scroll)
                    // =========================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Featured Logistics Packages',
                          style: AppTextStyles.headingSmall.copyWith(fontSize: 17),
                        ),
                        Text(
                          'Guaranteed Slots',
                          style: AppTextStyles.tagText.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    packagesAsync.when(
                      data: (packages) => SizedBox(
                        height: 165,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: packages.length,
                          itemBuilder: (context, idx) {
                            final pkg = packages[idx];
                            return _buildPackageCard(pkg);
                          },
                        ),
                      ),
                      loading: () => _buildPackagesShimmer(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),

                    // =========================================================
                    // 6. RECENT ORDERS SECTION
                    // =========================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Dispatches',
                          style: AppTextStyles.headingSmall.copyWith(fontSize: 17),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _selectedBottomNav = 3),
                          child: Text(
                            'View All',
                            style: AppTextStyles.tagText.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ordersAsync.when(
                      data: (orders) => Column(
                        children: orders.take(3).map((order) {
                          return _buildOrderCard(order);
                        }).toList(),
                      ),
                      loading: () => _buildOrdersShimmer(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedBottomNav == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedBottomNav = index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard(LogisticsPackageModel pkg) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FarmerPackageDetailsScreen(package: pkg),
          ),
        );
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pkg.frequency,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.promoRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    pkg.discountBadge,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.promoRed,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              pkg.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pkg.formattedPrice,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(FarmerOrderModel order) {
    Color badgeBg;
    Color badgeFg;

    switch (order.status) {
      case 'IN_TRANSIT':
        badgeBg = AppColors.primaryLight;
        badgeFg = AppColors.primaryDark;
        break;
      case 'DELIVERED':
        badgeBg = const Color(0xFFE8F5E9);
        badgeFg = const Color(0xFF2E7D32);
        break;
      case 'PENDING':
      default:
        badgeBg = AppColors.accentLight.withValues(alpha: 0.5);
        badgeFg = AppColors.accentDark;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.bookingRef,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.status.replaceAll('_', ' '),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: badgeFg,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${order.produceType} • ${order.weightKg.toStringAsFixed(0)} kg',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            '${order.pickup} → ${order.destination}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesShimmer() {
    return SizedBox(
      height: 165,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          width: 260,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersShimmer() {
    return Column(
      children: List.generate(
        2,
        (_) => Container(
          height: 72,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTab() {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        title: const Text('Farmer Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedBottomNav = 0),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.fullName ?? 'Aiden Smith',
                style: AppTextStyles.headingMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                user?.phoneNumber ?? '+94 77 123 4567',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              AgrizelCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      icon: Icons.shield_rounded,
                      label: 'Account Status',
                      value: user?.status ?? 'ACTIVE',
                      color: AppColors.primary,
                      isBold: true,
                    ),
                    const Divider(color: AppColors.border, height: 20),
                    _buildSummaryRow(
                      icon: Icons.verified_user_rounded,
                      label: 'Role',
                      value: user?.role ?? 'FARMER',
                    ),
                  ],
                ),
              ),
              const Spacer(),

              AgrizelPillButton(
                text: 'Sign Out',
                icon: Icons.logout_rounded,
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).logout();
                  context.go(RouteNames.farmerLanding);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color ?? AppColors.textPrimary,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
