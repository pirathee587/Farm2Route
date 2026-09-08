import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../data/assignment_recommendation_model.dart';
import '../../data/booking_model.dart';
import '../../data/driver_model.dart';
import '../../data/vehicle_model.dart';
import '../providers/agency_provider.dart';

class AssignmentPage extends ConsumerStatefulWidget {
  final String bookingId;
  const AssignmentPage({super.key, required this.bookingId});
  @override
  ConsumerState<AssignmentPage> createState() => _AssignmentState();
}

class _AssignmentState extends ConsumerState<AssignmentPage> {
  DriverModel? driver;
  VehicleModel? vehicle;
  bool submitting = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ref.watch(agencyRepositoryProvider).getBooking(widget.bookingId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _loading(snapshot);
        }
        final raw = snapshot.data as Map;
        if (raw.isEmpty) {
          return const Scaffold(
              body: Center(child: Text('Booking not found.')));
        }
        final booking = BookingModel.fromJson(Map<String, dynamic>.from(raw));
        if (booking.status != 'ACCEPTED') {
          return Scaffold(
            appBar: AppBar(title: const Text('Assignment')),
            body: Center(
                child: Text(
                    'This booking is ${booking.status.toLowerCase().replaceAll('_', ' ')} and is not assignable.')),
          );
        }
        final recommendation =
            ref.watch(assignmentRecommendationProvider(widget.bookingId));
        return Scaffold(
          appBar: AppBar(title: const Text('Smart assignment')),
          body: recommendation.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _RetryRecommendation(
                onRetry: () => ref.invalidate(
                    assignmentRecommendationProvider(widget.bookingId))),
            data: (value) => _resources(
                context,
                booking,
                AssignmentRecommendationModel.fromJson(
                    Map<String, dynamic>.from(value as Map))),
          ),
        );
      },
    );
  }

  Widget _resources(BuildContext context, BookingModel booking,
      AssignmentRecommendationModel recommendation) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([
        ref.read(agencyRepositoryProvider).getAvailableDrivers(),
        ref.read(agencyRepositoryProvider).getVehicles(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _RetryRecommendation(onRetry: () => setState(() {}));
        }
        final drivers = (snapshot.data![0] as List)
            .map((x) =>
                DriverModel.fromJson(Map<String, dynamic>.from(x as Map)))
            .where((x) =>
                x.kycStatus == 'APPROVED' || x.kycStatus == 'PENDING_APPROVAL')
            .toList();
        final vehicles = (snapshot.data![1] as List)
            .map((x) =>
                VehicleModel.fromJson(Map<String, dynamic>.from(x as Map)))
            .where((x) =>
                (x.kycStatus == 'APPROVED' ||
                    x.kycStatus == 'PENDING_APPROVAL') &&
                x.status == 'AVAILABLE')
            .toList();
        return _assignmentList(
            context, booking, recommendation, drivers, vehicles);
      },
    );
  }

  Widget _assignmentList(
      BuildContext context,
      BookingModel booking,
      AssignmentRecommendationModel recommendation,
      List<DriverModel> drivers,
      List<VehicleModel> vehicles) {
    final recommendationReady = recommendation.recommendedDriverId != null &&
        recommendation.recommendedVehicleId != null;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Review assignment', style: AppTextStyles.headingLarge),
        const SizedBox(height: 6),
        const _Notice(
            'Backend eligibility and assignment validation remain authoritative.'),
        _section('Booking', [
          _info('Reference', booking.bookingNumber),
          _info(
              'Route', '${booking.pickupAddress} → ${booking.deliveryAddress}'),
          _info('Package', booking.packageName),
          _info('Pickup', booking.scheduledPickupAt),
          _info('Cargo', '${booking.cargoType} • ${booking.cargoWeightKg} kg'),
        ]),
        _section('Recommended driver', [
          _info('Name', recommendation.recommendedDriverName ?? 'Unavailable'),
          _info('Availability',
              recommendation.recommendedDriverAvailability ?? 'Unavailable'),
          _info(
              'Rating',
              recommendation.recommendedDriverRating?.toStringAsFixed(1) ??
                  'Unavailable'),
          _info('Rationale', recommendation.rationale ?? 'Unavailable'),
        ]),
        _section('Recommended vehicle', [
          _info(
              'Registration',
              recommendation.recommendedVehicleRegistrationNumber ??
                  'Unavailable'),
          _info('Make/model',
              recommendation.recommendedVehicleMakeAndModel ?? 'Unavailable'),
          _info('Type', recommendation.recommendedVehicleType ?? 'Unavailable'),
          _info('Capacity',
              recommendation.recommendedVehicleCapacity ?? 'Unavailable'),
        ]),
        if (recommendationReady)
          FilledButton.icon(
            onPressed: submitting
                ? null
                : () => _confirm(
                    context,
                    booking,
                    recommendation.recommendedDriverId!,
                    recommendation.recommendedVehicleId!,
                    false),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Accept recommendation'),
          ),
        const SizedBox(height: 16),
        _section('Manual override', [
          const Text(
              'Resources below come from agency APIs. The backend revalidates them before assignment.'),
          const SizedBox(height: 12),
          DropdownButtonFormField<DriverModel>(
            initialValue: driver,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Driver'),
            items: drivers
                .map((x) => DropdownMenuItem(
                    value: x,
                    child: Text('${x.fullName} • ${x.availabilityStatus}')))
                .toList(),
            onChanged:
                submitting ? null : (value) => setState(() => driver = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<VehicleModel>(
            initialValue: vehicle,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Vehicle'),
            items: vehicles
                .map((x) => DropdownMenuItem(
                    value: x,
                    child: Text('${x.registrationNumber} • ${x.vehicleType}')))
                .toList(),
            onChanged:
                submitting ? null : (value) => setState(() => vehicle = value),
          ),
          const SizedBox(height: 12),
          SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                  onPressed: submitting || driver == null || vehicle == null
                      ? null
                      : () => _confirm(
                          context, booking, driver!.id, vehicle!.id, true),
                  child: const Text('Review manual assignment'))),
        ]),
        const _Notice(
            'Driver distance and proximity are not shown because reliable driver location is unavailable from the backend.'),
      ],
    );
  }

  Future<void> _confirm(BuildContext context, BookingModel booking,
      String driverId, String vehicleId, bool override) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final driverLabel = driver?.fullName ?? 'Recommended driver';
    final vehicleLabel = vehicle?.registrationNumber ?? 'Recommended vehicle';
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const Text('Confirm assignment'),
                content: Text(
                    'Booking: ${booking.bookingNumber}\nDriver: $driverLabel\nVehicle: $vehicleLabel\n\n${override ? 'Manual override selected.' : 'Backend recommendation selected.'}\n\nConfirm assignment?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Confirm'))
                ]));
    if (confirmed != true) return;
    setState(() => submitting = true);
    try {
      await ref
          .read(agencyRepositoryProvider)
          .assignBooking(widget.bookingId, driverId, vehicleId);
      ref.invalidate(assignmentRecommendationProvider(widget.bookingId));
      if (mounted) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Assignment confirmed')));
        router.go('/agency/bookings/${widget.bookingId}');
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(const SnackBar(
            content: Text(
                'Assignment conflict: the booking or selected resource changed. Refresh and retry.')));
      }
      ref.invalidate(assignmentRecommendationProvider(widget.bookingId));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }
}

Widget _section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: AgrizelCard(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppTextStyles.headingSmall),
              const SizedBox(height: 10),
              ...children
            ]))));
Widget _info(String title, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
          width: 110,
          child:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
      Expanded(child: Text(value.isEmpty ? 'Unavailable' : value))
    ]));
Widget _loading(AsyncSnapshot snapshot) => Scaffold(
    body: Center(
        child: snapshot.hasError
            ? const Text('Unable to load booking.')
            : const CircularProgressIndicator()));

class _RetryRecommendation extends StatelessWidget {
  final VoidCallback onRetry;
  const _RetryRecommendation({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('Recommendation unavailable.'),
        const SizedBox(height: 8),
        const Text('No eligible recommendation may be available yet.'),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry'))
      ]));
}

class _Notice extends StatelessWidget {
  final String text;
  const _Notice(this.text);
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(12)),
      child:
          Text(text, style: const TextStyle(color: AppColors.textSecondary)));
}
