import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../providers/landing_providers.dart';

class DistrictSelectorSheet extends ConsumerWidget {
  const DistrictSelectorSheet({super.key});

  static const List<String> availableDistricts = [
    'Jaffna',
    'Kilinochchi',
    'Vavuniya',
    'Dambulla',
    'Kandy',
    'Colombo',
    'Anuradhapura',
    'Kurunegala',
  ];

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const DistrictSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(landingLocationProvider);

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          const SizedBox(height: 16),

          Text(
            'Select Transport Pickup Hub',
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose your agricultural region to see live available trucks near you',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // Use GPS Auto-Detect Button
          InkWell(
            onTap: () async {
              await ref.read(landingLocationProvider.notifier).detectGpsLocation();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location_rounded, color: AppColors.primaryDark, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Use Current Device GPS',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          'Auto-detect nearest logistics zone',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryDark.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (locationState.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                    )
                  else
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryDark),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Divider(color: AppColors.divider),
          const SizedBox(height: 8),

          // District List
          Expanded(
            child: ListView.separated(
              itemCount: availableDistricts.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (context, index) {
                final district = availableDistricts[index];
                final isSelected = locationState.district.toLowerCase() == district.toLowerCase();

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryContainer : AppColors.surfaceSubtle,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 18,
                      color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                    ),
                  ),
                  title: Text(
                    '$district, Sri Lanka',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                      : null,
                  onTap: () {
                    ref.read(landingLocationProvider.notifier).setDistrict(district);
                    Navigator.of(context).pop();
                  },
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
