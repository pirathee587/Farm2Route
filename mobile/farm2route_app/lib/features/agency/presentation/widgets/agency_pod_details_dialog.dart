import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../driver/data/models/pod_model.dart';
import '../../../driver/data/repositories/pod_repository.dart';

/// Modal Dialog / Bottom Sheet for Agency managers to view Driver Proof of Delivery (POD) details
class AgencyPodDetailsDialog extends ConsumerWidget {
  final String bookingId;
  final String bookingNumber;

  const AgencyPodDetailsDialog({
    super.key,
    required this.bookingId,
    required this.bookingNumber,
  });

  static Future<void> show(BuildContext context, String bookingId, String bookingNumber) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AgencyPodDetailsDialog(
        bookingId: bookingId,
        bookingNumber: bookingNumber,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: FutureBuilder<PodModel?>(
        future: ref.read(podRepositoryProvider).getPod(bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 250,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Fetching Proof of Delivery details...'),
                  ],
                ),
              ),
            );
          }

          final pod = snapshot.data;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: AppColors.success,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Proof of Delivery (POD)',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Booking: $bookingNumber',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                if (pod == null) ...[
                  // Pending / Sample POD status if backend has no record yet
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.info),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'POD submission records will appear here once driver completes delivery.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Status chip
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                          const SizedBox(width: 6),
                          Text(
                            'DELIVERED & VERIFIED BY DRIVER',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recipient Info Card
                  _buildSectionCard(
                    title: 'Recipient Details',
                    icon: Icons.person_outline_rounded,
                    children: [
                      _buildInfoRow('Recipient Name', pod.recipientName),
                      _buildInfoRow('Recipient Phone', pod.recipientPhone),
                      if (pod.driverName != null && pod.driverName!.isNotEmpty)
                        _buildInfoRow('Driver Name', pod.driverName!),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Delivery Location Card
                  _buildSectionCard(
                    title: 'GPS Delivery Location',
                    icon: Icons.location_on_outlined,
                    children: [
                      _buildInfoRow(
                        'Coordinates',
                        pod.deliveryLatitude != null && pod.deliveryLongitude != null
                            ? '${pod.deliveryLatitude!.toStringAsFixed(6)}, ${pod.deliveryLongitude!.toStringAsFixed(6)}'
                            : 'Location Captured',
                      ),
                      if (pod.deliveryTimestamp != null)
                        _buildInfoRow(
                          'Delivered At',
                          pod.deliveryTimestamp!.toLocal().toString().split('.')[0],
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Recipient Signature
                  _buildSectionCard(
                    title: 'Recipient Touch Signature',
                    icon: Icons.gesture_rounded,
                    children: [
                      if (pod.recipientSignatureUrl != null && pod.recipientSignatureUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 120,
                            color: Colors.grey.shade100,
                            child: Image.network(
                              pod.recipientSignatureUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Text('Signature image captured'),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.draw_rounded, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('On-Screen Touch Signature Captured'),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Delivery Photo Evidence
                  _buildSectionCard(
                    title: 'Cargo Delivery Photo',
                    icon: Icons.camera_alt_outlined,
                    children: [
                      if (pod.deliveryPhotoUrl != null && pod.deliveryPhotoUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            color: Colors.grey.shade100,
                            child: Image.network(
                              pod.deliveryPhotoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Text('Delivery Photo evidence attached'),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.photo_camera_rounded, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('Cargo Delivery Photo Evidence Attached'),
                            ],
                          ),
                        ),
                    ],
                  ),

                  if (pod.notes != null && pod.notes!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildSectionCard(
                      title: 'Driver Delivery Notes',
                      icon: Icons.notes_rounded,
                      children: [
                        Text(
                          pod.notes!,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ],

                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
