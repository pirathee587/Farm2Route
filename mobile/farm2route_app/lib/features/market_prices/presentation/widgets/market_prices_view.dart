import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

class MarketPricesView extends StatefulWidget {
  final Function(String cropName)? onBookCropFreight;

  const MarketPricesView({super.key, this.onBookCropFreight});

  @override
  State<MarketPricesView> createState() => _MarketPricesViewState();
}

class _MarketPricesViewState extends State<MarketPricesView> {
  // Selected Market
  int _selectedMarketIndex = 0;
  final List<Map<String, String>> _markets = [
    {
      'name': 'Dambulla DEC',
      'fullName': 'Dambulla Dedicated Economic Centre',
      'province': 'Central Province (National Hub)',
      'inflow': '580 MT',
      'priceMultiplier': '1.0',
    },
    {
      'name': 'Pettah Manning',
      'fullName': 'Pettah Manning Market (Colombo Terminal)',
      'province': 'Western Province',
      'inflow': '420 MT',
      'priceMultiplier': '1.18',
    },
    {
      'name': 'Nuwara Eliya',
      'fullName': 'Nuwara Eliya Economic Centre',
      'province': 'Upcountry Highland Hub',
      'inflow': '290 MT',
      'priceMultiplier': '0.92',
    },
    {
      'name': 'Meegoda DEC',
      'fullName': 'Meegoda Dedicated Economic Centre',
      'province': 'Western Province Hub',
      'inflow': '180 MT',
      'priceMultiplier': '1.12',
    },
    {
      'name': 'Keppetipola',
      'fullName': 'Keppetipola Economic Centre',
      'province': 'Uva Province Hub',
      'inflow': '210 MT',
      'priceMultiplier': '0.95',
    },
  ];

  // Selected Date
  DateTime _selectedDate = DateTime(2026, 9, 8);
  final List<String> _quickDateLabels = ['Today (8 Sep)', 'Yesterday (7 Sep)', '6 Sep', 'Calendar 📅'];
  int _selectedQuickDateIndex = 0;

  // Category Filter
  int _selectedCategoryIndex = 0;
  final List<String> _categories = [
    'All Produce',
    'Upcountry',
    'Lowcountry',
    'Spices & Tubers',
    'Top Gainers ↑',
    'Top Drops ↓',
  ];

  // Search query
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Master Vegetable Price Database (Base rates at Dambulla DEC)
  final List<Map<String, dynamic>> _masterVegetables = [
    {
      'name': 'Carrot',
      'sinhala': 'කැරට්',
      'category': 'Upcountry',
      'baseWholesale': 280,
      'baseRetail': 350,
      'minPrice': 260,
      'maxPrice': 300,
      'change': 15,
      'percentChange': '+5.6%',
      'inflowTons': 52,
      'icon': Icons.spa_rounded,
      'color': const Color(0xFFFF7043),
    },
    {
      'name': 'Leeks',
      'sinhala': 'ලීක්ස්',
      'category': 'Upcountry',
      'baseWholesale': 220,
      'baseRetail': 280,
      'minPrice': 200,
      'maxPrice': 240,
      'change': -10,
      'percentChange': '-4.3%',
      'inflowTons': 38,
      'icon': Icons.grass_rounded,
      'color': const Color(0xFF66BB6A),
    },
    {
      'name': 'Tomato',
      'sinhala': 'තක්කාලි',
      'category': 'Lowcountry',
      'baseWholesale': 190,
      'baseRetail': 250,
      'minPrice': 170,
      'maxPrice': 210,
      'change': -25,
      'percentChange': '-11.6%',
      'inflowTons': 78,
      'icon': Icons.circle_rounded,
      'color': const Color(0xFFE53935),
    },
    {
      'name': 'Green Chilli',
      'sinhala': 'අමු මිරිස්',
      'category': 'Lowcountry',
      'baseWholesale': 450,
      'baseRetail': 560,
      'minPrice': 420,
      'maxPrice': 490,
      'change': 40,
      'percentChange': '+9.7%',
      'inflowTons': 22,
      'icon': Icons.bolt_rounded,
      'color': const Color(0xFF43A047),
    },
    {
      'name': 'Cabbage',
      'sinhala': 'ගෝවා',
      'category': 'Upcountry',
      'baseWholesale': 160,
      'baseRetail': 210,
      'minPrice': 140,
      'maxPrice': 180,
      'change': -5,
      'percentChange': '-3.0%',
      'inflowTons': 64,
      'icon': Icons.energy_savings_leaf_rounded,
      'color': const Color(0xFF81C784),
    },
    {
      'name': 'Green Beans',
      'sinhala': 'බෝංචි',
      'category': 'Upcountry',
      'baseWholesale': 320,
      'baseRetail': 390,
      'minPrice': 300,
      'maxPrice': 350,
      'change': 25,
      'percentChange': '+8.4%',
      'inflowTons': 30,
      'icon': Icons.eco_rounded,
      'color': const Color(0xFF388E3C),
    },
    {
      'name': 'Beetroot',
      'sinhala': 'බීට්රූට්',
      'category': 'Upcountry',
      'baseWholesale': 240,
      'baseRetail': 300,
      'minPrice': 220,
      'maxPrice': 260,
      'change': 0,
      'percentChange': '0.0%',
      'inflowTons': 26,
      'icon': Icons.circle,
      'color': const Color(0xFF880E4F),
    },
    {
      'name': 'Brinjal (Eggplant)',
      'sinhala': 'වම්බටු',
      'category': 'Lowcountry',
      'baseWholesale': 180,
      'baseRetail': 240,
      'minPrice': 160,
      'maxPrice': 200,
      'change': 10,
      'percentChange': '+5.8%',
      'inflowTons': 35,
      'icon': Icons.egg_rounded,
      'color': const Color(0xFF6A1B9A),
    },
    {
      'name': 'Pumpkin',
      'sinhala': 'වට්ටක්කා',
      'category': 'Lowcountry',
      'baseWholesale': 110,
      'baseRetail': 160,
      'minPrice': 95,
      'maxPrice': 125,
      'change': -10,
      'percentChange': '-8.3%',
      'inflowTons': 92,
      'icon': Icons.album_rounded,
      'color': const Color(0xFFFB8C00),
    },
    {
      'name': 'Bitter Gourd',
      'sinhala': 'කරවිල',
      'category': 'Lowcountry',
      'baseWholesale': 260,
      'baseRetail': 330,
      'minPrice': 240,
      'maxPrice': 285,
      'change': 20,
      'percentChange': '+8.3%',
      'inflowTons': 16,
      'icon': Icons.texture_rounded,
      'color': const Color(0xFF2E7D32),
    },
    {
      'name': 'Red Onion (Jaffna)',
      'sinhala': 'රතු ළූණු',
      'category': 'Spices & Tubers',
      'baseWholesale': 380,
      'baseRetail': 450,
      'minPrice': 360,
      'maxPrice': 410,
      'change': -20,
      'percentChange': '-5.0%',
      'inflowTons': 44,
      'icon': Icons.grain_rounded,
      'color': const Color(0xFFC2185B),
    },
    {
      'name': 'Big Onion',
      'sinhala': 'ලොකු ළූණු',
      'category': 'Spices & Tubers',
      'baseWholesale': 210,
      'baseRetail': 260,
      'minPrice': 195,
      'maxPrice': 225,
      'change': 10,
      'percentChange': '+5.0%',
      'inflowTons': 95,
      'icon': Icons.donut_large_rounded,
      'color': const Color(0xFFD84315),
    },
    {
      'name': 'Potato (Nuwara Eliya)',
      'sinhala': 'අල',
      'category': 'Spices & Tubers',
      'baseWholesale': 310,
      'baseRetail': 370,
      'minPrice': 290,
      'maxPrice': 330,
      'change': 15,
      'percentChange': '+5.0%',
      'inflowTons': 58,
      'icon': Icons.cookie_rounded,
      'color': const Color(0xFFA1887F),
    },
    {
      'name': 'Lime',
      'sinhala': 'දෙහි',
      'category': 'Spices & Tubers',
      'baseWholesale': 600,
      'baseRetail': 760,
      'minPrice': 570,
      'maxPrice': 640,
      'change': 50,
      'percentChange': '+9.0%',
      'inflowTons': 14,
      'icon': Icons.brightness_high_rounded,
      'color': const Color(0xFFC0CA33),
    },
    {
      'name': 'Snake Gourd',
      'sinhala': 'පත් Nicole',
      'category': 'Lowcountry',
      'baseWholesale': 140,
      'baseRetail': 190,
      'minPrice': 125,
      'maxPrice': 155,
      'change': 0,
      'percentChange': '0.0%',
      'inflowTons': 22,
      'icon': Icons.timeline_rounded,
      'color': const Color(0xFF4CAF50),
    },
    {
      'name': 'Ladies Finger (Okra)',
      'sinhala': 'බණ්ඩක්කා',
      'category': 'Lowcountry',
      'baseWholesale': 150,
      'baseRetail': 200,
      'minPrice': 135,
      'maxPrice': 165,
      'change': 5,
      'percentChange': '+3.4%',
      'inflowTons': 28,
      'icon': Icons.flare_rounded,
      'color': const Color(0xFF689F38),
    },
    {
      'name': 'Ginger (Local)',
      'sinhala': 'ඉඟුරු',
      'category': 'Spices & Tubers',
      'baseWholesale': 1200,
      'baseRetail': 1480,
      'minPrice': 1150,
      'maxPrice': 1280,
      'change': -50,
      'percentChange': '-4.0%',
      'inflowTons': 9,
      'icon': Icons.spa,
      'color': const Color(0xFF8D6E63),
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Calculate adjusted price based on selected market and date
  Map<String, dynamic> _getAdjustedVegetable(Map<String, dynamic> item) {
    final multiplier = double.parse(_markets[_selectedMarketIndex]['priceMultiplier']!);

    // Date variation (simulated date offset)
    final dayDiff = DateTime(2026, 9, 8).difference(_selectedDate).inDays;
    final dateFactor = 1.0 - (dayDiff * 0.02);

    final wholesale = ((item['baseWholesale'] as int) * multiplier * dateFactor).round();
    final retail = ((item['baseRetail'] as int) * multiplier * dateFactor).round();
    final minP = ((item['minPrice'] as int) * multiplier * dateFactor).round();
    final maxP = ((item['maxPrice'] as int) * multiplier * dateFactor).round();
    final change = item['change'] as int;

    return {
      ...item,
      'adjustedWholesale': wholesale,
      'adjustedRetail': retail,
      'adjustedMin': minP,
      'adjustedMax': maxP,
      'displayChange': change,
    };
  }

  List<Map<String, dynamic>> _getFilteredVegetables() {
    final adjusted = _masterVegetables.map(_getAdjustedVegetable).toList();

    return adjusted.where((item) {
      // 1. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = (item['name'] as String).toLowerCase();
        final sinhala = (item['sinhala'] as String).toLowerCase();
        if (!name.contains(query) && !sinhala.contains(query)) {
          return false;
        }
      }

      // 2. Category Filter
      final cat = _categories[_selectedCategoryIndex];
      if (cat == 'All Produce') return true;
      if (cat == 'Upcountry') return item['category'] == 'Upcountry';
      if (cat == 'Lowcountry') return item['category'] == 'Lowcountry';
      if (cat == 'Spices & Tubers') return item['category'] == 'Spices & Tubers';
      if (cat == 'Top Gainers ↑') return (item['change'] as int) > 0;
      if (cat == 'Top Drops ↓') return (item['change'] as int) < 0;

      return true;
    }).toList();
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2026, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedQuickDateIndex = 3;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMarket = _markets[_selectedMarketIndex];
    final filteredVegetables = _getFilteredVegetables();
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Market & Date Header
            _buildMarketHeader(currentMarket, dateFormat),

            // 2. Market Selection Chips Carousel
            _buildMarketSelectorBar(),

            // 3. Date Selection & Market Status Ribbon
            _buildDateSelectorRibbon(dateFormat),

            // 4. Search and Category Filter Tabs
            _buildSearchAndFilters(),

            // 5. Commodity Cards List
            Expanded(
              child: filteredVegetables.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                      itemCount: filteredVegetables.length,
                      itemBuilder: (context, index) {
                        final veg = filteredVegetables[index];
                        return _buildVegetableCard(veg);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Top Title Bar
  Widget _buildMarketHeader(Map<String, String> currentMarket, DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storefront_rounded, color: AppColors.primaryDark, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Market Vegetable Rates',
                      style: AppTextStyles.headingMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Daily Central Bank & Dedicated Economic Centre Price Feed',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                SizedBox(width: 4),
                Text(
                  'Verified Rates',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Market Selection Horizontal Pills
  Widget _buildMarketSelectorBar() {
    return Container(
      color: Colors.white,
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _markets.length,
        itemBuilder: (context, index) {
          final market = _markets[index];
          final isSelected = _selectedMarketIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedMarketIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 8, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryDark : const Color(0xFFF3F5F3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: isSelected ? AppColors.primary : Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    market['name']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Date Selection Ribbon & Inflow Metric
  Widget _buildDateSelectorRibbon(DateFormat dateFormat) {
    final currentMarket = _markets[_selectedMarketIndex];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F6F2),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2EBE4), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Quick Date Filter Pills
          Row(
            children: [
              Expanded(
                child: Row(
                  children: List.generate(_quickDateLabels.length, (index) {
                    final isSelected = _selectedQuickDateIndex == index;
                    return GestureDetector(
                      onTap: () {
                        if (index == 0) {
                          setState(() {
                            _selectedDate = DateTime(2026, 9, 8);
                            _selectedQuickDateIndex = 0;
                          });
                        } else if (index == 1) {
                          setState(() {
                            _selectedDate = DateTime(2026, 9, 7);
                            _selectedQuickDateIndex = 1;
                          });
                        } else if (index == 2) {
                          setState(() {
                            _selectedDate = DateTime(2026, 9, 6);
                            _selectedQuickDateIndex = 2;
                          });
                        } else {
                          _pickCustomDate();
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 1.2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          _quickDateLabels[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected ? AppColors.primaryDark : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Market Summary Status Banner
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_available_rounded, size: 14, color: AppColors.primaryDark),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(_selectedDate),
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
                  const Icon(Icons.local_shipping_outlined, size: 14, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text(
                    'Daily Inflow: ${currentMarket['inflow']}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Search Bar and Category Tabs
  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Column(
        children: [
          // Search Input Field
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4ECE5)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search carrot, tomato, chilli, onion...',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.black45),
                prefixIcon: const Icon(Icons.search, size: 18, color: Colors.black54),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: Colors.black54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Category Chips Bar
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1B2E23) : const Color(0xFFF3F5F3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Individual Vegetable Commodity Card
  Widget _buildVegetableCard(Map<String, dynamic> veg) {
    final wholesale = veg['adjustedWholesale'] as int;
    final retail = veg['adjustedRetail'] as int;
    final minP = veg['adjustedMin'] as int;
    final maxP = veg['adjustedMax'] as int;
    final change = veg['displayChange'] as int;
    final isGainer = change > 0;
    final isDrop = change < 0;
    final vegColor = veg['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
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
        children: [
          // Row 1: Crop Identity & Price
          Row(
            children: [
              // Icon Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: vegColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: vegColor.withValues(alpha: 0.3)),
                ),
                child: Icon(veg['icon'] as IconData, color: vegColor, size: 24),
              ),
              const SizedBox(width: 12),

              // Vegetable Name and Sinhala Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          veg['name'] as String,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            veg['sinhala'] as String,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${veg['category']} • Daily: ${veg['inflowTons']} MT',
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Wholesale Rate & Trend Indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Rs. ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        TextSpan(
                          text: '$wholesale',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const TextSpan(
                          text: ' /kg',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Trend Ribbon (+/-)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isGainer
                          ? const Color(0xFFFFEBEE)
                          : isDrop
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isGainer
                              ? Icons.arrow_upward_rounded
                              : isDrop
                                  ? Icons.arrow_downward_rounded
                                  : Icons.remove_rounded,
                          size: 11,
                          color: isGainer
                              ? const Color(0xFFC62828)
                              : isDrop
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          isGainer
                              ? '+Rs. $change (${veg['percentChange']})'
                              : isDrop
                                  ? '-Rs. ${change.abs()} (${veg['percentChange']})'
                                  : 'Stable',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isGainer
                                ? const Color(0xFFC62828)
                                : isDrop
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Row 2: Modal Price Range & Retail Price
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBF8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEDF3ED)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Auction Range: Rs. $minP - $maxP /kg',
                  style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Retail Est: Rs. $retail /kg',
                  style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Row 3: Action Buttons (Book Freight shortcut)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () {
                  if (widget.onBookCropFreight != null) {
                    widget.onBookCropFreight!(veg['name'] as String);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Selected ${veg['name']} for Freight Booking at ${_markets[_selectedMarketIndex]['name']}!'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 14, color: AppColors.primaryDark),
                      const SizedBox(width: 4),
                      Text(
                        'Dispatch ${veg['name']}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: Colors.black26),
          const SizedBox(height: 12),
          Text(
            'No vegetables matching "$_searchQuery"',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try searching for carrot, leeks, cabbage, tomato, or chilli',
            style: TextStyle(fontSize: 12, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}
