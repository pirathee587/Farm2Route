import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../data/review_notification_models.dart';
import '../providers/agency_provider.dart';
import '../providers/review_notification_provider.dart';

class AgencyReviewsPage extends ConsumerWidget {
  final bool embedded;
  const AgencyReviewsPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agencyReviewsProvider);
    final body = state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _F8Error(
        message: 'Unable to load agency reviews',
        onRetry: () => ref.invalidate(agencyReviewsProvider),
      ),
      data: (items) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(agencyReviewsProvider),
        child: items.isEmpty
            ? ListView(
                children: const [_F8Empty(message: 'No agency reviews found.')])
            : ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: items.length,
                itemBuilder: (_, index) => _ReviewCard(review: items[index]),
              ),
      ),
    );
    return embedded
        ? body
        : Scaffold(
            appBar: AppBar(title: const Text('Agency reviews')),
            body: body,
          );
  }
}

class AgencyDriverReviewsPage extends ConsumerWidget {
  final String driverId;
  const AgencyDriverReviewsPage({super.key, required this.driverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(driverReviewsProvider(driverId));
    return Scaffold(
      appBar: AppBar(title: const Text('Driver reviews')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _F8Error(
          message: 'Unable to load driver reviews',
          onRetry: () => ref.invalidate(driverReviewsProvider(driverId)),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(driverReviewsProvider(driverId)),
          child: items.isEmpty
              ? ListView(
                  children: const [_F8Empty(message: 'No driver reviews yet.')])
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final review = items[index];
                    return AgrizelCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading:
                            const Icon(Icons.star, color: AppColors.starAmber),
                        title:
                            Text('${review.driverRating ?? 'No rating'} / 5'),
                        subtitle: Text([
                          if (review.driverComment != null)
                            review.driverComment!,
                          if (review.bookingNumber != null)
                            'Booking ${review.bookingNumber}',
                          if (review.createdAt != null)
                            _f8Date(review.createdAt!),
                        ].join('\n')),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  final AgencyReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasResponse = review.agencyResponse?.trim().isNotEmpty == true;
    return AgrizelCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  review.bookingNumber == null
                      ? 'Review'
                      : 'Booking ${review.bookingNumber}',
                  style: AppTextStyles.headingSmall,
                ),
              ),
              _Rating(value: review.agencyRating),
            ],
          ),
          if (review.driverName != null) ...[
            const SizedBox(height: 6),
            Text('Driver: ${review.driverName}'),
          ],
          if (review.agencyComment != null) ...[
            const SizedBox(height: 12),
            Text(review.agencyComment!),
          ],
          if (review.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(_f8Date(review.createdAt!), style: _mutedStyle),
          ],
          if (review.moderationStatus != null) ...[
            const SizedBox(height: 8),
            Chip(label: Text(_f8Label(review.moderationStatus!))),
          ],
          const Divider(height: 24),
          if (hasResponse) ...[
            Text('Agency response', style: AppTextStyles.headingSmall),
            const SizedBox(height: 6),
            Text(review.agencyResponse!),
            if (review.agencyRespondedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_f8Date(review.agencyRespondedAt!),
                    style: _mutedStyle),
              ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _showResponseDialog(context, ref),
              icon: const Icon(Icons.reply_outlined),
              label: Text(hasResponse ? 'Update response' : 'Respond'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showResponseDialog(BuildContext context, WidgetRef ref) async {
    final response = await showDialog<String>(
      context: context,
      builder: (_) => _ReviewResponseDialog(initial: review.agencyResponse),
    );
    if (response == null || !context.mounted) return;
    try {
      await ref
          .read(agencyRepositoryProvider)
          .respondToReview(review.id, response);
      ref.invalidate(agencyReviewsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agency response saved.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_reviewError(error))),
      );
    }
  }
}

class _ReviewResponseDialog extends StatefulWidget {
  final String? initial;
  const _ReviewResponseDialog({this.initial});

  @override
  State<_ReviewResponseDialog> createState() => _ReviewResponseDialogState();
}

class _ReviewResponseDialogState extends State<_ReviewResponseDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial ?? '');
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(
            widget.initial == null ? 'Respond to review' : 'Update response'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          maxLines: 5,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Response',
            hintText: 'Write a response to the farmer',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
        ],
      );

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Response cannot be empty.')),
      );
      return;
    }
    if (value.length > 1000) return;
    setState(() => _submitting = true);
    Navigator.pop(context, value);
  }
}

class AgencyNotificationsPage extends ConsumerStatefulWidget {
  final bool embedded;
  const AgencyNotificationsPage({super.key, this.embedded = false});

  @override
  ConsumerState<AgencyNotificationsPage> createState() =>
      _AgencyNotificationsPageState();
}

class _AgencyNotificationsPageState
    extends ConsumerState<AgencyNotificationsPage> {
  final _marking = <String>{};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agencyNotificationsProvider);
    final body = state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _F8Error(
              message: 'Unable to load notifications',
              onRetry: () => ref.invalidate(agencyNotificationsProvider),
            ),
        data: (items) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(agencyNotificationsProvider);
                ref.invalidate(agencyUnreadCountProvider);
              },
              child: items.isEmpty
                  ? ListView(children: const [
                      _F8Empty(message: 'No notifications found.')
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (_, index) => _NotificationCard(
                        notification: items[index],
                        busy: _marking.contains(items[index].id),
                        onOpen: () => _open(items[index]),
                      ),
                    ),
            ));
    return widget.embedded
        ? body
        : Scaffold(
            appBar: AppBar(
              title: const Text('Notifications'),
              actions: [
                IconButton(
                  tooltip: 'Refresh notifications',
                  onPressed: () {
                    ref.invalidate(agencyNotificationsProvider);
                    ref.invalidate(agencyUnreadCountProvider);
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            body: body,
          );
  }

  Future<void> _open(AgencyNotificationModel notification) async {
    var readSucceeded = true;
    if (!notification.read && !_marking.contains(notification.id)) {
      setState(() => _marking.add(notification.id));
      try {
        await ref
            .read(agencyRepositoryProvider)
            .markNotificationRead(notification.id);
        ref.invalidate(agencyNotificationsProvider);
        ref.invalidate(agencyUnreadCountProvider);
      } catch (error) {
        readSucceeded = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_notificationError(error))),
          );
        }
      } finally {
        if (mounted) setState(() => _marking.remove(notification.id));
      }
    }
    if (!mounted || !readSucceeded) return;
    final destination = _notificationDestination(notification);
    if (destination != null) context.go(destination);
  }
}

class _NotificationCard extends StatelessWidget {
  final AgencyNotificationModel notification;
  final bool busy;
  final VoidCallback onOpen;
  const _NotificationCard({
    required this.notification,
    required this.busy,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) => AgrizelCard(
        margin: const EdgeInsets.only(bottom: 10),
        color:
            notification.read ? AppColors.surfaceLight : AppColors.primaryLight,
        onTap: busy ? null : onOpen,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              notification.read
                  ? Icons.notifications_none
                  : Icons.notifications_active_outlined,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title, style: AppTextStyles.headingSmall),
                  const SizedBox(height: 5),
                  Text(notification.message),
                  const SizedBox(height: 7),
                  Text(
                    '${_f8Label(notification.notificationType)}${notification.createdAt == null ? '' : ' • ${_f8Date(notification.createdAt!)}'}',
                    style: _mutedStyle,
                  ),
                ],
              ),
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (!notification.read)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Chip(label: Text('Unread')),
              ),
          ],
        ),
      );
}

class _Rating extends StatelessWidget {
  final int? value;
  const _Rating({required this.value});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: AppColors.starAmber, size: 20),
          const SizedBox(width: 4),
          Text(value == null ? 'No rating' : '$value / 5'),
        ],
      );
}

class _F8Error extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _F8Error({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

class _F8Empty extends StatelessWidget {
  final String message;
  const _F8Empty({required this.message});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(48),
        child: Center(child: Text(message)),
      );
}

const _mutedStyle = TextStyle(color: AppColors.textSecondary, fontSize: 12);

String _f8Label(String value) => value
    .replaceAll('_', ' ')
    .toLowerCase()
    .split(' ')
    .map((word) =>
        word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

String _f8Date(String value) {
  final parsed = DateTime.tryParse(value);
  return parsed == null ? value : parsed.toLocal().toString().split('.').first;
}

String? _notificationDestination(AgencyNotificationModel notification) {
  final id = notification.referenceId;
  switch (notification.referenceType?.toUpperCase()) {
    case 'BOOKING':
      return id == null ? null : '/agency/bookings/$id';
    case 'VEHICLE':
      return id == null ? null : '/agency/vehicles/$id';
    case 'REVIEW':
      return '/agency/reviews';
    default:
      return null;
  }
}

String _reviewError(Object error) {
  if (error is AppException &&
      (error.statusCode == 400 || error.statusCode == 422)) {
    return error.message;
  }
  if (error is AppException &&
      (error.statusCode == 401 || error.statusCode == 403)) {
    return 'You are not authorized to respond to this review.';
  }
  return 'Unable to save the review response. Please try again.';
}

String _notificationError(Object error) {
  if (error is AppException &&
      (error.statusCode == 401 || error.statusCode == 403)) {
    return 'You are not authorized to update this notification.';
  }
  return 'Unable to mark the notification as read. Please try again.';
}
