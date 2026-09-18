import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../data/models/admin_incident_model.dart';
import '../providers/admin_incident_provider.dart';

class AdminIncidentListPage extends ConsumerWidget {
  const AdminIncidentListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentState = ref.watch(adminIncidentNotifierProvider);
    final notifier = ref.read(adminIncidentNotifierProvider.notifier);
    final currentFilter = notifier.filter;

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: Text(
          'Active Incidents & Moderation',
          style: AppTextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            color: AppColors.surfaceLight,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All Statuses',
                        isSelected: currentFilter.status == null || currentFilter.status == 'ALL',
                        onSelected: () => notifier.setFilter(status: null),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'OPEN',
                        isSelected: currentFilter.status == 'OPEN',
                        onSelected: () => notifier.setFilter(status: 'OPEN'),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'INVESTIGATING',
                        isSelected: currentFilter.status == 'INVESTIGATING',
                        onSelected: () => notifier.setFilter(status: 'INVESTIGATING'),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'RESOLVED',
                        isSelected: currentFilter.status == 'RESOLVED',
                        onSelected: () => notifier.setFilter(status: 'RESOLVED'),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'REJECTED',
                        isSelected: currentFilter.status == 'REJECTED',
                        onSelected: () => notifier.setFilter(status: 'REJECTED'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Incident Type Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All Types',
                        isSelected: currentFilter.incidentType == null || currentFilter.incidentType == 'ALL',
                        onSelected: () => notifier.setFilter(incidentType: null),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'CROP_DAMAGE',
                        isSelected: currentFilter.incidentType == 'CROP_DAMAGE',
                        onSelected: () => notifier.setFilter(incidentType: 'CROP_DAMAGE'),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'CARGO_DAMAGE',
                        isSelected: currentFilter.incidentType == 'CARGO_DAMAGE',
                        onSelected: () => notifier.setFilter(incidentType: 'CARGO_DAMAGE'),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'DELAY',
                        isSelected: currentFilter.incidentType == 'DELAY',
                        onSelected: () => notifier.setFilter(incidentType: 'DELAY'),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'BREAKDOWN',
                        isSelected: currentFilter.incidentType == 'BREAKDOWN',
                        onSelected: () => notifier.setFilter(incidentType: 'BREAKDOWN'),
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'DRIVER_MISCONDUCT',
                        isSelected: currentFilter.incidentType == 'DRIVER_MISCONDUCT',
                        onSelected: () => notifier.setFilter(incidentType: 'DRIVER_MISCONDUCT'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Incidents List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => notifier.fetchIncidents(),
              child: incidentState.when(
                data: (incidents) {
                  if (incidents.isEmpty) {
                    return _buildEmptyState('No incidents match the selected filters.');
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: incidents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = incidents[index];
                      return AgrizelCard(
                        key: Key('incident_card_${item.id}'),
                        onTap: () {
                          context.push('/admin/incidents/${item.id}');
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _getIncidentColor(item.incidentType).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getIncidentIcon(item.incidentType),
                                color: _getIncidentColor(item.incidentType),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item.bookingNumber != null
                                            ? 'Booking ${item.bookingNumber}'
                                            : item.incidentType,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.title,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Reporter: ${_getReporterName(item)} • ${_formatDate(item.createdAt)}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 11,
                                      color: AppColors.textLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusChip(item.status),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load incidents',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => notifier.fetchIncidents(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceSubtle,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;

    switch (status.toUpperCase()) {
      case 'RESOLVED':
        bg = AppColors.primaryLight;
        fg = AppColors.primary;
        break;
      case 'INVESTIGATING':
        bg = const Color(0xFFE3F2FD);
        fg = AppColors.info;
        break;
      case 'REJECTED':
        bg = const Color(0xFFFFEBEE);
        fg = AppColors.error;
        break;
      case 'OPEN':
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
            const Icon(Icons.report_off_outlined, size: 48, color: AppColors.textLight),
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

  IconData _getIncidentIcon(String type) {
    switch (type.toUpperCase()) {
      case 'CROP_DAMAGE':
        return Icons.grass_rounded;
      case 'CARGO_DAMAGE':
        return Icons.inventory_2_outlined;
      case 'DELAY':
        return Icons.schedule_outlined;
      case 'VEHICLE_ISSUE':
        return Icons.build_outlined;
      case 'BREAKDOWN':
        return Icons.car_repair_outlined;
      case 'DRIVER_MISCONDUCT':
        return Icons.person_off_outlined;
      case 'LOST_CARGO':
      case 'THEFT':
        return Icons.shield_outlined;
      case 'ACCIDENT':
        return Icons.warning_amber_rounded;
      default:
        return Icons.report_problem_outlined;
    }
  }

  Color _getIncidentColor(String type) {
    switch (type.toUpperCase()) {
      case 'CROP_DAMAGE':
      case 'CARGO_DAMAGE':
        return AppColors.error;
      case 'BREAKDOWN':
      case 'ACCIDENT':
        return AppColors.warning;
      case 'DELAY':
        return AppColors.accentDark;
      case 'DRIVER_MISCONDUCT':
        return AppColors.logoBlue;
      default:
        return AppColors.primary;
    }
  }

  String _getReporterName(AdminIncidentModel item) {
    if (item.farmerSummary != null && item.farmerSummary!.farmerName != null) {
      return item.farmerSummary!.farmerName!;
    }
    if (item.agencySummary != null && item.agencySummary!.companyName != null) {
      return item.agencySummary!.companyName!;
    }
    if (item.driverSummary != null && item.driverSummary!.driverName != null) {
      return item.driverSummary!.driverName!;
    }
    return 'Platform System';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
