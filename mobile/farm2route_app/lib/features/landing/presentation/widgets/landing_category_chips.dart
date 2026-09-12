import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../providers/landing_providers.dart';

class LandingCategoryChips extends ConsumerWidget {
  const LandingCategoryChips({super.key});

  static const List<Map<String, dynamic>> categories = [
    {'name': 'All', 'icon': '🚛'},
    {'name': 'Express Haul', 'icon': '⚡'},
    {'name': 'Harvest Transport', 'icon': '🌾'},
    {'name': 'Bulk Cargo', 'icon': '🚚'},
    {'name': 'Refrigerated', 'icon': '❄️'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = categories[index];
          final name = item['name'] as String;
          final icon = item['icon'] as String;
          final isSelected = selectedCategory.toLowerCase() == name.toLowerCase();

          return InkWell(
            key: Key('category_chip_$name'),
            onTap: () {
              ref.read(selectedCategoryProvider.notifier).state = name;
            },
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight : AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    name,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
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
}
