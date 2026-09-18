import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../data/models/kyc_summary_model.dart';
import '../providers/kyc_provider.dart';
import '../widgets/kyc_decision_sheet.dart';

class KycQueuePage extends ConsumerWidget {
  const KycQueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.canvasCream,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceLight,
          elevation: 0,
          title: Text(
            'KYC Verification Queue',
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(
                text: 'Agencies',
                icon: Icon(Icons.business_rounded, size: 20),
              ),
              Tab(
                text: 'Drivers',
                icon: Icon(Icons.badge_outlined, size: 20),
              ),
              Tab(
                text: 'Vehicles',
                icon: Icon(Icons.local_shipping_outlined, size: 20),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AgenciesTab(),
            _DriversTab(),
            _VehiclesTab(),
          ],
        ),
      ),
    );
  }
}

class _AgenciesTab extends ConsumerWidget {
  const _AgenciesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(pendingAgencyKycProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(pendingAgencyKycProvider);
      },
      child: queueAsync.when(
        data: (agencies) {
          if (agencies.isEmpty) {
            return _buildEmptyState('No pending agency KYC applications');
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: agencies.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = agencies[index];
              return AgrizelCard(
                key: Key('agency_kyc_card_${item.id}'),
                onTap: () {
                  KycDecisionSheet.show(
                    context,
                    entityType: 'agency',
                    entityId: item.id,
                    entityName: item.companyName,
                    kycStatus: item.kycStatus,
                    details: {
                      'Company Name': item.companyName,
                      'Contact Email': item.contactEmail.isNotEmpty ? item.contactEmail : 'N/A',
                      'Contact Phone': item.contactPhone.isNotEmpty ? item.contactPhone : 'N/A',
                      'Submitted On': _formatDate(item.createdAt),
                      if (item.kycRejectionReason != null)
                        'Previous Reason': item.kycRejectionReason!,
                    },
                  );
                },
                child: _buildItemRow(
                  title: item.companyName,
                  subtitle: '${item.contactEmail} • ${item.contactPhone}',
                  dateStr: _formatDate(item.createdAt),
                  status: item.kycStatus,
                  icon: Icons.business_rounded,
                  iconColor: AppColors.accentDark,
                ),
              );
            },
          );
        },
        loading: () => const _LoadingView(),
        error: (err, stack) => _buildErrorView(
          message: 'Failed to load agency KYC queue',
          onRetry: () => ref.invalidate(pendingAgencyKycProvider),
        ),
      ),
    );
  }
}

class _DriversTab extends ConsumerWidget {
  const _DriversTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(pendingDriverKycProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(pendingDriverKycProvider);
      },
      child: queueAsync.when(
        data: (drivers) {
          if (drivers.isEmpty) {
            return _buildEmptyState('No pending driver KYC applications');
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: drivers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = drivers[index];
              return AgrizelCard(
                key: Key('driver_kyc_card_${item.id}'),
                onTap: () {
                  KycDecisionSheet.show(
                    context,
                    entityType: 'driver',
                    entityId: item.id,
                    entityName: item.driverName,
                    kycStatus: item.kycStatus,
                    details: {
                      'Driver Name': item.driverName,
                      'Phone': item.phone.isNotEmpty ? item.phone : 'N/A',
                      'License Number': item.licenseNumber.isNotEmpty ? item.licenseNumber : 'N/A',
                      'Agency': item.agencyName ?? 'Independent',
                      'Submitted On': _formatDate(item.createdAt),
                    },
                  );
                },
                child: _buildItemRow(
                  title: item.driverName,
                  subtitle: 'License: ${item.licenseNumber} • Agency: ${item.agencyName ?? "Independent"}',
                  dateStr: _formatDate(item.createdAt),
                  status: item.kycStatus,
                  icon: Icons.badge_outlined,
                  iconColor: AppColors.info,
                ),
              );
            },
          );
        },
        loading: () => const _LoadingView(),
        error: (err, stack) => _buildErrorView(
          message: 'Failed to load driver KYC queue',
          onRetry: () => ref.invalidate(pendingDriverKycProvider),
        ),
      ),
    );
  }
}

class _VehiclesTab extends ConsumerWidget {
  const _VehiclesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(pendingVehicleKycProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(pendingVehicleKycProvider);
      },
      child: queueAsync.when(
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return _buildEmptyState('No pending vehicle KYC applications');
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: vehicles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = vehicles[index];
              return AgrizelCard(
                key: Key('vehicle_kyc_card_${item.id}'),
                onTap: () {
                  KycDecisionSheet.show(
                    context,
                    entityType: 'vehicle',
                    entityId: item.id,
                    entityName: item.registrationNumber,
                    kycStatus: item.kycStatus,
                    details: {
                      'Registration No': item.registrationNumber,
                      'Vehicle Type': item.vehicleType.isNotEmpty ? item.vehicleType : 'N/A',
                      'Agency': item.agencyName ?? 'N/A',
                      'Submitted On': _formatDate(item.createdAt),
                    },
                  );
                },
                child: _buildItemRow(
                  title: item.registrationNumber,
                  subtitle: 'Type: ${item.vehicleType} • Agency: ${item.agencyName ?? "N/A"}',
                  dateStr: _formatDate(item.createdAt),
                  status: item.kycStatus,
                  icon: Icons.local_shipping_outlined,
                  iconColor: AppColors.primary,
                ),
              );
            },
          );
        },
        loading: () => const _LoadingView(),
        error: (err, stack) => _buildErrorView(
          message: 'Failed to load vehicle KYC queue',
          onRetry: () => ref.invalidate(pendingVehicleKycProvider),
        ),
      ),
    );
  }
}

Widget _buildItemRow({
  required String title,
  required String subtitle,
  required String dateStr,
  required String status,
  required IconData icon,
  required Color iconColor,
}) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'Date: $dateStr',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      _buildStatusChip(status),
    ],
  );
}

Widget _buildStatusChip(String status) {
  Color bg;
  Color fg;

  switch (status.toUpperCase()) {
    case 'APPROVED':
      bg = AppColors.primaryLight;
      fg = AppColors.primary;
      break;
    case 'REJECTED':
      bg = const Color(0xFFFFEBEE);
      fg = AppColors.error;
      break;
    case 'PENDING':
    case 'PENDING_APPROVAL':
    default:
      bg = AppColors.accentLight;
      fg = AppColors.accentDark;
      break;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      status.toUpperCase(),
      style: TextStyle(
        color: fg,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Widget _buildEmptyState(String message) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user_outlined, size: 48, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

Widget _buildErrorView({
  required String message,
  required VoidCallback onRetry,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

String _formatDate(DateTime? dt) {
  if (dt == null) return 'N/A';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
