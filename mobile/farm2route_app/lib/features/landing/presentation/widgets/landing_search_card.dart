import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_pill_button.dart';
import '../providers/landing_providers.dart';

class LandingSearchCard extends ConsumerStatefulWidget {
  const LandingSearchCard({super.key});

  @override
  ConsumerState<LandingSearchCard> createState() => _LandingSearchCardState();
}

class _LandingSearchCardState extends ConsumerState<LandingSearchCard> {
  final _searchController = TextEditingController();
  final _pickupController = TextEditingController();
  final _weightController = TextEditingController();

  String? _selectedMarket;
  String? _selectedProduce;

  static const List<String> _markets = [
    'Manning Wholesale Market, Colombo',
    'Dambulla Dedicated Economic Centre',
    'Peliyagoda Central Fish & Veg Market',
    'Kandy Central Market',
    'Thotalanga Agricultural Terminal',
    'Colombo Wholesale Market',
    'Galle General Market',
    'Jaffna City Market',
  ];

  static const List<String> _produceTypes = [
    'Fresh Vegetables',
    'Paddy / Rice',
    'Fruits',
    'Spices & Tubers',
    'Grains & Legumes',
    'Tea & Coconut',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _pickupController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onFindTransport() {
    final weight = double.tryParse(_weightController.text.trim());
    ref.read(searchCriteriaProvider.notifier).setCriteria(
          pickupLocation: _pickupController.text.trim(),
          deliveryMarket: _selectedMarket ?? '',
          cargoWeightKg: weight,
          produceType: _selectedProduce ?? '',
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Filtering transport for ${_selectedMarket ?? "All Markets"} (${_weightController.text.isNotEmpty ? "${_weightController.text} KG" : "Any Weight"})',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchCriteriaProvider);
    final locationState = ref.watch(landingLocationProvider);

    if (_pickupController.text.isEmpty) {
      _pickupController.text = locationState.district;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          color: searchState.isExpanded ? Colors.white : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(searchState.isExpanded ? 24 : 32),
          border: Border.all(
            color: searchState.isExpanded ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: searchState.isExpanded
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Collapsed Pill or Header Search Bar
            InkWell(
              key: const Key('landing_search_bar_trigger'),
              onTap: () {
                ref.read(searchCriteriaProvider.notifier).toggleExpanded();
              },
              borderRadius: BorderRadius.circular(32),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        searchState.hasActiveFilters
                            ? 'Filters Applied • Tap to modify'
                            : 'Search transport, agency, or market',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: searchState.hasActiveFilters
                              ? AppColors.primaryDark
                              : AppColors.textSecondary,
                          fontWeight: searchState.hasActiveFilters
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (searchState.hasActiveFilters)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _pickupController.clear();
                          _weightController.clear();
                          setState(() {
                            _selectedMarket = null;
                            _selectedProduce = null;
                          });
                          ref.read(searchCriteriaProvider.notifier).reset();
                        },
                      )
                    else
                      Icon(
                        searchState.isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.tune_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),

            // Expanded Form Fields
            if (searchState.isExpanded) ...[
              const Divider(height: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Pickup Location
                    TextFormField(
                      key: const Key('search_pickup_field'),
                      controller: _pickupController,
                      decoration: InputDecoration(
                        labelText: '📍 Pickup Location',
                        hintText: 'Use Current Location or enter district',
                        filled: true,
                        fillColor: AppColors.surfaceSubtle,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                          onPressed: () {
                            _pickupController.text = locationState.district;
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Delivery Market
                    DropdownButtonFormField<String>(
                      key: const Key('search_market_dropdown'),
                      initialValue: _selectedMarket,
                      decoration: InputDecoration(
                        labelText: '🏪 Delivery Market',
                        hintText: 'Select Market',
                        filled: true,
                        fillColor: AppColors.surfaceSubtle,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _markets.map((market) {
                        return DropdownMenuItem<String>(
                          value: market,
                          child: Text(
                            market,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedMarket = val),
                    ),
                    const SizedBox(height: 12),

                    // Row: Weight + Produce Type
                    Row(
                      children: [
                        // 3. Cargo Weight (KG)
                        Expanded(
                          child: TextFormField(
                            key: const Key('search_weight_field'),
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '⚖️ Weight (KG)',
                              hintText: 'e.g. 3000',
                              filled: true,
                              fillColor: AppColors.surfaceSubtle,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // 4. Produce Type
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: const Key('search_produce_dropdown'),
                            initialValue: _selectedProduce,
                            decoration: InputDecoration(
                              labelText: '🌾 Produce Type',
                              hintText: 'Select',
                              filled: true,
                              fillColor: AppColors.surfaceSubtle,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: _produceTypes.map((type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Text(
                                  type,
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedProduce = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Button: 🚛 Find Transport
                    AgrizelPillButton(
                      key: const Key('search_find_transport_button'),
                      text: 'Find Transport',
                      icon: Icons.local_shipping_rounded,
                      onPressed: _onFindTransport,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
