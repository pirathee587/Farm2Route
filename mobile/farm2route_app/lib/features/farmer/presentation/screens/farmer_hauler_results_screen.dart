// ==============================================================================
// Farmer Hauler Results & Agency Comparison Screen
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../../../shared/widgets/agrizel_pill_button.dart';
import '../../data/models/farmer_dashboard_models.dart';
import '../providers/farmer_dashboard_provider.dart';

class FarmerHaulerResultsScreen extends ConsumerStatefulWidget {
  final List<HaulerAgencyModel>? initialHaulers;

  const FarmerHaulerResultsScreen({super.key, this.initialHaulers});

  @override
  ConsumerState<FarmerHaulerResultsScreen> createState() =>
      _FarmerHaulerResultsScreenState();
}

class _FarmerHaulerResultsScreenState
    extends ConsumerState<FarmerHaulerResultsScreen> {
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialHaulers != null && widget.initialHaulers!.isNotEmpty) {
        ref
            .read(haulerResultsNotifierProvider.notifier)
            .setHaulers(widget.initialHaulers!);
      }
    });
  }

  void _showBookingConfirmation(HaulerAgencyModel agency) {
    final formState = ref.read(bookingFormNotifierProvider);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Text(
                    'Booking Confirmation',
                    style: AppTextStyles.headingMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Review your dispatch details before confirming hauler booking.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 18),

                  // Summary Details Card
                  AgrizelCard(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.surfaceSubtle,
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          icon: Icons.storefront_rounded,
                          label: 'Hauler',
                          value: agency.name,
                          color: AppColors.primaryDark,
                        ),
                        const Divider(color: AppColors.border, height: 16),
                        _buildSummaryRow(
                          icon: Icons.my_location_rounded,
                          label: 'Pickup',
                          value: formState.pickupLocation,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          icon: Icons.location_on_rounded,
                          label: 'Drop-off',
                          value: formState.destinationLocation,
                        ),
                        const Divider(color: AppColors.border, height: 16),
                        _buildSummaryRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Dispatch Date',
                          value:
                              '${formState.dispatchDate.year}-${formState.dispatchDate.month.toString().padLeft(2, '0')}-${formState.dispatchDate.day.toString().padLeft(2, '0')}',
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          icon: Icons.scale_rounded,
                          label: 'Cargo',
                          value:
                              '${formState.weight.toStringAsFixed(0)} ${formState.weightUnit} • ${formState.produceType}',
                        ),
                        const Divider(color: AppColors.border, height: 16),
                        _buildSummaryRow(
                          icon: Icons.payments_rounded,
                          label: 'Total Fare',
                          value: agency.formattedFare,
                          color: AppColors.primaryDark,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Confirm Button
                  AgrizelPillButton(
                    text: 'Confirm Booking',
                    isLoading: _isConfirming,
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: () async {
                      setSheetState(() => _isConfirming = true);

                      final repo = ref.read(farmerDashboardRepositoryProvider);
                      final request = BookingSubmissionRequest(
                        pickupLocation: formState.pickupLocation,
                        destinationLocation: formState.destinationLocation,
                        dispatchDate: formState.dispatchDate,
                        weightKg: formState.weightInKg,
                        produceType: formState.produceType,
                        haulerId: agency.id,
                        fare: agency.estimatedFare,
                      );

                      final order = await repo.createBooking(request);

                      setSheetState(() => _isConfirming = false);
                      if (!sheetContext.mounted) return;
                      Navigator.of(sheetContext).pop();

                      if (!context.mounted) return;
                      // Show success modal
                      showDialog(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
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
                                  Icons.local_shipping_rounded,
                                  color: AppColors.primary,
                                  size: 36,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Booking Dispatched!',
                                style: AppTextStyles.headingMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tracking Reference:\n${order.bookingRef}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${agency.name} has been notified and scheduled for harvest collection.',
                                style: AppTextStyles.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              AgrizelPillButton(
                                text: 'Back to Dashboard',
                                onPressed: () {
                                  Navigator.of(dialogCtx).pop();
                                  context.go(RouteNames.farmerHome);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color ?? AppColors.textPrimary,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final resultsState = ref.watch(haulerResultsNotifierProvider);
    final displayedHaulers = resultsState.displayedHaulers;

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        title: Text(
          'Available Haulers',
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
        child: Column(
          children: [
            // Sort and Filter Controls Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Text(
                    'Sort by:',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildSortChip('price', 'Price'),
                  const SizedBox(width: 6),
                  _buildSortChip('rating', 'Rating'),
                  const SizedBox(width: 6),
                  _buildSortChip('eta', 'Fastest'),
                  const Spacer(),
                  // Cold Chain Filter Toggle
                  GestureDetector(
                    onTap: () {
                      ref
                          .read(haulerResultsNotifierProvider.notifier)
                          .toggleColdChainOnly(!resultsState.filterColdChainOnly);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: resultsState.filterColdChainOnly
                            ? const Color(0xFFE1F5FE)
                            : AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: resultsState.filterColdChainOnly
                              ? const Color(0xFF0288D1)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.ac_unit_rounded,
                            size: 14,
                            color: resultsState.filterColdChainOnly
                                ? const Color(0xFF0288D1)
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cold-Chain',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              color: resultsState.filterColdChainOnly
                                  ? const Color(0xFF0288D1)
                                  : AppColors.textSecondary,
                              fontWeight: resultsState.filterColdChainOnly
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Haulers List
            Expanded(
              child: displayedHaulers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.local_shipping_outlined,
                            size: 64,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Haulers Match Filter',
                            style: AppTextStyles.headingSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try turning off the Cold-Chain filter or modifying dates.',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: displayedHaulers.length,
                      itemBuilder: (context, index) {
                        final hauler = displayedHaulers[index];
                        return _buildHaulerCard(hauler);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String value, String label) {
    final currentSort = ref.watch(haulerResultsNotifierProvider).sortBy;
    final isSelected = currentSort == value;

    return GestureDetector(
      onTap: () =>
          ref.read(haulerResultsNotifierProvider.notifier).setSortBy(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildHaulerCard(HaulerAgencyModel hauler) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Agency Name & Star Rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hauler.name,
                      style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: AppColors.starAmber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hauler.rating.toStringAsFixed(1),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${hauler.reviewsCount} trips)',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('•', style: AppTextStyles.bodySmall),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          hauler.etaFormatted,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Vehicle details & Cold-chain badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${hauler.vehicleType} • ${hauler.vehiclePlate}',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              if (hauler.coldChainSupported)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.ac_unit_rounded, size: 12, color: Color(0xFF0288D1)),
                      SizedBox(width: 4),
                      Text(
                        'Reefer',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0288D1),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          if (hauler.promoBadge != null && hauler.promoBadge!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                hauler.promoBadge!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.accentDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Bottom Row: Price & Select CTA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Trip Fare',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                  ),
                  Text(
                    hauler.formattedFare,
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => _showBookingConfirmation(hauler),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Select'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
