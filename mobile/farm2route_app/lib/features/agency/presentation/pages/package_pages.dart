import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../data/package_model.dart';
import '../providers/agency_provider.dart';

const _days = [
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
  'SUNDAY'
];
String _dayLabel(String value) =>
    '${value[0]}${value.substring(1).toLowerCase()}';
String _packageError(Object error) =>
    error.toString().replaceFirst('Exception: ', '');

class PackageListPage extends ConsumerStatefulWidget {
  const PackageListPage({super.key});
  @override
  ConsumerState<PackageListPage> createState() => _PackageListState();
}

class _PackageListState extends ConsumerState<PackageListPage> {
  String query = '';
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Packages'), actions: [
          IconButton(
              onPressed: () => context.push('/agency/packages/new'),
              icon: const Icon(Icons.add))
        ]),
        body: FutureBuilder<List<dynamic>>(
            future: ref.watch(agencyRepositoryProvider).getPackages(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _Retry(
                    message: 'Unable to load packages',
                    onRetry: () => setState(() {}));
              }
              final packages = (snapshot.data ?? [])
                  .map((x) => PackageModel.fromJson(
                      Map<String, dynamic>.from(x as Map)))
                  .where((p) =>
                      query.isEmpty ||
                      p.title.toLowerCase().contains(query.toLowerCase()) ||
                      p.routeOrigin
                          .toLowerCase()
                          .contains(query.toLowerCase()) ||
                      p.routeDestination
                          .toLowerCase()
                          .contains(query.toLowerCase()))
                  .toList();
              return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView(padding: const EdgeInsets.all(20), children: [
                    TextField(
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Search loaded packages'),
                        onChanged: (v) => setState(() => query = v)),
                    const SizedBox(height: 16),
                    if (packages.isEmpty)
                      const _Empty(text: 'No packages configured yet.')
                    else
                      ...packages.map((p) => _PackageCard(package: p))
                  ]));
            }),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/agency/packages/new'),
            icon: const Icon(Icons.add),
            label: const Text('Add package')),
      );
}

class _PackageCard extends StatelessWidget {
  final PackageModel package;
  const _PackageCard({required this.package});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AgrizelCard(
          child: ListTile(
              isThreeLine: true,
              leading: const Icon(Icons.inventory_2, color: AppColors.primary),
              title: Text(
                  package.title.isEmpty ? 'Untitled package' : package.title),
              subtitle: Text(
                  '${package.routeOrigin} → ${package.routeDestination}\nBase ${package.basePrice} • ${package.maxWeightKg} kg • ${package.scheduleDays.map(_dayLabel).join(', ')}'),
              trailing:
                  Chip(label: Text(package.isActive ? 'Active' : 'Inactive')),
              onTap: () => context.push('/agency/packages/${package.id}'))));
}

class PackageDetailsPage extends ConsumerWidget {
  final String id;
  const PackageDetailsPage({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder(
      future: ref.watch(agencyRepositoryProvider).getPackage(id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _loading(snapshot, 'Unable to load package');
        }
        final p = PackageModel.fromJson(
            Map<String, dynamic>.from(snapshot.data as Map));
        return Scaffold(
            appBar: AppBar(
                leading: IconButton(
                    tooltip: 'Back to packages',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/agency/packages')),
                title: Text(p.title),
                actions: [
                  IconButton(
                      onPressed: () =>
                          context.push('/agency/packages/$id/edit'),
                      icon: const Icon(Icons.edit))
                ]),
            body: ListView(padding: const EdgeInsets.all(24), children: [
              _info('Route', '${p.routeOrigin} → ${p.routeDestination}'),
              _info('Package type', _pretty(p.packageType)),
              _info('Description', p.description),
              _info('Pricing',
                  'Base: ${p.basePrice}\nPer km: ${p.pricePerKm}\nPer kg: ${p.pricePerKg}\nEstimated: ${p.estimatedCost.isEmpty ? '—' : p.estimatedCost}'),
              _info('Capacity', '${p.maxWeightKg} kg'),
              _info('Availability', p.isActive ? 'Active' : 'Inactive'),
              _info(
                  'Recurring schedule',
                  p.scheduleDays.isEmpty
                      ? 'No recurring days'
                      : p.scheduleDays.map(_dayLabel).join(', ')),
              const SizedBox(height: 12),
              _DeletePackage(id: id, title: p.title)
            ]));
      });
}

class PackageFormPage extends ConsumerStatefulWidget {
  final String? id;
  const PackageFormPage({super.key, this.id});
  @override
  ConsumerState<PackageFormPage> createState() => _PackageFormState();
}

class _PackageFormState extends ConsumerState<PackageFormPage> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{
    for (final key in [
      'title',
      'description',
      'packageType',
      'basePrice',
      'pricePerKm',
      'pricePerKg',
      'maxWeightKg',
      'routeOrigin',
      'routeDestination'
    ])
      key: TextEditingController()
  };
  final selectedDays = <String>{};
  bool active = true;
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
    if (widget.id != null && !loaded) {
      return FutureBuilder(
          future: ref.read(agencyRepositoryProvider).getPackage(widget.id!),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _loading(snapshot, 'Unable to load package');
            }
            _fill(Map<String, dynamic>.from(snapshot.data as Map));
            return _form(context);
          });
    }
    return _form(context);
  }

  void _fill(Map<String, dynamic> data) {
    for (final key in fields.keys) {
      fields[key]!.text = '${data[key] ?? ''}';
    }
    fields['packageType']!.text = '${data['packageType'] ?? 'STANDARD'}';
    // Support both Jackson boolean property names returned by the API.
    active = data['isActive'] ?? data['active'] ?? true;
    selectedDays
      ..clear()
      ..addAll((data['scheduleDays'] as List? ?? const []).map((x) => '$x'));
    loaded = true;
  }

  Widget _form(BuildContext context) => Scaffold(
      appBar: AppBar(
          leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => widget.id == null
                  ? context.go('/agency/packages')
                  : context.go('/agency/packages/${widget.id}')),
          title: Text(widget.id == null ? 'Add package' : 'Edit package')),
      body: Form(
          key: form,
          child: ListView(padding: const EdgeInsets.all(24), children: [
            Text('Basic information', style: AppTextStyles.headingSmall),
            _field('title', 'Package title'),
            _field('description', 'Description', required: false, maxLines: 3),
            _field('packageType',
                'Package type (STANDARD, EXPRESS, COLD_CHAIN, BULK_AGRICULTURAL, WEIGHT_BASED)'),
            const SizedBox(height: 12),
            Text('Route', style: AppTextStyles.headingSmall),
            _field('routeOrigin', 'Origin'),
            _field('routeDestination', 'Destination'),
            const SizedBox(height: 12),
            Text('Pricing and capacity', style: AppTextStyles.headingSmall),
            _field('basePrice', 'Base price', decimal: true),
            _field('pricePerKm', 'Price per km', decimal: true),
            _field('pricePerKg', 'Price per kg',
                decimal: true, required: false),
            _field('maxWeightKg', 'Maximum weight (kg)', decimal: true),
            Material(
                color: Colors.transparent,
                child: SwitchListTile(
                    title: const Text('Active package'),
                    value: active,
                    onChanged: (v) => setState(() => active = v))),
            const SizedBox(height: 12),
            Text('Recurring schedule', style: AppTextStyles.headingSmall),
            const Text(
                'Selected weekdays are sent as canonical backend enum values.'),
            Wrap(
                spacing: 8,
                children: _days
                    .map((day) => FilterChip(
                        label: Text(_dayLabel(day)),
                        selected: selectedDays.contains(day),
                        onSelected: (value) => setState(() {
                              if (value) {
                                selectedDays.add(day);
                              } else {
                                selectedDays.remove(day);
                              }
                            })))
                    .toList()),
            const SizedBox(height: 20),
            FilledButton(
                onPressed: saving ? null : _submit,
                child: Text(saving
                    ? 'Saving…'
                    : widget.id == null
                        ? 'Create package'
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
                if (decimal && value != null && value.trim().isNotEmpty) {
                  final number = double.tryParse(value);
                  if (number == null ||
                      number < 0 ||
                      (key == 'maxWeightKg' && number <= 0)) {
                    return 'Enter a valid positive number';
                  }
                }
                return null;
              }));
  Future<void> _submit() async {
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final body = <String, dynamic>{
        'title': fields['title']!.text.trim(),
        'description': fields['description']!.text.trim(),
        'packageType': fields['packageType']!.text.trim().toUpperCase(),
        'basePrice': fields['basePrice']!.text.trim(),
        'pricePerKm': fields['pricePerKm']!.text.trim(),
        'maxWeightKg': fields['maxWeightKg']!.text.trim(),
        'routeOrigin': fields['routeOrigin']!.text.trim(),
        'routeDestination': fields['routeDestination']!.text.trim(),
        'scheduleDays': selectedDays.toList()
      };
      if (fields['pricePerKg']!.text.trim().isNotEmpty) {
        body['pricePerKg'] = fields['pricePerKg']!.text.trim();
      }
      if (widget.id != null) {
        body['isActive'] = active;
      }
      final response = widget.id == null
          ? await ref.read(agencyRepositoryProvider).createPackage(body)
          : await ref
              .read(agencyRepositoryProvider)
              .updatePackage(widget.id!, body);
      if (mounted) {
        final id = '${(response as Map)['id'] ?? widget.id ?? ''}';
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Package saved')));
        context.go('/agency/packages/$id');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_packageError(error))));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class _DeletePackage extends ConsumerStatefulWidget {
  final String id;
  final String title;
  const _DeletePackage({required this.id, required this.title});
  @override
  ConsumerState<_DeletePackage> createState() => _DeletePackageState();
}

class _DeletePackageState extends ConsumerState<_DeletePackage> {
  bool deleting = false;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: deleting ? null : _delete,
        icon: const Icon(Icons.delete_outline, color: AppColors.error),
        label: Text(deleting ? 'Deleting…' : 'Delete package'),
      );

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete package?'),
        content: Text('Delete ${widget.title}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => deleting = true);
    try {
      await ref.read(agencyRepositoryProvider).deletePackage(widget.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Package deleted')));
        context.go('/agency/packages');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_packageError(error))));
      }
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }
}

String _pretty(String value) => value
    .replaceAll('_', ' ')
    .toLowerCase()
    .split(' ')
    .map((x) => x.isEmpty ? x : '${x[0].toUpperCase()}${x.substring(1)}')
    .join(' ');
Widget _info(String title, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: AgrizelCard(
        child: ListTile(
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(value.isEmpty ? '—' : value))));
Widget _loading(AsyncSnapshot snapshot, String message) => Scaffold(
    body: Center(
        child: snapshot.hasError
            ? Text(message)
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
