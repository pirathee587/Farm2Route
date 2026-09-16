import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/models/pod_model.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../data/repositories/pod_repository.dart';

enum FarmerPodDecision { confirmed, disputed }

class PodReviewPage extends ConsumerStatefulWidget {
  final String bookingId;
  final PodModel? initialPod;

  const PodReviewPage({
    super.key,
    required this.bookingId,
    this.initialPod,
  });

  @override
  ConsumerState<PodReviewPage> createState() => _PodReviewPageState();
}

class _PodReviewPageState extends ConsumerState<PodReviewPage> {
  late Future<PodModel?> _podFuture;
  FarmerPodDecision _selectedDecision = FarmerPodDecision.confirmed;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialPod != null) {
      _podFuture = Future.value(widget.initialPod);
    } else {
      _podFuture = ref.read(farmerPodRepositoryProvider).getPod(widget.bookingId);
    }
    _notesController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool _isSubmitEnabled() {
    if (_isSubmitting) return false;
    if (_selectedDecision == FarmerPodDecision.disputed) {
      return _notesController.text.trim().isNotEmpty;
    }
    return true;
  }

  Future<void> _submitDecision(PodModel currentPod) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final statusString = _selectedDecision == FarmerPodDecision.confirmed
        ? 'CONFIRMED'
        : 'DISPUTED';
    final notes = _notesController.text.trim();

    try {
      final updatedPod = await ref.read(farmerPodRepositoryProvider).confirmPod(
            bookingId: widget.bookingId,
            status: statusString,
            notes: notes.isNotEmpty ? notes : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              statusString == 'CONFIRMED'
                  ? 'Delivery confirmed successfully!'
                  : 'Problem reported. Incident has been opened.',
            ),
            backgroundColor: statusString == 'CONFIRMED'
                ? AppColors.success
                : AppColors.error,
          ),
        );
        setState(() {
          _isSubmitting = false;
          _podFuture = Future.value(updatedPod);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        title: const Text('Proof of Delivery Review'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: FutureBuilder<PodModel?>(
        future: _podFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final pod = snapshot.data ?? widget.initialPod;

          if (pod == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.description_outlined,
                        size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'No Proof of Delivery Found',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Proof of Delivery has not been uploaded yet for booking #${widget.bookingId}.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final String currentStatus =
              pod.farmerConfirmationStatus?.toUpperCase() ?? 'PENDING';
          final bool isPending = currentStatus == 'PENDING';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Header Card
                    _buildStatusCard(currentStatus, pod.farmerConfirmedAt, dateFormat),

                    const SizedBox(height: 16),

                    // Delivery Details Card
                    AgrizelCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_user_outlined,
                                  color: AppColors.primary, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Delivery Details',
                                style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Recipient Name',
                            value: pod.recipientName,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.phone_outlined,
                            label: 'Recipient Phone',
                            value: pod.recipientPhone,
                          ),
                          if (pod.deliveryTimestamp != null) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              icon: Icons.access_time_rounded,
                              label: 'Delivered At',
                              value: dateFormat.format(pod.deliveryTimestamp!),
                            ),
                          ],
                          if (pod.deliveryLatitude != null &&
                              pod.deliveryLongitude != null) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              icon: Icons.location_on_outlined,
                              label: 'GPS Coordinates',
                              value:
                                  '${pod.deliveryLatitude!.toStringAsFixed(5)}, ${pod.deliveryLongitude!.toStringAsFixed(5)}',
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Photo & Signature Media Section
                    AgrizelCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Evidence',
                            style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 14),

                          // Delivery Photo
                          Text(
                            'Cargo Delivery Photo',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              color: const Color(0xFFEFEFEF),
                              child: (pod.deliveryPhotoUrl != null &&
                                      pod.deliveryPhotoUrl!.isNotEmpty)
                                  ? Image.network(
                                      pod.deliveryPhotoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.broken_image_outlined,
                                                size: 40, color: Colors.grey),
                                            SizedBox(height: 6),
                                            Text('Photo unavailable',
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    )
                                  : const Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.image_rounded,
                                              size: 40, color: Colors.grey),
                                          SizedBox(height: 6),
                                          Text('Delivery photo captured',
                                              style: TextStyle(
                                                  color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Signature
                          Text(
                            'Recipient Signature',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 110,
                              width: double.infinity,
                              color: const Color(0xFFFAFAFA),
                              child: (pod.recipientSignatureUrl != null &&
                                      pod.recipientSignatureUrl!.isNotEmpty)
                                  ? Image.network(
                                      pod.recipientSignatureUrl!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Center(
                                        child: Text('Signature captured',
                                            style: TextStyle(color: Colors.grey)),
                                      ),
                                    )
                                  : const Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.edit_note_rounded,
                                              color: AppColors.primary),
                                          SizedBox(width: 8),
                                          Text('Signature on file',
                                              style: TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Read-only Notes or Action Controls
                    if (!isPending) ...[
                      if (pod.notes != null && pod.notes!.isNotEmpty)
                        AgrizelCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Confirmation Notes',
                                style: AppTextStyles.headingSmall.copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                pod.notes!,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                    ] else ...[
                      // Confirmation Action Controls for Farmers
                      AgrizelCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Review Delivery',
                              style: AppTextStyles.headingSmall.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Confirm receipt of goods or report an issue with this shipment.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Choice Options
                            RadioListTile<FarmerPodDecision>(
                              key: const Key('radio_confirm_delivery'),
                              title: const Text(
                                'Confirm Delivery',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text('Everything received in good condition'),
                              value: FarmerPodDecision.confirmed,
                              groupValue: _selectedDecision,
                              activeColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedDecision = val;
                                  });
                                }
                              },
                            ),
                            RadioListTile<FarmerPodDecision>(
                              key: const Key('radio_report_problem'),
                              title: const Text(
                                'Report a Problem (Dispute)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                              subtitle: const Text(
                                  'Cargo damaged, missing, or incorrect delivery'),
                              value: FarmerPodDecision.disputed,
                              groupValue: _selectedDecision,
                              activeColor: AppColors.error,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedDecision = val;
                                  });
                                }
                              },
                            ),

                            // Notes field required for DISPUTED
                            if (_selectedDecision == FarmerPodDecision.disputed) ...[
                              const SizedBox(height: 12),
                              TextField(
                                key: const Key('field_dispute_notes'),
                                controller: _notesController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Explain Issue (Required)',
                                  hintText:
                                      'Describe damage, missing items, or dispute reasons...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.error, width: 2),
                                  ),
                                ),
                              ),
                            ],

                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                    color: AppColors.error, fontSize: 13),
                              ),
                            ],

                            const SizedBox(height: 18),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                key: const Key('btn_submit_pod_decision'),
                                onPressed: _isSubmitEnabled()
                                    ? () => _submitDecision(pod)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _selectedDecision == FarmerPodDecision.confirmed
                                          ? AppColors.primary
                                          : AppColors.error,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _selectedDecision == FarmerPodDecision.confirmed
                                            ? 'Confirm Delivery'
                                            : 'Submit Dispute & Open Incident',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(
      String status, DateTime? confirmedAt, DateFormat dateFormat) {
    Color cardColor;
    IconData icon;
    String statusTitle;
    String statusDesc;

    switch (status) {
      case 'CONFIRMED':
        cardColor = AppColors.success;
        icon = Icons.check_circle_rounded;
        statusTitle = 'Delivery Confirmed';
        statusDesc = confirmedAt != null
            ? 'Confirmed on ${dateFormat.format(confirmedAt)}'
            : 'Farmer confirmed receipt of goods';
        break;
      case 'DISPUTED':
        cardColor = AppColors.error;
        icon = Icons.error_rounded;
        statusTitle = 'Delivery Disputed';
        statusDesc = 'Cargo damage incident automatically opened for admin review';
        break;
      default:
        cardColor = const Color(0xFFE08A00);
        icon = Icons.pending_actions_rounded;
        statusTitle = 'Delivery Confirmation Needed';
        statusDesc = 'Please verify receipt and condition of cargo below';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: cardColor, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    color: cardColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusDesc,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: AppTextStyles.bodyMedium.copyWith(
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
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
