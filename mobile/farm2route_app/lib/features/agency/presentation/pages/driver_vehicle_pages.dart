import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../data/driver_model.dart';
import '../../data/vehicle_model.dart';
import '../providers/agency_provider.dart';

String _pretty(String value) => value
    .replaceAll('_', ' ')
    .toLowerCase()
    .split(' ')
    .map((x) => x.isEmpty ? x : '${x[0].toUpperCase()}${x.substring(1)}')
    .join(' ');

class _Badge extends StatelessWidget {
  final String value;
  const _Badge(this.value);
  @override
  Widget build(BuildContext context) => Chip(
      label: Text(_pretty(value), style: const TextStyle(fontSize: 12)),
      backgroundColor: value.contains('APPROVED') || value == 'AVAILABLE'
          ? AppColors.primaryLight
          : AppColors.surfaceSubtle);
}

class DriverListPage extends ConsumerStatefulWidget {
  const DriverListPage({super.key});
  @override
  ConsumerState<DriverListPage> createState() => _DriverListPageState();
}

class _DriverListPageState extends ConsumerState<DriverListPage> {
  String query = '';
  String kyc = 'ALL';
  String availability = 'ALL';
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Drivers'), actions: [
        IconButton(
            onPressed: () => context.push('/agency/drivers/new'),
            icon: const Icon(Icons.add))
      ]),
      body: FutureBuilder<List<dynamic>>(
          future: ref.watch(agencyRepositoryProvider).getDrivers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _Retry(
                  message: 'Unable to load drivers',
                  onRetry: () => setState(() {}));
            }
            final all = (snapshot.data ?? [])
                .map((x) =>
                    DriverModel.fromJson(Map<String, dynamic>.from(x as Map)))
                .toList();
            final items = all
                .where((d) =>
                    (query.isEmpty ||
                        d.fullName
                            .toLowerCase()
                            .contains(query.toLowerCase()) ||
                        d.drivingLicenseNumber
                            .toLowerCase()
                            .contains(query.toLowerCase())) &&
                    (kyc == 'ALL' || d.kycStatus == kyc) &&
                    (availability == 'ALL' ||
                        d.availabilityStatus == availability))
                .toList();
            return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  TextField(
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search loaded drivers'),
                      onChanged: (v) => setState(() => query = v)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, children: [
                    _filter(
                        'KYC',
                        kyc,
                        [
                          'ALL',
                          'PENDING',
                          'PENDING_APPROVAL',
                          'APPROVED',
                          'REJECTED'
                        ],
                        (v) => setState(() => kyc = v)),
                    _filter(
                        'Availability',
                        availability,
                        ['ALL', 'AVAILABLE', 'ON_TRIP', 'OFF_DUTY', 'INACTIVE'],
                        (v) => setState(() => availability = v))
                  ]),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    const _Empty(text: 'No drivers registered yet.')
                  else
                    ...items.map((d) => _driverCard(context, d))
                ]));
          }));
  Widget _filter(String label, String selected, List<String> values,
          ValueChanged<String> onChanged) =>
      DropdownButton<String>(
          value: selected,
          underline: const SizedBox(),
          hint: Text(label),
          items: values
              .map((v) => DropdownMenuItem(
                  value: v, child: Text(v == 'ALL' ? label : _pretty(v))))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          });
  Widget _driverCard(BuildContext context, DriverModel d) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AgrizelCard(
          child: ListTile(
              isThreeLine: true,
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(d.fullName.isEmpty ? 'Unnamed driver' : d.fullName),
              subtitle: Text(
                  '${d.drivingLicenseNumber}\n${d.phoneNumber} • ${d.ratingAverage?.toStringAsFixed(1) ?? '—'} rating'),
              trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Badge(d.kycStatus),
                    Text(_pretty(d.availabilityStatus),
                        style: const TextStyle(fontSize: 11))
                  ]),
              onTap: () => context.push('/agency/drivers/${d.id}'))));
}

class VehicleListPage extends ConsumerStatefulWidget {
  const VehicleListPage({super.key});
  @override
  ConsumerState<VehicleListPage> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends ConsumerState<VehicleListPage> {
  String query = '';
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Vehicles'), actions: [
        IconButton(
            onPressed: () => context.push('/agency/vehicles/new'),
            icon: const Icon(Icons.add))
      ]),
      body: FutureBuilder<List<dynamic>>(
          future: ref.watch(agencyRepositoryProvider).getVehicles(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _Retry(
                  message: 'Unable to load vehicles',
                  onRetry: () => setState(() {}));
            }
            final items = (snapshot.data ?? [])
                .map((x) =>
                    VehicleModel.fromJson(Map<String, dynamic>.from(x as Map)))
                .where((v) =>
                    query.isEmpty ||
                    v.registrationNumber
                        .toLowerCase()
                        .contains(query.toLowerCase()) ||
                    v.makeAndModel.toLowerCase().contains(query.toLowerCase()))
                .toList();
            return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  TextField(
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search loaded vehicles'),
                      onChanged: (v) => setState(() => query = v)),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    const _Empty(text: 'No vehicles registered yet.')
                  else
                    ...items.map((v) => _vehicleCard(context, v))
                ]));
          }));
  Widget _vehicleCard(BuildContext context, VehicleModel v) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AgrizelCard(
          child: ListTile(
              isThreeLine: true,
              leading:
                  const Icon(Icons.local_shipping, color: AppColors.primary),
              title: Text(v.registrationNumber),
              subtitle: Text(
                  '${v.makeAndModel} • ${_pretty(v.vehicleType)}\n${v.capacity ?? '—'} kg • ${v.cargoVolumeCbm ?? '—'} CBM • ${v.refrigerated ? 'Refrigerated' : 'Standard'}'),
              trailing: _Badge(v.status),
              onTap: () => context.push('/agency/vehicles/${v.id}'))));
}

class DriverDetailsPage extends ConsumerWidget {
  final String id;
  const DriverDetailsPage({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder(
      future: ref.watch(agencyRepositoryProvider).getDriver(id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _loadingOrError(snapshot, 'Unable to load driver');
        }
        final d = DriverModel.fromJson(
            Map<String, dynamic>.from(snapshot.data as Map));
        return _DetailsScaffold(title: d.fullName, actions: [
          IconButton(
              onPressed: () => context.push('/agency/drivers/$id/edit'),
              icon: const Icon(Icons.edit))
        ], children: [
          _info('Contact', '${d.phoneNumber}\n${d.email}'),
          _info('Licence',
              '${d.drivingLicenseNumber}\nExpires ${d.licenseExpiryDate}'),
          _info('NIC', d.nicNumber),
          Row(children: [
            _Badge(d.kycStatus),
            const SizedBox(width: 8),
            _Badge(d.availabilityStatus)
          ]),
          _info('Rating',
              '${d.ratingAverage?.toStringAsFixed(1) ?? 'No rating'} (${d.totalRatingsCount} reviews)'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: () => context.push('/agency/drivers/$id/documents'),
              icon: const Icon(Icons.description),
              label: const Text('Documents')),
          OutlinedButton.icon(
              onPressed: () => context.push('/agency/drivers/$id/reviews'),
              icon: const Icon(Icons.star_outline),
              label: const Text('View reviews')),
          const SizedBox(height: 12),
          _DeleteButton(
              label: d.fullName,
              onDelete: () async {
                await ref.read(agencyRepositoryProvider).deleteDriver(id);
                if (context.mounted) context.pop();
              })
        ]);
      });
}

class VehicleDetailsPage extends ConsumerWidget {
  final String id;
  const VehicleDetailsPage({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder(
      future: ref.watch(agencyRepositoryProvider).getVehicle(id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _loadingOrError(snapshot, 'Unable to load vehicle');
        }
        final v = VehicleModel.fromJson(
            Map<String, dynamic>.from(snapshot.data as Map));
        return _DetailsScaffold(title: v.registrationNumber, actions: [
          IconButton(
              onPressed: () => context.push('/agency/vehicles/$id/edit'),
              icon: const Icon(Icons.edit))
        ], children: [
          _info('Vehicle', '${v.makeAndModel}\n${_pretty(v.vehicleType)}'),
          _info('Capacity',
              '${v.capacity ?? '—'} kg • ${v.cargoVolumeCbm ?? '—'} CBM'),
          _info('Configuration', v.refrigerated ? 'Refrigerated' : 'Standard'),
          Row(children: [
            _Badge(v.kycStatus),
            const SizedBox(width: 8),
            _Badge(v.status)
          ]),
          _info('Insurance',
              '${v.insurancePolicyNumber}\nExpires ${v.insuranceExpiryDate}'),
          _info('Revenue licence',
              '${v.revenueLicenseNumber}\nExpires ${v.revenueLicenseExpiryDate}'),
          OutlinedButton.icon(
              onPressed: () => context.push('/agency/vehicles/$id/kyc'),
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('View KYC')),
          OutlinedButton.icon(
              onPressed: () => context.go('/agency/vehicles/$id/maintenance'),
              icon: const Icon(Icons.build_circle_outlined),
              label: const Text('View maintenance')),
          const SizedBox(height: 12),
          const _Notice('Vehicle document upload is not currently available.'),
          _DeleteButton(
              label: v.registrationNumber,
              onDelete: () async {
                await ref.read(agencyRepositoryProvider).deleteVehicle(id);
                if (context.mounted) context.pop();
              })
        ]);
      });
}

class DriverFormPage extends ConsumerStatefulWidget {
  final String? id;
  const DriverFormPage({super.key, this.id});
  @override
  ConsumerState<DriverFormPage> createState() => _DriverFormState();
}

class _DriverFormState extends ConsumerState<DriverFormPage> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{
    for (final x in [
      'fullName',
      'phoneNumber',
      'email',
      'drivingLicenseNumber',
      'licenseExpiryDate',
      'nicNumber'
    ])
      x: TextEditingController()
  };
  bool loading = false;
  bool loaded = false;
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.id != null && !loaded) {
      return FutureBuilder(
          future: ref.read(agencyRepositoryProvider).getDriver(widget.id!),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _loadingOrError(snapshot, 'Unable to load driver');
            }
            final m = Map<String, dynamic>.from(snapshot.data as Map);
            for (final k in fields.keys) {
              fields[k]!.text = '${m[k] ?? ''}';
            }
            fields['drivingLicenseNumber']!.text =
                '${m['drivingLicenseNumber'] ?? ''}';
            fields['licenseExpiryDate']!.text =
                '${m['licenseExpiryDate'] ?? ''}';
            loaded = true;
            return _form(context);
          });
    }
    return _form(context);
  }

  Widget _form(BuildContext context) => Scaffold(
      appBar:
          AppBar(title: Text(widget.id == null ? 'Add driver' : 'Edit driver')),
      body: Form(
          key: form,
          child: ListView(padding: const EdgeInsets.all(24), children: [
            Text('Personal information', style: AppTextStyles.headingSmall),
            _field('fullName', 'Full name'),
            _field('phoneNumber', 'Phone number'),
            _field('email', 'Email', required: false),
            const SizedBox(height: 12),
            Text('Licence and identity', style: AppTextStyles.headingSmall),
            _field('drivingLicenseNumber', 'Driving licence number'),
            _field('licenseExpiryDate', 'Licence expiry (YYYY-MM-DD)'),
            _field('nicNumber', 'NIC number'),
            const SizedBox(height: 12),
            const _Notice(
                'New drivers are submitted for administrative KYC review. Approval controls are not available to agencies.'),
            const SizedBox(height: 18),
            FilledButton(
                onPressed: loading ? null : _submit,
                child: Text(loading
                    ? 'Saving…'
                    : widget.id == null
                        ? 'Register driver'
                        : 'Save changes'))
          ])));
  Widget _field(String key, String label, {bool required = true}) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
          controller: fields[key],
          decoration: InputDecoration(labelText: label),
          validator: required
              ? (v) =>
                  v == null || v.trim().isEmpty ? '$label is required' : null
              : null));
  Future<void> _submit() async {
    if (!form.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      final body = <String, dynamic>{
        for (final e in fields.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim()
      };
      if (widget.id != null) {
        body.remove('email');
        body.remove('phoneNumber');
      }
      final result = widget.id == null
          ? await ref.read(agencyRepositoryProvider).createDriver(body)
          : await ref
              .read(agencyRepositoryProvider)
              .updateDriver(widget.id!, body);
      if (mounted) {
        final id = '${(result as Map)['id'] ?? widget.id ?? ''}';
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Driver saved')));
        context.go('/agency/drivers/$id');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Unable to save driver: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

class VehicleFormPage extends ConsumerStatefulWidget {
  final String? id;
  const VehicleFormPage({super.key, this.id});
  @override
  ConsumerState<VehicleFormPage> createState() => _VehicleFormState();
}

class _VehicleFormState extends ConsumerState<VehicleFormPage> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{
    for (final x in [
      'registrationNumber',
      'makeAndModel',
      'vehicleType',
      'capacity',
      'cargoVolumeCbm',
      'insurancePolicyNumber',
      'insuranceExpiryDate',
      'revenueLicenseNumber',
      'revenueLicenseExpiryDate'
    ])
      x: TextEditingController()
  };
  bool refrigerated = false;
  bool loading = false;
  bool loaded = false;
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.id != null && !loaded) {
      return FutureBuilder(
          future: ref.read(agencyRepositoryProvider).getVehicle(widget.id!),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _loadingOrError(snapshot, 'Unable to load vehicle');
            }
            final m = Map<String, dynamic>.from(snapshot.data as Map);
            for (final k in fields.keys) {
              fields[k]!.text = '${m[k] ?? ''}';
            }
            refrigerated =
                m['refrigerated'] == true || m['isRefrigerated'] == true;
            loaded = true;
            return _form(context);
          });
    }
    return _form(context);
  }

  Widget _form(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(widget.id == null ? 'Add vehicle' : 'Edit vehicle')),
      body: Form(
          key: form,
          child: ListView(padding: const EdgeInsets.all(24), children: [
            _field('registrationNumber', 'Registration number'),
            _field('makeAndModel', 'Make and model'),
            _field('vehicleType', 'Vehicle type (e.g. TRUCK)'),
            _field('capacity', 'Maximum weight (kg)', number: true),
            _field('cargoVolumeCbm', 'Cargo volume (CBM)', number: true),
            SwitchListTile(
                title: const Text('Refrigerated'),
                value: refrigerated,
                onChanged: (v) => setState(() => refrigerated = v)),
            const SizedBox(height: 12),
            Text('Insurance and licences', style: AppTextStyles.headingSmall),
            _field('insurancePolicyNumber', 'Insurance policy',
                required: false),
            _field('insuranceExpiryDate', 'Insurance expiry (YYYY-MM-DD)'),
            _field('revenueLicenseNumber', 'Revenue licence', required: false),
            _field('revenueLicenseExpiryDate',
                'Revenue licence expiry (YYYY-MM-DD)'),
            const SizedBox(height: 18),
            FilledButton(
                onPressed: loading ? null : _submit,
                child: Text(loading
                    ? 'Saving…'
                    : widget.id == null
                        ? 'Register vehicle'
                        : 'Save changes'))
          ])));
  Widget _field(String key, String label,
          {bool required = true, bool number = false}) =>
      Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextFormField(
              controller: fields[key],
              keyboardType: number
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              decoration: InputDecoration(labelText: label),
              validator: required
                  ? (v) {
                      if (v == null || v.trim().isEmpty) {
                        return '$label is required';
                      }
                      if (number && double.tryParse(v) == null) {
                        return 'Enter a valid positive number';
                      }
                      if (number && double.parse(v) <= 0) {
                        return 'Must be positive';
                      }
                      return null;
                    }
                  : null));
  Future<void> _submit() async {
    if (!form.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      final body = <String, dynamic>{
        for (final e in fields.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
        'isRefrigerated': refrigerated
      };
      final result = widget.id == null
          ? await ref.read(agencyRepositoryProvider).createVehicle(body)
          : await ref
              .read(agencyRepositoryProvider)
              .updateVehicle(widget.id!, body);
      if (mounted) {
        final id = '${(result as Map)['id'] ?? widget.id ?? ''}';
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Vehicle saved')));
        context.go('/agency/vehicles/$id');
      }
    } catch (e) {
      if (mounted) {
        final message = switch (e) {
          AppException(:final statusCode) when statusCode == 400 =>
            'Please check the vehicle details and try again.',
          AppException(:final statusCode) when statusCode == 403 =>
            'You are not authorized to manage vehicles for this agency.',
          AppException(:final statusCode) when statusCode == 409 =>
            'A vehicle with this registration number already exists.',
          AppException(:final statusCode)
              when statusCode != null && statusCode >= 500 =>
            'The vehicle could not be saved because of a server error. Please try again.',
          AppException() => e.message,
          _ =>
            'Unable to save the vehicle. Please check your connection and try again.',
        };
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

class VehicleKycPage extends ConsumerWidget {
  final String id;
  const VehicleKycPage({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder(
      future: ref.watch(agencyRepositoryProvider).getVehicleKyc(id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _loadingOrError(snapshot, 'Unable to load vehicle KYC');
        }
        final value = snapshot.data is Map
            ? Map<String, dynamic>.from(snapshot.data as Map)
            : {'status': snapshot.data};
        return _DetailsScaffold(title: 'Vehicle KYC', children: [
          _Badge('${value['status'] ?? value['kycStatus'] ?? 'PENDING'}'),
          const SizedBox(height: 16),
          const _Notice(
              'This screen shows submission status only. Administrative approval, rejection, and suspension are not available to agencies.'),
          const _Notice('Vehicle document upload is not currently available.')
        ]);
      });
}

class DriverDocumentsPage extends ConsumerWidget {
  final String id;
  const DriverDocumentsPage({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder<dynamic>(
      future: ref.watch(agencyRepositoryProvider).getDriverDocument(id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _loadingOrError(snapshot, 'Unable to load driver document');
        }
        final url = '${snapshot.data ?? ''}'.trim();
        return _DetailsScaffold(title: 'Driver documents', children: [
          if (url.isEmpty)
            const _Notice('No driver KYC document is currently available.')
          else ...[
            const _Notice('A secure document URL was returned by the backend.'),
            SelectableText(url),
          ],
          const _Notice(
              'Document upload is not included because the current app dependencies do not provide a multipart file picker.')
        ]);
      });
}

class DriverReviewsPage extends ConsumerWidget {
  final String id;
  const DriverReviewsPage({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      FutureBuilder<List<dynamic>>(
          future: ref.watch(agencyRepositoryProvider).getDriverReviews(id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _loadingOrError(snapshot, 'Unable to load reviews');
            }
            final items = snapshot.data!;
            return _DetailsScaffold(title: 'Driver reviews', children: [
              if (items.isEmpty)
                const _Empty(text: 'No driver reviews yet.')
              else
                ...items.map((x) {
                  final m = Map<String, dynamic>.from(x as Map);
                  return AgrizelCard(
                      child: ListTile(
                          leading: const Icon(Icons.star,
                              color: AppColors.starAmber),
                          title: Text('${m['rating'] ?? '—'} / 5'),
                          subtitle: Text(
                              '${m['comment'] ?? m['review'] ?? ''}\n${m['bookingReference'] ?? ''} • ${m['createdAt'] ?? ''}')));
                })
            ]);
          });
}

class _DetailsScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  const _DetailsScaffold(
      {required this.title, required this.children, this.actions});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: ListView(
          padding: const EdgeInsets.all(24),
          children: children
              .map((x) =>
                  Padding(padding: const EdgeInsets.only(bottom: 12), child: x))
              .toList()));
}

Widget _info(String title, String value) => AgrizelCard(
    child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value.isEmpty ? '—' : value)));
Widget _loadingOrError(AsyncSnapshot snapshot, String message) => Scaffold(
    body: Center(
        child: snapshot.hasError
            ? _Retry(message: message, onRetry: () {})
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

class _DeleteButton extends StatelessWidget {
  final String label;
  final Future<void> Function() onDelete;
  const _DeleteButton({required this.label, required this.onDelete});
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
      onPressed: () async {
        final ok = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
                    title: const Text('Delete record?'),
                    content: Text('Delete $label? This cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Delete'))
                    ]));
        if (ok == true && context.mounted) {
          await onDelete();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Deleted')));
        }
      },
      icon: const Icon(Icons.delete_outline, color: AppColors.error),
      label: const Text('Delete'));
}
