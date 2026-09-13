import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../data/models/admin_incident_model.dart';
import '../providers/admin_incident_provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/incident_resolve_dialog.dart';

class AdminIncidentDetailPage extends ConsumerWidget {
  final String incidentId;

  const AdminIncidentDetailPage({
    super.key,
    required this.incidentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(adminIncidentDetailProvider(incidentId));

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: Text(
          'Incident Investigation',
          style: AppTextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: detailAsync.when(
        data: (incident) => _buildBody(context, ref, incident),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'Failed to load incident detail',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminIncidentDetailProvider(incidentId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, AdminIncidentModel incident) {
    final canAct = incident.status.toUpperCase() == 'OPEN' ||
        incident.status.toUpperCase() == 'INVESTIGATING';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Card
                AgrizelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              incident.incidentType,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildStatusChip(incident.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        incident.title,
                        style: AppTextStyles.headingSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (incident.bookingNumber != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Associated Booking: ${incident.bookingNumber}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.accentDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        incident.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reported: ${_formatDate(incident.createdAt)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Party Summary Cards (Only render non-null cards!)
                if (incident.farmerSummary != null) ...[
                  _buildFarmerCard(incident.farmerSummary!),
                  const SizedBox(height: 12),
                ],
                if (incident.agencySummary != null) ...[
                  _buildAgencyCard(incident.agencySummary!),
                  const SizedBox(height: 12),
                ],
                if (incident.driverSummary != null) ...[
                  _buildDriverCard(incident.driverSummary!),
                  const SizedBox(height: 12),
                ],
                if (incident.vehicleSummary != null) ...[
                  _buildVehicleCard(incident.vehicleSummary!),
                  const SizedBox(height: 12),
                ],

                // 3. Evidence Gallery
                if (incident.evidenceList.isNotEmpty) ...[
                  Text(
                    'Evidence & Photos (${incident.evidenceList.length})',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: incident.evidenceList.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final ev = incident.evidenceList[index];
                        final imageUrl = ev.photoUrl ?? ev.fileUrl ?? '';
                        return GestureDetector(
                          onTap: () => _showFullscreenImage(context, imageUrl, ev.caption),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 130,
                              color: AppColors.surfaceSubtle,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image_outlined, color: AppColors.textLight),
                                    ),
                                  ),
                                  if (ev.caption != null)
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        color: Colors.black54,
                                        padding: const EdgeInsets.all(4),
                                        child: Text(
                                          ev.caption!,
                                          style: const TextStyle(color: Colors.white, fontSize: 10),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 4. Investigation Notes Timeline
                Text(
                  'Investigation Notes & Timeline',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                AgrizelCard(
                  color: AppColors.surfaceSubtle,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 80),
                    child: Text(
                      (incident.investigationNotes != null && incident.investigationNotes!.isNotEmpty)
                          ? incident.investigationNotes!
                          : 'No investigation notes recorded yet.',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontFamily: 'monospace',
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                if (incident.resolutionOutcome != null) ...[
                  const SizedBox(height: 12),
                  AgrizelCard(
                    color: AppColors.primaryLight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Final Resolution Outcome',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          incident.resolutionOutcome!,
                          style: AppTextStyles.bodyMedium,
                        ),
                        if (incident.refundAmount != null && incident.refundAmount! > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Refund Approved: \$${incident.refundAmount!.toStringAsFixed(2)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // 5. Action Bar (Enabled only when status is OPEN or INVESTIGATING)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('add_note_button'),
                  onPressed: canAct ? () => _showAddNoteDialog(context, ref) : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add Note'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  key: const Key('escalate_button'),
                  onPressed: canAct ? () => _showEscalateDialog(context, ref) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Escalate', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  key: const Key('resolve_button'),
                  onPressed: canAct ? () => _showResolveDialog(context, ref) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Resolve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFarmerCard(FarmerSummaryModel farmer) {
    return AgrizelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.agriculture_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Farmer Information',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 12, color: AppColors.border),
          if (farmer.farmerName != null) Text('Name: ${farmer.farmerName}', style: AppTextStyles.bodySmall),
          if (farmer.farmName != null) Text('Farm: ${farmer.farmName}', style: AppTextStyles.bodySmall),
          if (farmer.farmerPhone != null) Text('Phone: ${farmer.farmerPhone}', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildAgencyCard(AgencySummaryModel agency) {
    return AgrizelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.business_rounded, color: AppColors.accentDark, size: 20),
              const SizedBox(width: 8),
              Text(
                'Agency Information',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 12, color: AppColors.border),
          if (agency.companyName != null) Text('Company: ${agency.companyName}', style: AppTextStyles.bodySmall),
          if (agency.contactPhone != null) Text('Phone: ${agency.contactPhone}', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildDriverCard(DriverSummaryModel driver) {
    return AgrizelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_outlined, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                'Driver Information',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 12, color: AppColors.border),
          if (driver.driverName != null) Text('Name: ${driver.driverName}', style: AppTextStyles.bodySmall),
          if (driver.licenseNumber != null) Text('License: ${driver.licenseNumber}', style: AppTextStyles.bodySmall),
          if (driver.driverPhone != null) Text('Phone: ${driver.driverPhone}', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(VehicleSummaryModel vehicle) {
    return AgrizelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, color: AppColors.logoBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Vehicle Information',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 12, color: AppColors.border),
          if (vehicle.registrationNumber != null) Text('Reg No: ${vehicle.registrationNumber}', style: AppTextStyles.bodySmall),
          if (vehicle.vehicleType != null) Text('Type: ${vehicle.vehicleType}', style: AppTextStyles.bodySmall),
          if (vehicle.capacityKg != null) Text('Capacity: ${vehicle.capacityKg} kg', style: AppTextStyles.bodySmall),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, String imageUrl, String? caption) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('Failed to load image', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (caption != null)
              Positioned(
                bottom: 30,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(8)),
                  child: Text(caption, style: const TextStyle(color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Investigation Note'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter investigation updates...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(ctx).pop();
                final repo = ref.read(adminRepositoryProvider);
                await repo.addIncidentNote(incidentId, text);
                ref.invalidate(adminIncidentDetailProvider(incidentId));
                ref.read(adminIncidentNotifierProvider.notifier).fetchIncidents();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Investigation note added successfully')),
                  );
                }
              }
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  void _showEscalateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Escalate Incident'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter escalation notes and priority reason...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(ctx).pop();
                final repo = ref.read(adminRepositoryProvider);
                await repo.escalateIncident(incidentId, text);
                ref.invalidate(adminIncidentDetailProvider(incidentId));
                ref.read(adminIncidentNotifierProvider.notifier).fetchIncidents();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Incident escalated successfully')),
                  );
                }
              }
            },
            child: const Text('Escalate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(BuildContext context, WidgetRef ref) {
    IncidentResolveDialog.show(
      context,
      incidentId: incidentId,
      onResolve: (status, notes, refundAmount) async {
        final repo = ref.read(adminRepositoryProvider);
        await repo.resolveIncident(
          incidentId,
          status: status,
          notes: notes,
          refundAmount: refundAmount,
        );
        ref.invalidate(adminIncidentDetailProvider(incidentId));
        ref.read(adminIncidentNotifierProvider.notifier).fetchIncidents();
        ref.invalidate(adminStatsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Incident status set to $status'),
              backgroundColor: status == 'RESOLVED' ? AppColors.success : AppColors.error,
            ),
          );
        }
      },
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
