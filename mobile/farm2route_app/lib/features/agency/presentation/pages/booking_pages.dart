import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../data/booking_model.dart';
import '../providers/agency_provider.dart';

String bookingStatusLabel(String value) => value
    .replaceAll('_', ' ')
    .toLowerCase()
    .split(' ')
    .map((word) =>
        word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');
bool _isPending(String status) => status == 'PENDING';

class BookingListPage extends ConsumerStatefulWidget {
  const BookingListPage({super.key});
  @override
  ConsumerState<BookingListPage> createState() => _BookingListState();
}

class _BookingListState extends ConsumerState<BookingListPage> {
  String filter = 'ALL';
  String query = '';
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Bookings')),
        body: FutureBuilder<List<dynamic>>(
            future: ref.watch(agencyRepositoryProvider).getBookings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _Retry(
                    message: 'Unable to load booking requests',
                    onRetry: () => setState(() {}));
              }
              final bookings = (snapshot.data ?? [])
                  .map((item) => BookingModel.fromJson(
                      Map<String, dynamic>.from(item as Map)))
                  .where((b) =>
                      (filter == 'ALL' || b.status == filter) &&
                      (query.isEmpty ||
                          b.bookingNumber
                              .toLowerCase()
                              .contains(query.toLowerCase()) ||
                          b.packageName
                              .toLowerCase()
                              .contains(query.toLowerCase())))
                  .toList();
              return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView(padding: const EdgeInsets.all(20), children: [
                    TextField(
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Search loaded bookings'),
                        onChanged: (v) => setState(() => query = v)),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                        value: filter,
                        items: [
                          'ALL',
                          'PENDING',
                          'ACCEPTED',
                          'REJECTED',
                          'DRIVER_ASSIGNED',
                          'IN_TRANSIT',
                          'DELIVERED',
                          'CANCELLED'
                        ]
                            .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v == 'ALL'
                                    ? 'All statuses'
                                    : bookingStatusLabel(v))))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => filter = v);
                        }),
                    const SizedBox(height: 12),
                    if (bookings.isEmpty)
                      const _Empty(text: 'No booking requests found.')
                    else
                      ...bookings.map((booking) => _BookingCard(
                          booking: booking, onChanged: () => setState(() {})))
                  ]));
            }),
      );
}

class _BookingCard extends ConsumerStatefulWidget {
  final BookingModel booking;
  final VoidCallback onChanged;
  const _BookingCard({required this.booking, required this.onChanged});
  @override
  ConsumerState<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<_BookingCard> {
  bool submitting = false;
  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AgrizelCard(
            child: ListTile(
                isThreeLine: true,
                title: Text(b.bookingNumber.isEmpty
                    ? 'Booking request'
                    : b.bookingNumber),
                subtitle: Text(
                    '${b.packageName}\n${b.pickupAddress} → ${b.deliveryAddress}\n${b.totalAmount.isEmpty ? 'Amount unavailable' : 'Amount ${b.totalAmount}'}'),
                trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusBadge(b.status),
                      if (_isPending(b.status))
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                              tooltip: 'Accept',
                              onPressed:
                                  submitting ? null : () => _accept(context),
                              icon: const Icon(Icons.check,
                                  color: AppColors.success)),
                          IconButton(
                              tooltip: 'Reject',
                              onPressed:
                                  submitting ? null : () => _reject(context),
                              icon: const Icon(Icons.close,
                                  color: AppColors.error))
                        ])
                    ]),
                onTap: submitting
                    ? null
                    : () => context.push('/agency/bookings/${b.id}'))));
  }

  Future<void> _accept(BuildContext context) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Accept booking?'),
                content: Text('Accept ${widget.booking.bookingNumber}?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Accept'))
                ]));
    if (confirmed != true) return;
    setState(() => submitting = true);
    try {
      await ref.read(agencyRepositoryProvider).acceptBooking(widget.booking.id);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Booking accepted')));
      widget.onChanged();
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Booking changed or could not be accepted. Refresh and try again.')));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> _reject(BuildContext context) async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Reject booking?'),
                content: TextField(
                    controller: reason,
                    decoration:
                        const InputDecoration(labelText: 'Reason (optional)')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Reject'))
                ]));
    if (confirmed != true) {
      reason.dispose();
      return;
    }
    setState(() => submitting = true);
    try {
      await ref.read(agencyRepositoryProvider).rejectBooking(widget.booking.id,
          reason: reason.text.trim().isEmpty ? null : reason.text.trim());
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Booking rejected')));
      widget.onChanged();
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Booking changed or could not be rejected. Refresh and try again.')));
    } finally {
      reason.dispose();
      if (mounted) setState(() => submitting = false);
    }
  }
}

class BookingDetailsPage extends ConsumerStatefulWidget {
  final String id;
  const BookingDetailsPage({super.key, required this.id});
  @override
  ConsumerState<BookingDetailsPage> createState() => _BookingDetailsState();
}

class _BookingDetailsState extends ConsumerState<BookingDetailsPage> {
  bool mutating = false;
  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: ref.watch(agencyRepositoryProvider).getBooking(widget.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _loading(snapshot);
        final raw = snapshot.data as Map;
        if (raw.isEmpty) {
          return const Scaffold(
              body: Center(child: Text('Booking not found.')));
        }
        final b = BookingModel.fromJson(Map<String, dynamic>.from(raw));
        return Scaffold(
            appBar: AppBar(title: Text(b.bookingNumber)),
            body: ListView(padding: const EdgeInsets.all(24), children: [
              _info('Status', b.status),
              _info('Booking',
                  'Requested ${b.createdAt}\nPickup ${b.scheduledPickupAt}'),
              _info('Route', '${b.pickupAddress} → ${b.deliveryAddress}'),
              _info(
                  'Package',
                  b.packageName.isEmpty
                      ? 'Package information unavailable'
                      : b.packageName,
                  action: b.packageId.isEmpty
                      ? null
                      : () => context.push('/agency/packages/${b.packageId}')),
              _info('Cargo',
                  '${b.cargoType} • ${b.cargoWeightKg} kg\n${b.fragile ? 'Fragile' : 'Standard'} • ${b.requiresRefrigeration ? 'Refrigeration required' : 'No refrigeration requirement'}'),
              _info('Amount',
                  b.totalAmount.isEmpty ? 'Amount unavailable' : b.totalAmount),
              const _Notice(
                  'SLA deadline is not returned by the current BookingDto. Backend status remains authoritative.'),
              if (b.driverId.isNotEmpty)
                _info('Assigned driver', b.driverId,
                    action: () =>
                        context.push('/agency/drivers/${b.driverId}')),
              if (b.vehicleId.isNotEmpty)
                _info('Assigned vehicle', b.vehicleId,
                    action: () =>
                        context.push('/agency/vehicles/${b.vehicleId}')),
              BookingActionBar(
                  booking: b,
                  disabled: mutating,
                  onAccept: _accept,
                  onReject: _reject,
                  onAssign: () =>
                      context.push('/agency/bookings/${b.id}/assignment'))
            ]));
      });
  Future<void> _accept() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => mutating = true);
    try {
      await ref.read(agencyRepositoryProvider).acceptBooking(widget.id);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('Booking accepted')));
      setState(() {});
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(const SnackBar(
          content: Text(
              'Booking changed or could not be accepted. Refresh and try again.')));
    } finally {
      if (mounted) setState(() => mutating = false);
    }
  }

  Future<void> _reject() async {
    final reason = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Reject booking?'),
                content: TextField(
                    controller: reason,
                    decoration:
                        const InputDecoration(labelText: 'Reason (optional)')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Reject'))
                ]));
    if (confirmed != true) {
      reason.dispose();
      return;
    }
    setState(() => mutating = true);
    try {
      await ref.read(agencyRepositoryProvider).rejectBooking(widget.id,
          reason: reason.text.trim().isEmpty ? null : reason.text.trim());
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('Booking rejected')));
      setState(() {});
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(const SnackBar(
          content: Text('Booking changed or could not be rejected.')));
    } finally {
      reason.dispose();
      if (mounted) setState(() => mutating = false);
    }
  }
}

class BookingActionBar extends StatelessWidget {
  final BookingModel booking;
  final bool disabled;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onAssign;
  const BookingActionBar(
      {super.key,
      required this.booking,
      required this.disabled,
      required this.onAccept,
      required this.onReject,
      required this.onAssign});
  @override
  Widget build(BuildContext context) {
    if (booking.status == 'PENDING') {
      return Row(children: [
        Expanded(
            child: FilledButton(
                onPressed: disabled ? null : onAccept,
                child: const Text('Accept'))),
        const SizedBox(width: 10),
        Expanded(
            child: OutlinedButton(
                onPressed: disabled ? null : onReject,
                child: const Text('Reject')))
      ]);
    }
    if (booking.status == 'ACCEPTED') {
      return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
              onPressed: disabled ? null : onAssign,
              icon: const Icon(Icons.assignment_turned_in),
              label: const Text('Assign driver & vehicle')));
    }
    return const SizedBox.shrink();
  }
}

Widget _info(String title, String value, {VoidCallback? action}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: AgrizelCard(
        child: ListTile(
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(value.isEmpty ? '—' : value),
            trailing: action == null
                ? null
                : IconButton(
                    onPressed: action,
                    icon: const Icon(Icons.arrow_forward)))));

class _StatusBadge extends StatelessWidget {
  final String value;
  const _StatusBadge(this.value);
  @override
  Widget build(BuildContext context) =>
      Chip(label: Text(bookingStatusLabel(value)));
}

class _Notice extends StatelessWidget {
  final String text;
  const _Notice(this.text);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(12)),
      child:
          Text(text, style: const TextStyle(color: AppColors.textSecondary)));
}

Widget _loading(AsyncSnapshot snapshot) => Scaffold(
    body: Center(
        child: snapshot.hasError
            ? const Text('Unable to load booking.')
            : const CircularProgressIndicator()));

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(40), child: Center(child: Text(text)));
}

class _Retry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _Retry({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(message),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry'))
      ]));
}
