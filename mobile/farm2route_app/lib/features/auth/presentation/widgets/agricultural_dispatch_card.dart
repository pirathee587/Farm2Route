import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

class AgriculturalDispatchCard extends StatefulWidget {
  const AgriculturalDispatchCard({super.key});

  @override
  State<AgriculturalDispatchCard> createState() => _AgriculturalDispatchCardState();
}

class _AgriculturalDispatchCardState extends State<AgriculturalDispatchCard> {
  String _pickupLocation = 'Central Agro Hub, Dambulla';
  String _deliveryLocation = 'Manning Wholesale Market, Colombo';
  DateTime _selectedDate = DateTime.now();
  int _weightKg = 1500;
  String _commodityType = 'Vegetables (Fresh Harvest)';
  String _commodityIcon = '🥬';
  bool _requiresColdChain = false;

  // Preset locations for quick selection
  static const List<Map<String, String>> _popularOrigins = [
    {'title': 'Central Agro Hub, Dambulla', 'desc': 'Primary Wholesale Collection Terminal'},
    {'title': 'Nuwara Eliya Cold Logistics Center', 'desc': 'Highland Vegetable Consolidation Hub'},
    {'title': 'Jaffna Regional Agro Terminal', 'desc': 'Northern Produce & Onion Center'},
    {'title': 'Kurunegala Paddy & Coconut Depot', 'desc': 'North Western Grain Storage'},
    {'title': 'Bandarawela Vegetable Dispatch', 'desc': 'Upcountry Vegetable Market'},
    {'title': 'Embilipitiya Banana & Fruit Yard', 'desc': 'Southern Fruit Collection Center'},
  ];

  static const List<Map<String, String>> _popularDestinations = [
    {'title': 'Manning Wholesale Market, Colombo', 'desc': 'Peliyagoda Mega Wholesale Facility'},
    {'title': 'Kandy Central Distribution Yard', 'desc': 'Central Province Wholesale Hub'},
    {'title': 'Negombo Agro & Seafood Exchange', 'desc': 'Western Coastal Distribution'},
    {'title': 'Galle Port Commercial Depot', 'desc': 'Southern Province Bulk Center'},
    {'title': 'Jaffna Town Market, Hospital Road', 'desc': 'Northern Retail/Wholesale Exchange'},
    {'title': 'Katunayake Air Cargo Cold Terminal', 'desc': 'Export Perishable Terminal'},
  ];

  static const List<Map<String, dynamic>> _commodityOptions = [
    {
      'name': 'Vegetables (Fresh Harvest)',
      'icon': '🥬',
      'desc': 'Tomatoes, Cabbage, Carrots, Beans, Leeks',
      'coldChain': false,
    },
    {
      'name': 'Leafy & Perishable Greens',
      'icon': '🥦',
      'desc': 'Gotukola, Mukunuwenna, Spinach, Herbs',
      'coldChain': true,
    },
    {
      'name': 'Fresh Fruits & Melons',
      'icon': '🍎',
      'desc': 'Bananas, Papaya, Mangoes, Watermelon',
      'coldChain': false,
    },
    {
      'name': 'Grains, Paddy & Pulses',
      'icon': '🌾',
      'desc': 'Samba, Keeri Samba, Corn, Mung Beans',
      'coldChain': false,
    },
    {
      'name': 'Roots, Potatoes & Onions',
      'icon': '🥔',
      'desc': 'Jaffna Red Onions, Nuwara Eliya Potatoes',
      'coldChain': false,
    },
    {
      'name': 'Cold Chain Perishables',
      'icon': '❄️',
      'desc': 'Dairy, Mushrooms, Pre-cut Produce (Reefer)',
      'coldChain': true,
    },
  ];

  // Calculated estimates based on active choices
  int get _estimatedDistanceKm {
    if (_pickupLocation.contains('Dambulla') && _deliveryLocation.contains('Colombo')) {
      return 148;
    } else if (_pickupLocation.contains('Nuwara Eliya') && _deliveryLocation.contains('Colombo')) {
      return 165;
    } else if (_pickupLocation.contains('Jaffna') && _deliveryLocation.contains('Colombo')) {
      return 395;
    } else if (_pickupLocation.contains('Kurunegala') && _deliveryLocation.contains('Colombo')) {
      return 94;
    } else if (_pickupLocation.contains('Dambulla') && _deliveryLocation.contains('Kandy')) {
      return 72;
    }
    return 130;
  }

  String get _estimatedDuration {
    final dist = _estimatedDistanceKm;
    final hours = (dist / 42).floor();
    final mins = (((dist / 42) - hours) * 60).round();
    return '${hours}h ${mins}m';
  }

  int get _estimatedCost {
    final dist = _estimatedDistanceKm;
    // Base rate + distance rate + weight multiplier + optional cold chain markup
    double base = 6000;
    double distCost = dist * 85.0;
    double weightFactor = (_weightKg / 1000.0) * 1800.0;
    double coldChainMarkup = _requiresColdChain ? 4500 : 0;
    return (base + distCost + weightFactor + coldChainMarkup).round();
  }

  int get _availableTrucksCount {
    if (_pickupLocation.contains('Dambulla')) return 24;
    if (_pickupLocation.contains('Nuwara Eliya')) return 16;
    if (_pickupLocation.contains('Jaffna')) return 9;
    return 18;
  }

  void _swapLocations() {
    setState(() {
      final temp = _pickupLocation;
      _pickupLocation = _deliveryLocation;
      _deliveryLocation = temp;
    });
  }

  // --- Bottom Sheets & Modals ---

  void _openLocationPicker({required bool isPickup}) {
    final list = isPickup ? _popularOrigins : _popularDestinations;
    final title = isPickup ? 'Select Pickup Location' : 'Select Delivery Destination';
    final subtitle = isPickup ? 'Choose origin farm, packing hub or consolidation center' : 'Choose target wholesale market or storage facility';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isPickup ? AppColors.primary : AppColors.promoRed).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPickup ? Icons.trip_origin_rounded : Icons.location_on_rounded,
                        color: isPickup ? AppColors.primary : AppColors.promoRed,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.headingSmall.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final isSelected = isPickup ? _pickupLocation == item['title'] : _deliveryLocation == item['title'];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryContainer : const Color(0xFFF6F6F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.warehouse_rounded,
                          color: isSelected ? AppColors.primaryDark : Colors.black54,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        item['title']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? AppColors.primaryDark : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        item['desc']!,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22)
                          : const Icon(Icons.chevron_right_rounded, color: Colors.black26),
                      onTap: () {
                        setState(() {
                          if (isPickup) {
                            _pickupLocation = item['title']!;
                          } else {
                            _deliveryLocation = item['title']!;
                          }
                        });
                        Navigator.pop(ctx);
                      },
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

  void _openDatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final now = DateTime.now();
        final tomorrow = now.add(const Duration(days: 1));
        final dayAfter = now.add(const Duration(days: 2));

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Schedule Dispatch Date', style: AppTextStyles.headingSmall.copyWith(fontSize: 18)),
                      Text('Choose when trucks should arrive at pickup', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDateQuickOption(
                title: 'Today (Immediate Haul)',
                date: now,
                badge: '⚡ Instant Dispatch',
                badgeColor: AppColors.primary,
                ctx: ctx,
              ),
              const SizedBox(height: 10),
              _buildDateQuickOption(
                title: 'Tomorrow Morning',
                date: tomorrow,
                badge: '🌿 Dawn Harvest',
                badgeColor: AppColors.accent,
                ctx: ctx,
              ),
              const SizedBox(height: 10),
              _buildDateQuickOption(
                title: DateFormat('EEEE, d MMMM').format(dayAfter),
                date: dayAfter,
                badge: '📅 Advance Booking',
                badgeColor: Colors.blueGrey,
                ctx: ctx,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: AppColors.border),
                ),
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: const Text('Pick Specific Calendar Date', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateQuickOption({
    required String title,
    required DateTime date,
    required String badge,
    required Color badgeColor,
    required BuildContext ctx,
  }) {
    final isSelected = DateUtils.isSameDay(_selectedDate, date);
    return InkWell(
      onTap: () {
        setState(() => _selectedDate = date);
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFEEEEEE),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primaryDark : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(date),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCommodityPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Commodity / Vegetable', style: AppTextStyles.headingSmall.copyWith(fontSize: 18)),
                          Text('Tailors vehicle insulation & ventilation requirements', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _commodityOptions.length,
                  itemBuilder: (context, index) {
                    final item = _commodityOptions[index];
                    final isSelected = _commodityType == item['name'];
                    final bool isColdChain = item['coldChain'] as bool;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryLight : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : const Color(0xFFEEEEEE),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F6F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              item['icon'] as String,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                item['name'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.primaryDark : Colors.black87,
                                ),
                              ),
                            ),
                            if (isColdChain) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Cold Chain',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          item['desc'] as String,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22)
                            : null,
                        onTap: () {
                          setState(() {
                            _commodityType = item['name'] as String;
                            _commodityIcon = item['icon'] as String;
                            _requiresColdChain = isColdChain;
                          });
                          Navigator.pop(ctx);
                        },
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

  void _openWeightPicker() {
    int tempWeight = _weightKg;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final tons = (tempWeight / 1000.0).toStringAsFixed(1);
            return Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.scale_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Specify Cargo Weight', style: AppTextStyles.headingSmall.copyWith(fontSize: 18)),
                          Text('Ensures optimal lorry axle & weight capacity', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Big Weight Display with Stepper
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton.filled(
                          onPressed: tempWeight > 200
                              ? () => setModalState(() => tempWeight -= 100)
                              : null,
                          icon: const Icon(Icons.remove_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 1,
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '$tempWeight kg',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              '≈ $tons Metric Tons',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        IconButton.filled(
                          onPressed: tempWeight < 20000
                              ? () => setModalState(() => tempWeight += 100)
                              : null,
                          icon: const Icon(Icons.add_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  const Text('Quick Weight Presets:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),

                  // Quick preset pills
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [500, 1000, 1500, 2500, 3500, 5000, 8000].map((preset) {
                      final isSelected = tempWeight == preset;
                      final label = preset < 1000 ? '$preset kg' : '${(preset / 1000).toStringAsFixed(1)} Tons';
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: AppColors.primaryContainer,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primaryDark : Colors.black87,
                        ),
                        backgroundColor: const Color(0xFFF3F3F3),
                        onSelected: (val) {
                          if (val) setModalState(() => tempWeight = preset);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _weightKg = tempWeight);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: const Text('Confirm Weight', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMatchedHaulersPreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.local_shipping_rounded, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Text('Matched Freight Haulers', style: AppTextStyles.headingSmall.copyWith(fontSize: 18)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_availableTrucksCount Available',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Route: ${_pickupLocation.split(',').first} → ${_deliveryLocation.split(',').first}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    Text(
                      '$_estimatedDistanceKm km • $_weightKg kg • $_commodityType',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHaulerCard(
                      company: 'Central Dambulla Agro Haul',
                      vehicle: 'Isuzu Elf 3.5 Ton (Insulated Tarp)',
                      rating: '4.9 ★ (128 trips)',
                      eta: 'Arrives pickup in 25 min',
                      rate: 'LKR ${NumberFormat('#,###').format(_estimatedCost)}',
                      isFastest: true,
                    ),
                    const SizedBox(height: 12),
                    _buildHaulerCard(
                      company: 'Highland Reefer Cold Fleet',
                      vehicle: 'Cold Chain Refrigerated Van (+4°C to 12°C)',
                      rating: '4.8 ★ (94 trips)',
                      eta: 'Arrives pickup in 45 min',
                      rate: 'LKR ${NumberFormat('#,###').format(_estimatedCost + 3500)}',
                      isColdChainCertified: true,
                    ),
                    const SizedBox(height: 12),
                    _buildHaulerCard(
                      company: 'Lanka Agro Logistics Cooperative',
                      vehicle: 'Tata LPT 709 5-Ton Standard Lorry',
                      rating: '4.7 ★ (312 trips)',
                      eta: 'Scheduled for ${DateFormat('MMM d, h:mm a').format(_selectedDate.add(const Duration(hours: 2)))}',
                      rate: 'LKR ${NumberFormat('#,###').format((_estimatedCost * 0.94).round())}',
                      isBestValue: true,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push(RouteNames.login);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: const Text('Sign In to Confirm Dispatch & Book', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHaulerCard({
    required String company,
    required String vehicle,
    required String rating,
    required String eta,
    required String rate,
    bool isFastest = false,
    bool isBestValue = false,
    bool isColdChainCertified = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(company, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Text(
                rate,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(vehicle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(rating, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: Colors.black26)),
              const SizedBox(width: 8),
              Text(eta, style: const TextStyle(fontSize: 11, color: Colors.black87)),
            ],
          ),
          if (isFastest || isBestValue || isColdChainCertified) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isFastest
                    ? AppColors.primaryLight
                    : (isColdChainCertified ? const Color(0xFFE1F5FE) : const Color(0xFFFFF3E0)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isFastest
                    ? '⚡ Fastest Dispatch'
                    : (isColdChainCertified ? '❄️ Certified Reefer Quality' : '🏷️ Best Price Match'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isFastest
                      ? AppColors.primaryDark
                      : (isColdChainCertified ? Colors.blue.shade900 : Colors.orange.shade900),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Main Build ---

  @override
  Widget build(BuildContext context) {
    final dateDisplay = DateUtils.isSameDay(_selectedDate, DateTime.now())
        ? 'Today (${DateFormat('MMM d').format(_selectedDate)})'
        : (DateUtils.isSameDay(_selectedDate, DateTime.now().add(const Duration(days: 1)))
            ? 'Tomorrow (${DateFormat('MMM d').format(_selectedDate)})'
            : DateFormat('EEE, MMM d').format(_selectedDate));

    final weightDisplay = _weightKg < 1000
        ? '$_weightKg kg'
        : '${(_weightKg / 1000).toStringAsFixed(1)} Tons';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 20,
            spreadRadius: 0,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Premium Badge Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAF9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Agricultural Freight & Route Dispatch',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flash_on_rounded, size: 12, color: AppColors.primaryDark),
                      const SizedBox(width: 2),
                      Text(
                        '$_availableTrucksCount Trucks',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Interactive Route Path (Pickup & Delivery with Swap)
                Stack(
                  children: [
                    Column(
                      children: [
                        // Pickup Location Field
                        InkWell(
                          onTap: () => _openLocationPicker(isPickup: true),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFEBEBEB)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD1F2E0),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.trip_origin_rounded, color: AppColors.primary, size: 16),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'PICKUP LOCATION',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black45,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _pickupLocation,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 32), // clearance for swap button
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.black38),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Delivery Location Field
                        InkWell(
                          onTap: () => _openLocationPicker(isPickup: false),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFEBEBEB)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFEBEE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.location_on_rounded, color: AppColors.promoRed, size: 16),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'DELIVERY DESTINATION',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black45,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _deliveryLocation,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 32), // clearance for swap button
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.black38),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Floating Swap Button
                    Positioned(
                      right: 14,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _swapLocations,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x12000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.swap_vert_rounded,
                              size: 18,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 3. Trip Parameters (Date, Weight)
                Row(
                  children: [
                    // Date Tile
                    Expanded(
                      flex: 4,
                      child: _buildParameterTile(
                        icon: Icons.calendar_month_rounded,
                        iconColor: AppColors.primary,
                        label: 'DISPATCH DATE',
                        value: dateDisplay,
                        onTap: _openDatePicker,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Weight Tile
                    Expanded(
                      flex: 3,
                      child: _buildParameterTile(
                        icon: Icons.scale_rounded,
                        iconColor: Colors.deepOrange,
                        label: 'CARGO WEIGHT',
                        value: weightDisplay,
                        onTap: _openWeightPicker,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Vegetable / Commodity Tile (Full Width for clear produce visibility)
                InkWell(
                  onTap: _openCommodityPicker,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEBEBEB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: Center(
                            child: Text(_commodityIcon, style: const TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'VEGETABLE / PRODUCE TYPE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black45,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _commodityType,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (_requiresColdChain) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE1F5FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.ac_unit_rounded, size: 10, color: Colors.blue),
                                SizedBox(width: 2),
                                Text(
                                  'Cold Reefer',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.black38),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 4. Live Route Intelligence Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8F4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.route_rounded, size: 15, color: AppColors.primaryDark),
                          const SizedBox(width: 5),
                          Text(
                            '$_estimatedDistanceKm km • ~$_estimatedDuration',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            'Est. Fare: ',
                            style: TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                          Text(
                            'LKR ${NumberFormat('#,###').format(_estimatedCost)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 5. Senior UI/UX Call to Action Button
                ElevatedButton(
                  onPressed: _showMatchedHaulersPreview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Find Available Haulers & Rates',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEBEBEB)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.black45,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
