import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../data/models/transport_package_model.dart';
import 'login_required_sheet.dart';
import 'package:intl/intl.dart';
import 'package:farm2route_app/features/landing/presentation/widgets/package_details_sheet.dart';

class LandingPackageCard extends StatelessWidget {
  final TransportPackageModel package;

  const LandingPackageCard({super.key, required this.package});

  @override
  Widget build(BuildContext context) {
    final weightFormat = NumberFormat('#,###');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Soft light-gray (#F5F5F5) background
        borderRadius: BorderRadius.circular(16), // 16px rounded corners
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Offer banner ribbon if any
          if (package.hasOffer && package.offerLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_rounded, size: 14, color: AppColors.primaryDark),
                  const SizedBox(width: 6),
                  Text(
                    package.offerLabel!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ROW 1: 🏢 Agency Name | ⭐ Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.business_rounded, size: 18, color: AppColors.primaryDark),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              package.agencyName,
                              style: AppTextStyles.headingSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 15, color: AppColors.starAmber),
                          const SizedBox(width: 3),
                          Text(
                            package.rating.toString(),
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ROW 2: 📍 Pickup Location ↓ 🏪 Market Name, District
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.circle, size: 8, color: AppColors.primary),
                          Container(width: 1.5, height: 16, color: AppColors.border),
                          const Icon(Icons.location_on, size: 12, color: AppColors.promoRed),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📍 ${package.pickupLocation}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '🏪 ${package.deliveryMarket}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ROW 3: 🚛 Vehicle Type | 💰 LKR X / KG
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              package.vehicleType,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '💰 LKR ${package.pricePerKg.toStringAsFixed(0)} / KG',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ROW 4: ⚖️ Up to X,XXX KG | 🚚 X Trucks Available | 📏 X km from you
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      '⚖️ Up to ${weightFormat.format(package.maxWeightKg)} KG',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Text('•', style: AppTextStyles.bodySmall),
                    Text(
                      '🚚 ${package.availableTrucks} Trucks',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    Text('•', style: AppTextStyles.bodySmall),
                    Text(
                      '📏 ${package.distanceKm} km',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // BUTTONS: Split 50/50 [ View Details ] | [ Book Now ]
                Row(
                  children: [
                    // [ View Details ] (outlined, no auth)
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          key: Key('view_details_${package.id}'),
                          onPressed: () => PackageDetailsSheet.show(context, package),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border, width: 1.2),
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: Text(
                            'View Details',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // [ Book Now ] (filled green, opens Login Required sheet)
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          key: Key('book_now_${package.id}'),
                          onPressed: () {
                            LoginRequiredBottomSheet.show(
                              context,
                              title: 'Login to continue your booking',
                              subtitle: 'Sign in to confirm your freight dispatch with ${package.agencyName}.',
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: Text(
                            'Book Now',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
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
