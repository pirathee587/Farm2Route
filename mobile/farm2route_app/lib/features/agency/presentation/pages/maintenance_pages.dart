import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../data/maintenance_model.dart';
import '../providers/agency_provider.dart';

const _maintenanceStatuses = [
  'SCHEDULED',
  'IN_PROGRESS',
  'COMPLETED',
  'CANCELLED'
];
String maintenanceStatusLabel(String value) => value
    .replaceAll('_', ' ')
    .toLowerCase()
    .split(' ')
    .map((x) => x.isEmpty ? x : '${x[0].toUpperCase()}${x.substring(1)}')
    .join(' ');

class MaintenanceOverviewPage extends ConsumerWidget {
  const MaintenanceOverviewPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      FutureBuilder<List<dynamic>>(
          future: ref.watch(agencyRepositoryProvider).maintenance(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(
                  child: Text('Unable to load active maintenance records.'));
            }
            final records = (snapshot.data ?? [])
                .map((x) => MaintenanceModel.fromJson(
                    Map<String, dynamic>.from(x as Map)))
                .toList();
            return Scaffold(
                appBar: AppBar(title: const Text('Maintenance')),
                body: records.isEmpty
                    ? const _Empty(text: 'No active maintenance records.')
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: records
                            .map((x) => _MaintenanceCard(record: x))
                            .toList()));
          });
}

class VehicleMaintenancePage extends ConsumerStatefulWidget {
  final String vehicleId;
  const VehicleMaintenancePage({super.key, required this.vehicleId});
  @override
  ConsumerState<VehicleMaintenancePage> createState() =>
      _VehicleMaintenanceState();
}

class _VehicleMaintenanceState extends ConsumerState<VehicleMaintenancePage> {
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Maintenance history'), actions: [
        IconButton(
            onPressed: () => context
                .push('/agency/vehicles/${widget.vehicleId}/maintenance/new'),
            icon: const Icon(Icons.add))
      ]),
      body: FutureBuilder<List<dynamic>>(
          future: ref
              .watch(agencyRepositoryProvider)
              .getVehicleMaintenance(widget.vehicleId),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _Retry(onRetry: () => setState(() {}));
            }
            final records = (snapshot.data ?? [])
                .map((x) => MaintenanceModel.fromJson(
                    Map<String, dynamic>.from(x as Map)))
                .toList();
            return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  if (records.isEmpty)
                    const _Empty(
                        text: 'No maintenance records for this vehicle.')
                  else
                    ...records.map((x) => _MaintenanceCard(
                        record: x, vehicleId: widget.vehicleId))
                ]));
          }));
}

class _MaintenanceCard extends StatelessWidget {
  final MaintenanceModel record;
  final String? vehicleId;
  const _MaintenanceCard({required this.record, this.vehicleId});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AgrizelCard(
          child: ListTile(
              isThreeLine: true,
              leading: const Icon(Icons.build_circle_outlined,
                  color: AppColors.primary),
              title: Text(
                  record.title.isEmpty ? record.maintenanceType : record.title),
              subtitle: Text(
                  '${record.maintenanceDate}${record.nextDueDate.isEmpty ? '' : ' → next due ${record.nextDueDate}'}\n${record.serviceCenterName.isEmpty ? 'Service center unavailable' : record.serviceCenterName}'),
              trailing:
                  Chip(label: Text(maintenanceStatusLabel(record.status))),
              onTap: vehicleId == null
                  ? null
                  : () => context.push(
                      '/agency/vehicles/$vehicleId/maintenance/${record.id}'))));
}

class MaintenanceDetailsPage extends ConsumerWidget {
  final String vehicleId;
  final String maintenanceId;
  const MaintenanceDetailsPage(
      {super.key, required this.vehicleId, required this.maintenanceId});
  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder<
          List<dynamic>>(
      future:
          ref.watch(agencyRepositoryProvider).getVehicleMaintenance(vehicleId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _loading(snapshot);
        final matches = snapshot.data!
            .map((x) =>
                MaintenanceModel.fromJson(Map<String, dynamic>.from(x as Map)))
            .where((x) => x.id == maintenanceId)
            .toList();
        if (matches.isEmpty) {
          return const Scaffold(
              body: Center(child: Text('Maintenance record not found.')));
        }
        final record = matches.first;
        return Scaffold(
            appBar: AppBar(title: Text(record.title), actions: [
              IconButton(
                  onPressed: () => context.push(
                      '/agency/vehicles/$vehicleId/maintenance/$maintenanceId/edit'),
                  icon: const Icon(Icons.edit))
            ]),
            body: ListView(padding: const EdgeInsets.all(24), children: [
              _info('Status', maintenanceStatusLabel(record.status)),
              _info('Type', record.maintenanceType),
              _info('Title', record.title),
              _info('Description', record.description),
              _info('Cost', record.cost),
              _info('Service date', record.maintenanceDate),
              _info('Next due date', record.nextDueDate),
              _info('Service center', record.serviceCenterName),
              _info('Created', record.createdAt),
              _info('Updated', record.updatedAt),
              const _Notice(
                  'Vehicle availability and assignment readiness are returned by the backend vehicle state. This page does not change them locally.')
            ]));
      });
}

class MaintenanceFormPage extends ConsumerStatefulWidget {
  final String vehicleId;
  final String? maintenanceId;
  const MaintenanceFormPage(
      {super.key, required this.vehicleId, this.maintenanceId});
  @override
  ConsumerState<MaintenanceFormPage> createState() => _MaintenanceFormState();
}

class _MaintenanceFormState extends ConsumerState<MaintenanceFormPage> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{
    for (final key in [
      'maintenanceType',
      'title',
      'description',
      'cost',
      'maintenanceDate',
      'nextDueDate',
      'serviceCenterName',
      'invoiceDocumentUrl'
    ])
      key: TextEditingController()
  };
  String status = 'SCHEDULED';
  bool saving = false;
  bool loaded = false;
  @override
  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.maintenanceId != null && !loaded) {
      return FutureBuilder<List<dynamic>>(
          future: ref
              .read(agencyRepositoryProvider)
              .getVehicleMaintenance(widget.vehicleId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return _loading(snapshot);
            final matches = snapshot.data!
                .map((x) => Map<String, dynamic>.from(x as Map))
                .where((x) => '${x['id']}' == widget.maintenanceId)
                .toList();
            if (matches.isEmpty) {
              return const Scaffold(
                  body: Center(child: Text('Maintenance record not found.')));
            }
            _fill(matches.first);
            return _form(context);
          });
    }
    return _form(context);
  }

  void _fill(Map<String, dynamic> data) {
    for (final key in fields.keys) {
      fields[key]!.text = '${data[key] ?? ''}';
    }
    status = '${data['status'] ?? 'SCHEDULED'}';
    loaded = true;
  }

  Widget _form(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(widget.maintenanceId == null
              ? 'Add maintenance'
              : 'Edit maintenance')),
      body: Form(
          key: form,
          child: ListView(padding: const EdgeInsets.all(24), children: [
            _field('maintenanceType', 'Maintenance type'),
            _field('title', 'Title'),
            _field('description', 'Description', required: false, maxLines: 3),
            _field('cost', 'Cost', decimal: true),
            _field('maintenanceDate', 'Maintenance date (YYYY-MM-DD)'),
            _field('nextDueDate', 'Next due date (YYYY-MM-DD)',
                required: false),
            _field('serviceCenterName', 'Service center', required: false),
            _field('invoiceDocumentUrl', 'Invoice document URL',
                required: false),
            DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _maintenanceStatuses
                    .map((x) => DropdownMenuItem(
                        value: x, child: Text(maintenanceStatusLabel(x))))
                    .toList(),
                onChanged: widget.maintenanceId == null
                    ? null
                    : (x) {
                        if (x != null) setState(() => status = x);
                      }),
            const SizedBox(height: 20),
            FilledButton(
                onPressed: saving ? null : _submit,
                child: Text(saving
                    ? 'Saving…'
                    : widget.maintenanceId == null
                        ? 'Create maintenance'
                        : 'Save changes'))
          ])));
  Widget _field(String key, String label,
          {bool required = true, bool decimal = false, int maxLines = 1}) =>
      Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextFormField(
              controller: fields[key],
              maxLines: maxLines,
              keyboardType: decimal
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              decoration: InputDecoration(labelText: label),
              validator: (value) {
                if (required && (value == null || value.trim().isEmpty)) {
                  return '$label is required';
                }
                if (decimal &&
                    value != null &&
                    (double.tryParse(value) == null ||
                        double.parse(value) < 0)) {
                  return 'Enter a valid non-negative amount';
                }
                return null;
              }));
  Future<void> _submit() async {
    if (!form.currentState!.validate()) return;
    final date = fields['maintenanceDate']!.text.trim();
    final next = fields['nextDueDate']!.text.trim();
    if (DateTime.tryParse(date) == null ||
        (next.isNotEmpty && DateTime.tryParse(next) == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Use valid dates in YYYY-MM-DD format.')));
      return;
    }
    if (next.isNotEmpty &&
        DateTime.parse(next).isBefore(DateTime.parse(date))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Next due date cannot be before the maintenance date.')));
      return;
    }
    setState(() => saving = true);
    try {
      final body = <String, dynamic>{
        'maintenanceType': fields['maintenanceType']!.text.trim(),
        'title': fields['title']!.text.trim(),
        'description': fields['description']!.text.trim(),
        'cost': fields['cost']!.text.trim(),
        'maintenanceDate': date,
        'status': status
      };
      if (next.isNotEmpty) body['nextDueDate'] = next;
      for (final key in ['serviceCenterName', 'invoiceDocumentUrl']) {
        if (fields[key]!.text.trim().isNotEmpty) {
          body[key] = fields[key]!.text.trim();
        }
      }
      if (widget.maintenanceId == null) {
        await ref
            .read(agencyRepositoryProvider)
            .createMaintenance(widget.vehicleId, body);
      } else {
        await ref
            .read(agencyRepositoryProvider)
            .updateMaintenance(widget.maintenanceId!, body);
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Maintenance saved')));
        context.go('/agency/vehicles/${widget.vehicleId}/maintenance');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Maintenance could not be saved. Refresh and try again.')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

Widget _info(String title, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: AgrizelCard(
        child: ListTile(
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(value.isEmpty ? 'Unavailable' : value))));
Widget _loading(AsyncSnapshot snapshot) => Scaffold(
    body: Center(
        child: snapshot.hasError
            ? const Text('Unable to load maintenance.')
            : const CircularProgressIndicator()));

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(40), child: Center(child: Text(text)));
}

class _Retry extends StatelessWidget {
  final VoidCallback onRetry;
  const _Retry({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
      child: OutlinedButton(onPressed: onRetry, child: const Text('Retry')));
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
