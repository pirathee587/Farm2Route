import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(notificationsNotifierProvider.notifier).fetchNotifications();
          await ref.read(unreadCountNotifierProvider.notifier).fetchUnreadCount();
        },
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return const _F8EmptyWidget();
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return AgrizelCard(
                  notification: notification,
                  onTap: () {
                    if (!notification.read) {
                      ref
                          .read(notificationsNotifierProvider.notifier)
                          .markAsRead(notification.id);
                    }
                  },
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => _F8ErrorWidget(
            message: error.toString(),
            onRetry: () {
              ref.read(notificationsNotifierProvider.notifier).fetchNotifications();
              ref.read(unreadCountNotifierProvider.notifier).fetchUnreadCount();
            },
          ),
        ),
      ),
    );
  }
}

class AgrizelCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const AgrizelCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _getIconForType(notification.notificationType);
    final iconColor = _getColorForType(notification.notificationType);
    final relativeTime = _formatRelativeTime(notification.createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.read ? Colors.white : AppColors.primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.read
                ? AppColors.border.withOpacity(0.4)
                : AppColors.primary.withOpacity(0.3),
            width: notification.read ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: notification.read
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        relativeTime,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: notification.read
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.read) ...[
              const SizedBox(width: 10),
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'BOOKING_UPDATE':
        return Icons.inventory_2_outlined;
      case 'TRIP_DISPATCH':
        return Icons.local_shipping_outlined;
      case 'POD_SUBMITTED':
        return Icons.fact_check_outlined;
      case 'INCIDENT_ALERT':
        return Icons.warning_amber_rounded;
      case 'KYC_STATUS':
        return Icons.verified_user_outlined;
      case 'PAYMENT':
        return Icons.account_balance_wallet_outlined;
      case 'SYSTEM':
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toUpperCase()) {
      case 'BOOKING_UPDATE':
        return AppColors.info;
      case 'TRIP_DISPATCH':
        return AppColors.primary;
      case 'POD_SUBMITTED':
        return AppColors.success;
      case 'INCIDENT_ALERT':
        return AppColors.error;
      case 'KYC_STATUS':
        return AppColors.accent;
      case 'PAYMENT':
        return AppColors.accentDark;
      case 'SYSTEM':
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}

class _F8EmptyWidget extends StatelessWidget {
  const _F8EmptyWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Notifications',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'You are all caught up! Important updates will appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _F8ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _F8ErrorWidget({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load notifications',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
