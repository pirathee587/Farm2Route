// ==============================================================================
// Farmer Package Details & Subscription Screen
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../../../shared/widgets/agrizel_pill_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/farmer_dashboard_models.dart';
import '../providers/farmer_dashboard_provider.dart';

class FarmerPackageDetailsScreen extends ConsumerStatefulWidget {
  final LogisticsPackageModel? package;

  const FarmerPackageDetailsScreen({super.key, this.package});

  @override
  ConsumerState<FarmerPackageDetailsScreen> createState() =>
      _FarmerPackageDetailsScreenState();
}

class _FarmerPackageDetailsScreenState
    extends ConsumerState<FarmerPackageDetailsScreen> {
  bool _isSubscribing = false;

  late LogisticsPackageModel _pkg;

  @override
  void initState() {
    super.initState();
    _pkg = widget.package ??
        const LogisticsPackageModel(
          id: 'pkg-seasonal-pass',
          name: 'Seasonal Harvest Unlimited Pass',
          frequency: 'Seasonal (3 Months)',
          price: 45000.0,
          discountBadge: 'Save 35%',
          description:
              'Priority dispatch access across all Central Province markets during peak crop cycle.',
          features: [
            'Guaranteed hauler dispatch within 60 mins',
            'Zero cancellation or rescheduling fees',
            'Free transit insurance up to LKR 2.5 Million',
            'Direct delivery tracking to Pettah Manning Market',
          ],
        );
  }

  Future<void> _handleSubscribe() async {
    setState(() => _isSubscribing = true);

    final user = ref.read(authNotifierProvider).user;
    final farmerId = user?.id ?? 'farmer-me';
    final repo = ref.read(farmerDashboardRepositoryProvider);

    final success = await repo.subscribeToPackage(farmerId, _pkg.id);

    if (!mounted) return;
    setState(() => _isSubscribing = false);

    if (success) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Subscription Confirmed!',
                style: AppTextStyles.headingMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You have successfully enrolled in the ${_pkg.name}. Priority dispatch perks are now active on your farm profile.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AgrizelPillButton(
                text: 'Back to Dashboard',
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.pop();
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        title: Text(
          'Logistics Package',
          style: AppTextStyles.headingSmall,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Package Card
              AgrizelCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _pkg.frequency,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (_pkg.discountBadge.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.promoRed.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _pkg.discountBadge,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.promoRed,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _pkg.name,
                      style: AppTextStyles.headingLarge.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _pkg.description,
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _pkg.formattedPrice,
                          style: AppTextStyles.displayLarge.copyWith(
                            color: AppColors.primaryDark,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '/ billed ${_pkg.frequency.toLowerCase()}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Package Perks List
              Text(
                'Included Plan Privileges',
                style: AppTextStyles.headingSmall.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 14),

              AgrizelCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  children: _pkg.features.map((feature) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              feature,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),

              // Subscribe CTA
              AgrizelPillButton(
                text: 'Subscribe to Package',
                isLoading: _isSubscribing,
                icon: Icons.verified_rounded,
                onPressed: _handleSubscribe,
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Cancel anytime • No lock-in contracts • Seasonal flexibility',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
