import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../providers/admin_provider.dart';
import '../providers/kyc_provider.dart';

class KycDecisionSheet extends ConsumerStatefulWidget {
  final String entityType; // 'agency', 'driver', 'vehicle'
  final String entityId;
  final String entityName;
  final Map<String, String> details;
  final String kycStatus;

  const KycDecisionSheet({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.entityName,
    required this.details,
    required this.kycStatus,
  });

  static Future<void> show(
    BuildContext context, {
    required String entityType,
    required String entityId,
    required String entityName,
    required Map<String, String> details,
    required String kycStatus,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => KycDecisionSheet(
        entityType: entityType,
        entityId: entityId,
        entityName: entityName,
        details: details,
        kycStatus: kycStatus,
      ),
    );
  }

  @override
  ConsumerState<KycDecisionSheet> createState() => _KycDecisionSheetState();
}

class _KycDecisionSheetState extends ConsumerState<KycDecisionSheet> {
  late final TextEditingController _reasonController;
  bool _isSubmitting = false;
  bool _isReasonValid = false;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
    _reasonController.addListener(_onReasonChanged);
  }

  void _onReasonChanged() {
    final isValid = _reasonController.text.trim().isNotEmpty;
    if (isValid != _isReasonValid) {
      setState(() {
        _isReasonValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _reasonController.removeListener(_onReasonChanged);
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitDecision(String status) async {
    if (_isSubmitting) return;

    if (status == 'REJECTED' && !_isReasonValid) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(adminRepositoryProvider);
      await repository.submitKycDecision(
        entityType: widget.entityType,
        entityId: widget.entityId,
        status: status,
        rejectionReason: status == 'REJECTED' ? _reasonController.text.trim() : null,
      );

      refreshAllKycProviders(ref);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.entityName} KYC status set to $status'),
            backgroundColor: status == 'APPROVED' ? AppColors.success : AppColors.error,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit decision: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.entityName,
                    style: AppTextStyles.headingMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(widget.kycStatus),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.entityType.toUpperCase()} Verification Review',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Detail Key-Values
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: widget.details.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            entry.value,
                            textAlign: TextAlign.end,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Rejection Reason Input Field
            Text(
              'Rejection Reason (Required for rejection)',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('rejection_reason_field'),
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Enter reason for rejecting application...',
                hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.surfaceSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isReasonValid
                  ? '✓ Reason provided — Reject button enabled'
                  : '⚠ Enter a rejection reason above to enable the Reject button',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _isReasonValid ? AppColors.primary : AppColors.error,
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons Row (Mobile Responsive)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    key: const Key('reject_button'),
                    onPressed: (_isReasonValid && !_isSubmitting)
                        ? () => _submitDecision('REJECTED')
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      disabledBackgroundColor: AppColors.border,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Reject',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('approve_button'),
                    onPressed: !_isSubmitting ? () => _submitDecision('APPROVED') : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Approve',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
