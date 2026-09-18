import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

class IncidentResolveDialog extends StatefulWidget {
  final String incidentId;
  final Future<void> Function(String status, String notes, double? refundAmount) onResolve;

  const IncidentResolveDialog({
    super.key,
    required this.incidentId,
    required this.onResolve,
  });

  static Future<void> show(
    BuildContext context, {
    required String incidentId,
    required Future<void> Function(String status, String notes, double? refundAmount) onResolve,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => IncidentResolveDialog(
        incidentId: incidentId,
        onResolve: onResolve,
      ),
    );
  }

  @override
  State<IncidentResolveDialog> createState() => _IncidentResolveDialogState();
}

class _IncidentResolveDialogState extends State<IncidentResolveDialog> {
  String _selectedStatus = 'RESOLVED';
  late final TextEditingController _notesController;
  late final TextEditingController _refundController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _refundController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _refundController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final refundText = _refundController.text.trim();
    double? refundAmount;
    if (refundText.isNotEmpty) {
      refundAmount = double.tryParse(refundText);
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onResolve(
        _selectedStatus,
        _notesController.text.trim(),
        refundAmount,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit resolution: ${e.toString()}'),
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Resolve Incident',
        style: AppTextStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resolution Decision Status *',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),

            // Radio Options for Status
            RadioListTile<String>(
              key: const Key('status_radio_resolved'),
              title: const Text('RESOLVED (Case settled)'),
              value: 'RESOLVED',
              groupValue: _selectedStatus,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedStatus = val);
                }
              },
            ),
            RadioListTile<String>(
              key: const Key('status_radio_rejected'),
              title: const Text('REJECTED (Claim dismissed)'),
              value: 'REJECTED',
              groupValue: _selectedStatus,
              activeColor: AppColors.error,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedStatus = val);
                }
              },
            ),

            const SizedBox(height: 12),
            Text(
              'Resolution Notes',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('resolution_notes_field'),
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter outcome details or settlement terms...',
                hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.surfaceSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              'Refund Amount (Optional)',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              key: const Key('refund_amount_field'),
              controller: _refundController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '\$ ',
                hintText: '0.00',
                hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.surfaceSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('submit_resolve_button'),
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedStatus == 'RESOLVED' ? AppColors.primary : AppColors.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'Submit Decision',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
