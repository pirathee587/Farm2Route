import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../data/models/admin_review_model.dart';
import '../providers/admin_provider.dart';
import '../providers/admin_review_provider.dart';

class AdminReviewModerationPage extends ConsumerWidget {
  const AdminReviewModerationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(adminReportedReviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: Text(
          'Review Moderation Queue',
          style: AppTextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminReportedReviewsProvider);
        },
        child: reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = reviews[index];
                return _buildReviewCard(context, ref, item);
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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load reported reviews',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(adminReportedReviewsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, WidgetRef ref, AdminReviewModel item) {
    final farmer = item.farmerName ?? 'Anonymous Farmer';
    final agency = item.agencyName ?? item.driverName ?? 'Logistics Provider';

    return AgrizelCard(
      key: Key('review_card_${item.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Farmer -> Agency & Status Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$farmer → $agency',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusChip(item.moderationStatus),
            ],
          ),
          if (item.bookingNumber != null) ...[
            const SizedBox(height: 2),
            Text(
              'Booking: ${item.bookingNumber}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Star Ratings Row
          Row(
            children: [
              if (item.agencyRating != null) ...[
                _buildStarRating('Agency', item.agencyRating!),
                const SizedBox(width: 12),
              ],
              if (item.driverRating != null) ...[
                _buildStarRating('Driver', item.driverRating!),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Review Comment Text
          if (item.comment != null && item.comment!.isNotEmpty) ...[
            Text(
              '"${item.comment}"',
              style: AppTextStyles.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Agency Response (if present)
          if (item.agencyResponse != null && item.agencyResponse!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Agency Response: "${item.agencyResponse}"',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          Text(
            'Submitted: ${_formatDate(item.createdAt)}',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10,
              color: AppColors.textLight,
            ),
          ),
          const Divider(height: 16, color: AppColors.border),

          // Action Buttons Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Hide Button (opens confirm dialog with optional reason)
              TextButton.icon(
                key: Key('hide_button_${item.id}'),
                onPressed: () => _showHideDialog(context, ref, item.id),
                icon: const Icon(Icons.visibility_off_outlined, size: 16, color: AppColors.error),
                label: const Text('Hide', style: TextStyle(color: AppColors.error)),
              ),
              const SizedBox(width: 4),

              // Restore Button — ONLY SHOWN IF moderationStatus == "HIDDEN"
              if (item.moderationStatus.toUpperCase() == 'HIDDEN') ...[
                TextButton.icon(
                  key: Key('restore_button_${item.id}'),
                  onPressed: () => _showRestoreDialog(context, ref, item.id),
                  icon: const Icon(Icons.restore_outlined, size: 16, color: AppColors.primary),
                  label: const Text('Restore', style: TextStyle(color: AppColors.primary)),
                ),
                const SizedBox(width: 4),
              ],

              // Escalate Button (opens confirm dialog with optional reason)
              TextButton.icon(
                key: Key('escalate_button_${item.id}'),
                onPressed: () => _showEscalateDialog(context, ref, item.id),
                icon: const Icon(Icons.priority_high_rounded, size: 16, color: AppColors.warning),
                label: const Text('Escalate', style: TextStyle(color: AppColors.warning)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(String label, double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            5,
            (index) => Icon(
              index < rating ? Icons.star_rounded : Icons.star_border_rounded,
              size: 14,
              color: AppColors.starAmber,
            ),
          ),
        ),
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
      case 'HIDDEN':
        bg = const Color(0xFFFFEBEE);
        fg = AppColors.error;
        break;
      case 'ESCALATED':
        bg = const Color(0xFFFFF3E0);
        fg = AppColors.warning;
        break;
      case 'PENDING_REVIEW':
      default:
        bg = AppColors.accentLight;
        fg = AppColors.accentDark;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rate_review_outlined, size: 48, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text(
              'No reviews currently flagged for moderation',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showHideDialog(BuildContext context, WidgetRef ref, String reviewId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hide Review'),
        content: TextField(
          key: const Key('hide_reason_field'),
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Enter reason for hiding (optional)...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirm_hide_button'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final repo = ref.read(adminRepositoryProvider);
              await repo.hideReview(reviewId, reason: controller.text.trim());
              ref.invalidate(adminReportedReviewsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review hidden successfully')),
                );
              }
            },
            child: const Text('Hide Review', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context, WidgetRef ref, String reviewId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Review'),
        content: const Text('Are you sure you want to restore this review to public display?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirm_restore_button'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final repo = ref.read(adminRepositoryProvider);
              await repo.restoreReview(reviewId);
              ref.invalidate(adminReportedReviewsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review restored successfully')),
                );
              }
            },
            child: const Text('Restore Review', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEscalateDialog(BuildContext context, WidgetRef ref, String reviewId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Escalate Review'),
        content: TextField(
          key: const Key('escalate_reason_field'),
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Enter reason for escalation (optional)...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirm_escalate_button'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final repo = ref.read(adminRepositoryProvider);
              await repo.escalateReview(reviewId, reason: controller.text.trim());
              ref.invalidate(adminReportedReviewsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review escalated successfully')),
                );
              }
            },
            child: const Text('Escalate Review', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
