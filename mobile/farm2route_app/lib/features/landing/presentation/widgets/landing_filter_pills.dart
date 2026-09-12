import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../providers/landing_providers.dart';

class LandingFilterPills extends ConsumerWidget {
  const LandingFilterPills({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(filterPillsProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 1. [ 🏷️ Offers ]
          _buildFilterPill(
            key: const Key('filter_pill_offers'),
            label: '🏷️ Offers',
            isActive: filters.offersOnly,
            onTap: () => ref.read(filterPillsProvider.notifier).toggleOffers(),
          ),
          const SizedBox(width: 8),

          // 2. [ 💰 Price ▼ ]
          _buildFilterPill(
            key: const Key('filter_pill_price'),
            label: '💰 Price ▼',
            isActive: filters.sortOption == SortOption.priceLowToHigh,
            onTap: () => ref.read(filterPillsProvider.notifier).togglePriceSort(),
          ),
          const SizedBox(width: 8),

          // 3. [ ⭐ Rating ]
          _buildFilterPill(
            key: const Key('filter_pill_rating'),
            label: '⭐ Rating',
            isActive: filters.sortOption == SortOption.ratingHighToLow,
            onTap: () => ref.read(filterPillsProvider.notifier).toggleRatingSort(),
          ),
          const SizedBox(width: 8),

          // 4. [ 📏 Nearest ]
          _buildFilterPill(
            key: const Key('filter_pill_nearest'),
            label: '📏 Nearest',
            isActive: filters.sortOption == SortOption.nearestDistance,
            onTap: () => ref.read(filterPillsProvider.notifier).toggleNearestSort(),
          ),

          if (filters.offersOnly || filters.sortOption != SortOption.none) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => ref.read(filterPillsProvider.notifier).reset(),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  'Clear',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required Key key,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.textPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.textPrimary : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
