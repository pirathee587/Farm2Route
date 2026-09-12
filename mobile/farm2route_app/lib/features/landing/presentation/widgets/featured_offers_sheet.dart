import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/featured_promo_model.dart';
import '../providers/landing_providers.dart';

/// Modal bottom sheet displaying all featured harvest deals, promo codes, and vouchers
class FeaturedOffersSheet extends ConsumerWidget {
  const FeaturedOffersSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const FeaturedOffersSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(featuredPromosProvider);

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.5)),
                  ),
                  child: const Icon(
                    Icons.local_offer_rounded,
                    color: Color(0xFFE65100),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔥 Featured Deals & Offers',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Active transport vouchers & seasonal discounts',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('close_featured_offers_sheet'),
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),

            // Offers List
            Expanded(
              child: promosAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: Text('Failed to load offers: $e'),
                ),
                data: (promos) {
                  if (promos.isEmpty) {
                    return const Center(child: Text('No featured offers available right now'));
                  }

                  return ListView.separated(
                    itemCount: promos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final promo = promos[index];
                      return _buildOfferCard(context, ref, promo);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Filter All Offers Button
            ElevatedButton.icon(
              key: const Key('view_all_discounted_trips_button'),
              onPressed: () {
                ref.read(filterPillsProvider.notifier).setOffersOnly(true);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Filtered packages: Showing active discounted trips only'),
                    backgroundColor: AppColors.primaryDark,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.local_fire_department_rounded, size: 18),
              label: const Text('Show All Discounted Trips in Feed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, WidgetRef ref, FeaturedPromoModel promo) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: promo.bannerColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Banner Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: promo.bannerColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                // Ribbon Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: promo.bannerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    promo.ribbonBadge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(promo.icon, size: 18, color: promo.bannerColor),
                const SizedBox(width: 4),
                Text(
                  promo.availabilityTag,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Main Card Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo.title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),

                // Agency & Rating
                Row(
                  children: [
                    Text(
                      promo.agencyName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.primary,
                      size: 15,
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star_rounded, size: 15, color: AppColors.starAmber),
                    const SizedBox(width: 2),
                    Text(
                      '${promo.rating} (${promo.reviewsCount}+)',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Promo code pill & action buttons
                Row(
                  children: [
                    if (promo.code != null) ...[
                      // Code Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.border,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.confirmation_number_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              promo.code!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 1,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Copy Code Button
                      IconButton(
                        key: Key('copy_code_${promo.id}'),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: 'Copy Code',
                        color: AppColors.primaryDark,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: promo.code!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Voucher code "${promo.code}" copied to clipboard!'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.primaryDark,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                    const Spacer(),

                    // Apply / View Packages Button
                    ElevatedButton(
                      key: Key('apply_offer_${promo.id}'),
                      onPressed: () {
                        // Filter feed by agency or offers
                        ref.read(filterPillsProvider.notifier).setOffersOnly(true);
                        ref.read(searchCriteriaProvider.notifier).updateQuery(promo.agencyName);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Applied offer for ${promo.agencyName}'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.primaryDark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: promo.bannerColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'View Trips',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
