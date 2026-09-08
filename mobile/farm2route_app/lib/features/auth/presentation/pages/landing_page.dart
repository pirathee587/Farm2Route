import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../widgets/agricultural_dispatch_card.dart';
import 'package:farm2route_app/features/tracking/presentation/widgets/live_truck_map_view.dart';
import 'package:farm2route_app/features/market_prices/presentation/widgets/market_prices_view.dart';
import 'package:farm2route_app/features/orders/presentation/widgets/orders_tab_view.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  int _selectedTopService = 0;
  int _selectedBottomNav = 0;

  late AnimationController _animController;
  late Animation<double> _fadeHeader;
  late Animation<Offset> _slideHeader;
  late Animation<double> _fadeContent;
  late Animation<Offset> _slideContent;

  final List<Map<String, dynamic>> _topServices = [
    {'name': 'All', 'icon': Icons.local_mall_rounded, 'color': AppColors.primary},
    {'name': 'Express Haul', 'icon': Icons.directions_car_filled_rounded, 'color': Colors.black87},
    {'name': 'Harvests', 'icon': Icons.eco_rounded, 'color': Colors.orange},
    {'name': 'Bulk Freight', 'icon': Icons.local_shipping_rounded, 'color': Colors.redAccent},
  ];

  final List<Map<String, dynamic>> _featuredLogistics = [
    {
      'title': 'MKC Freight Center',
      'discount': '20% off LKR 1,000+',
      'fee': 'LKR 99 Delivery Fee',
      'badge': 'Best Overall • 28 min',
      'imageColor': const Color(0xFFE8F5E9),
      'icon': Icons.local_shipping_rounded,
    },
    {
      'title': 'Chopsticks Transport',
      'discount': 'LKR 150 off trips',
      'fee': 'LKR 99 Delivery Fee',
      'badge': 'Best Overall • 39 min',
      'imageColor': const Color(0xFFFFF3E0),
      'icon': Icons.fire_truck_rounded,
    },
    {
      'title': 'Central Agro Haulers',
      'discount': '15% off Bulk Grains',
      'fee': 'Free Delivery over 5 Tons',
      'badge': 'Top Rated • 15 min',
      'imageColor': const Color(0xFFE3F2FD),
      'icon': Icons.airport_shuttle_rounded,
    },
    {
      'title': 'Highland Cold Express',
      'discount': 'Special Temperature Control',
      'fee': 'LKR 120 Delivery Fee',
      'badge': 'Verified • 45 min',
      'imageColor': const Color(0xFFF1F8E9),
      'icon': Icons.ac_unit_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeHeader = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideHeader = Tween<Offset>(
      begin: const Offset(0.0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _fadeContent = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );

    _slideContent = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Active Tab View with State Preservation
            Expanded(
              child: IndexedStack(
                index: _selectedBottomNav,
                children: [
                  // Tab 0: Home Page
                  _buildHomeTab(),

                  // Tab 1: Live Truck / Lorry Tracking Map View
                  const LiveTruckMapView(),

                  // Tab 2: Vegetable Market Prices View (based on Market and Date)
                  MarketPricesView(
                    onBookCropFreight: (cropName) {
                      setState(() => _selectedBottomNav = 0);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Selected $cropName for Express Haul dispatch!'),
                          backgroundColor: AppColors.primaryDark,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),

                  // Tab 3: Orders Tab View
                  OrdersTabView(
                    onSwitchToMap: () {
                      setState(() => _selectedBottomNav = 1);
                    },
                  ),
                ],
              ),
            ),

            // Docked Bottom Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomNavItem(Icons.home_filled, 'Home', 0),
                  _buildBottomNavItem(Icons.map_rounded, 'Map', 1),
                  _buildBottomNavItem(Icons.price_change_rounded, 'Prices', 2),
                  _buildBottomNavItem(Icons.receipt_long_rounded, 'Orders', 3),
                  _buildBottomNavItem(Icons.person_outline_rounded, 'Account', 4, onTap: () {
                    context.push(RouteNames.login);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Location Bar with Slide Down Animation
          SlideTransition(
            position: _slideHeader,
            child: FadeTransition(
              opacity: _fadeHeader,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {},
                      child: Row(
                        children: [
                          Text(
                            'Central Agro Hub, Dambulla',
                            style: AppTextStyles.headingSmall.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, size: 24),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Staggered Body Content
          SlideTransition(
            position: _slideContent,
            child: FadeTransition(
              opacity: _fadeContent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Horizontal Primary Service Filter Pills
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _topServices.length,
                      itemBuilder: (context, index) {
                        final item = _topServices[index];
                        final isSelected = _selectedTopService == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTopService = index),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE8F8F0) : const Color(0xFFF3F3F3),
                              borderRadius: BorderRadius.circular(24),
                              border: isSelected ? Border.all(color: AppColors.primary, width: 1.5) : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item['icon'] as IconData,
                                  size: 18,
                                  color: isSelected ? AppColors.primary : Colors.black87,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item['name'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: isSelected ? AppColors.primaryDark : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 3. Senior UI/UX Agricultural Freight & Route Dispatcher Card
                  const AgriculturalDispatchCard(),

                  const SizedBox(height: 12),

                  // 4. "Featured on Farm2Route" Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Featured on Farm2Route',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3F3F3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, size: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 5. Grid of Featured Logistics Cards
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.76,
                    ),
                    itemCount: _featuredLogistics.length,
                    itemBuilder: (context, index) {
                      final item = _featuredLogistics[index];
                      return GestureDetector(
                        onTap: () => context.push(RouteNames.login),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: item['imageColor'] as Color,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      item['icon'] as IconData,
                                      size: 48,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.promoRed,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item['discount'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['title'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['fee'] as String,
                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['badge'] as String,
                              style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index, {VoidCallback? onTap}) {
    final isSelected = _selectedBottomNav == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap ?? () => setState(() => _selectedBottomNav = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? AppColors.primaryDark : Colors.black45,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected ? AppColors.primaryDark : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
