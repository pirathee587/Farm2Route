import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/agency_provider.dart';
import '../../data/agency_profile_model.dart';
import 'driver_vehicle_pages.dart';
import 'package_pages.dart';
import 'booking_pages.dart';
import 'maintenance_pages.dart';
import 'finance_pages.dart';
import 'reviews_notifications_pages.dart';
import '../providers/review_notification_provider.dart';

class AgencyPortalPage extends ConsumerWidget {
  final String section;
  const AgencyPortalPage({super.key, required this.section});

  static const _items = <String, String>{
    'dashboard': 'Dashboard',
    'bookings': 'Bookings',
    'assignments': 'Assignments',
    'drivers': 'Drivers',
    'vehicles': 'Vehicles',
    'packages': 'Packages',
    'maintenance': 'Maintenance',
    'finance': 'Finance',
    'reviews': 'Reviews',
    'notifications': 'Notifications',
    'profile': 'Agency Profile',
  };

  String _path(String key) =>
      key == 'dashboard' ? RouteNames.agencyHome : '/agency/$key';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.sizeOf(context).width >= 800;
    final unreadCount = ref.watch(agencyUnreadCountProvider).valueOrNull ?? 0;
    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 20,
          title: Text(_items[section] ?? 'Agency Portal'),
          actions: [
            IconButton(
                tooltip: unreadCount == 0
                    ? 'Notifications'
                    : '$unreadCount unread notifications',
                onPressed: () => context.push(RouteNames.agencyNotifications),
                icon: Stack(clipBehavior: Clip.none, children: [
                  const Icon(Icons.notifications_none_rounded),
                  if (unreadCount > 0)
                    Positioned(
                        right: -8,
                        top: -8,
                        child: CircleAvatar(
                            radius: 9,
                            backgroundColor: AppColors.error,
                            child: Text('$unreadCount',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10))))
                ])),
            PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'logout') {
                    ref.read(authNotifierProvider.notifier).logout();
                  }
                  if (v == 'profile') {
                    context.push(RouteNames.agencyProfile);
                  }
                },
                itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: 'profile', child: Text('Agency profile')),
                      PopupMenuItem(value: 'logout', child: Text('Sign out'))
                    ]),
          ]),
      drawer: isWide ? null : Drawer(child: _navigation(context)),
      body: Row(children: [
        if (isWide) SizedBox(width: 248, child: _navigation(context)),
        Expanded(child: _content(context, ref))
      ]),
      bottomNavigationBar: isWide ? null : _bottomNavigation(context),
    );
  }

  Widget _navigation(BuildContext context) => Material(
      color: AppColors.surfaceLight,
      child: SafeArea(
          child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
            Padding(
                padding: const EdgeInsets.all(20),
                child: Text('FARM2ROUTE',
                    style: AppTextStyles.headingSmall
                        .copyWith(color: AppColors.primary))),
            ..._items.entries.map((e) => ListTile(
                leading: Icon(_icon(e.key),
                    color: section == e.key
                        ? AppColors.primary
                        : AppColors.textSecondary),
                title: Text(e.value),
                selected: section == e.key,
                selectedTileColor: AppColors.primaryLight,
                onTap: () => context.go(_path(e.key))))
          ])));

  Widget _bottomNavigation(BuildContext context) {
    const items = [
      (Icons.grid_view_rounded, 'Home', 'dashboard'),
      (Icons.receipt_long_rounded, 'Bookings', 'bookings'),
      (Icons.groups_rounded, 'Drivers', 'drivers'),
      (Icons.local_shipping_outlined, 'Vehicles', 'vehicles'),
      (Icons.account_balance_wallet_outlined, 'Finance', 'finance'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SafeArea(
        top: false,
        child: Row(
          children: items.map((item) {
            final selected = section == item.$3;
            return Expanded(
              child: InkWell(
                onTap: () => context.go(_path(item.$3)),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.$1,
                          size: 22,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textLight),
                      const SizedBox(height: 3),
                      Text(
                        item.$2,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? AppColors.primaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _icon(String key) => {
        'dashboard': Icons.grid_view_rounded,
        'bookings': Icons.receipt_long,
        'assignments': Icons.assignment_turned_in,
        'drivers': Icons.groups,
        'vehicles': Icons.local_shipping,
        'packages': Icons.inventory_2,
        'maintenance': Icons.build_circle,
        'finance': Icons.account_balance_wallet,
        'reviews': Icons.star_outline,
        'notifications': Icons.notifications_none,
        'profile': Icons.business
      }.containsKey(key)
          ? {
              'dashboard': Icons.grid_view_rounded,
              'bookings': Icons.receipt_long,
              'assignments': Icons.assignment_turned_in,
              'drivers': Icons.groups,
              'vehicles': Icons.local_shipping,
              'packages': Icons.inventory_2,
              'maintenance': Icons.build_circle,
              'finance': Icons.account_balance_wallet,
              'reviews': Icons.star_outline,
              'notifications': Icons.notifications_none,
              'profile': Icons.business
            }[key]!
          : Icons.circle;

  Widget _content(BuildContext context, WidgetRef ref) {
    if (section == 'dashboard') return const _Dashboard();
    if (section == 'profile') return const _Profile();
    if (section == 'finance') return const FinanceOverviewPage();
    if (section == 'drivers') return const DriverListPage();
    if (section == 'vehicles') return const VehicleListPage();
    if (section == 'packages') return const PackageListPage();
    if (section == 'bookings') return const BookingListPage();
    if (section == 'maintenance') return const MaintenanceOverviewPage();
    if (section == 'reviews') return const AgencyReviewsPage(embedded: true);
    if (section == 'notifications') {
      return const AgencyNotificationsPage(embedded: true);
    }
    return _ResourceList(
        resource: section == 'assignments' ? 'bookings' : section,
        title: _items[section] ?? section,
        ref: ref);
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard();
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final data = ref.watch(agencyDashboardProvider);
    return data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => _StateMessage('Unable to load dashboard',
            () => ref.invalidate(agencyDashboardProvider)),
        data: (d) {
          final map = Map<String, dynamic>.from(d as Map);
          return RefreshIndicator(
              onRefresh: () async => ref.invalidate(agencyDashboardProvider),
              child: ListView(padding: const EdgeInsets.all(24), children: [
                Text('Good day, Agency', style: AppTextStyles.headingLarge),
                const SizedBox(height: 6),
                Text('Your fleet at a glance',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                _MetricGrid(data: map),
                const SizedBox(height: 24),
                AgrizelCard(
                    child: ListTile(
                        leading: const Icon(Icons.info_outline,
                            color: AppColors.info),
                        title: const Text('Assignment workspace'),
                        subtitle: const Text(
                            'Review accepted bookings and confirm eligible driver and vehicle assignments.'),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => c.go(RouteNames.agencyBookings)))
              ]));
        });
  }
}

class _MetricGrid extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MetricGrid({required this.data});
  @override
  Widget build(BuildContext c) => LayoutBuilder(
        builder: (context, constraints) {
          final groups = [
            ('Bookings', 'bookingSummary', Icons.receipt_long),
            ('Drivers', 'driverSummary', Icons.groups),
            ('Vehicles', 'vehicleSummary', Icons.local_shipping),
            ('Maintenance', 'maintenanceSummary', Icons.build_circle),
            ('Assignments', 'assignmentSummary', Icons.assignment_turned_in),
            ('Finance', 'financeSummary', Icons.account_balance_wallet)
          ];
          final columns = constraints.maxWidth >= 1000
              ? 3
              : constraints.maxWidth >= 600
                  ? 2
                  : 1;
          return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: columns == 1 ? 2.2 : 1.7,
              children: groups.map((g) {
                final value = data[g.$2] is Map
                    ? Map<String, dynamic>.from(data[g.$2])
                    : <String, dynamic>{};
                final primary = value['total'] ??
                    value['available'] ??
                    value['net'] ??
                    value['active'] ??
                    value['assigned'] ??
                    0;
                return AgrizelCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Icon(g.$3, color: AppColors.primary),
                      const SizedBox(height: 10),
                      Text('$primary', style: AppTextStyles.headingLarge),
                      Text(g.$1,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary))
                    ]));
              }).toList());
        },
      );
}

class _ResourceList extends ConsumerWidget {
  final String resource;
  final String title;
  final WidgetRef ref;
  const _ResourceList(
      {required this.resource, required this.title, required this.ref});
  @override
  Widget build(BuildContext c, WidgetRef _) {
    final state = ref.watch(agencyResourceProvider(resource));
    return state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => _StateMessage('Unable to load $title',
            () => ref.invalidate(agencyResourceProvider(resource))),
        data: (items) => RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(agencyResourceProvider(resource)),
            child: ListView(padding: const EdgeInsets.all(24), children: [
              LayoutBuilder(builder: (context, constraints) {
                final addButton =
                    ['drivers', 'vehicles', 'packages'].contains(resource)
                        ? FilledButton.icon(
                            onPressed: () => _showCreate(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add'))
                        : null;
                if (addButton == null) {
                  return Text(title, style: AppTextStyles.headingLarge);
                }
                if (constraints.maxWidth < 500) {
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(title, style: AppTextStyles.headingLarge),
                        const SizedBox(height: 12),
                        addButton,
                      ]);
                }
                return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                          child: Text(title,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.headingLarge)),
                      addButton,
                    ]);
              }),
              const SizedBox(height: 18),
              if (items.isEmpty)
                const _EmptyMessage()
              else
                ...items.map((item) {
                  final m = Map<String, dynamic>.from(item as Map);
                  return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AgrizelCard(
                          child: ListTile(
                              title: Text(_label(m)),
                              subtitle: Text(_subtitle(m)),
                              trailing: _status(m),
                              onTap: () {})));
                })
            ])));
  }

  String _label(Map<String, dynamic> m) => (m['name'] ??
          m['fullName'] ??
          m['registrationNumber'] ??
          m['reference'] ??
          m['bookingReference'] ??
          m['title'] ??
          'Record')
      .toString();
  String _subtitle(Map<String, dynamic> m) => [
        m['phoneNumber'],
        m['origin'],
        m['destination'],
        m['status'],
        m['type']
      ].where((x) => x != null).join(' • ');
  Widget _status(Map<String, dynamic> m) {
    final s =
        (m['status'] ?? m['kycStatus'] ?? m['availability'] ?? '').toString();
    return s.isEmpty
        ? const Icon(Icons.chevron_right)
        : Chip(label: Text(s.replaceAll('_', ' ')));
  }

  void _showCreate(BuildContext c) {
    showDialog(
        context: c,
        builder: (_) => AlertDialog(
                title: Text('Create $title'),
                content: const Text(
                    'Use the full form to register a new resource. This entry point is ready for the next workflow step.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Close'))
                ]));
  }
}

class _Profile extends ConsumerWidget {
  const _Profile();

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final state = ref.watch(agencyProfileProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _StateMessage('Unable to load agency profile',
          () => ref.invalidate(agencyProfileProvider)),
      data: (profile) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(agencyProfileProvider),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _ProfileHero(profile: profile),
              const SizedBox(height: 20),
              _ProfileSection(
                title: 'Business information',
                icon: Icons.business_outlined,
                children: [
                  _ProfileValue(
                      label: 'Company name', value: profile.companyName),
                  _ProfileValue(
                      label: 'Business registration number',
                      value: profile.businessRegistrationNumber),
                  _ProfileValue(
                      label: 'Tax identification number',
                      value: profile.taxIdentificationNumber),
                ],
              ),
              const SizedBox(height: 14),
              _ProfileSection(
                title: 'Contact and office',
                icon: Icons.contact_mail_outlined,
                children: [
                  _ProfileValue(
                      label: 'Contact person',
                      value: profile.contactPersonName),
                  _ProfileValue(
                      label: 'Contact phone',
                      value: profile.contactPersonPhone),
                  _ProfileValue(
                      label: 'Office address', value: profile.officeAddress),
                  _ProfileValue(label: 'District', value: profile.district),
                ],
              ),
              const SizedBox(height: 14),
              _ProfileSection(
                title: 'Verification and account',
                icon: Icons.verified_user_outlined,
                children: [
                  _ProfileStatusValue(
                      label: 'KYC status', value: profile.kycStatus),
                  _ProfileValue(
                      label: 'Commission rate',
                      value: profile.commissionRatePercentage == null
                          ? null
                          : '${profile.commissionRatePercentage}%'),
                  _ProfileValue(label: 'Profile ID', value: profile.id),
                ],
              ),
            ],
          )),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final AgencyProfileModel profile;
  const _ProfileHero({required this.profile});

  @override
  Widget build(BuildContext context) => AgrizelCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final identity = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      profile.companyName.isEmpty
                          ? 'A'
                          : profile.companyName[0].toUpperCase(),
                      style: AppTextStyles.headingMedium
                          .copyWith(color: AppColors.primaryDark),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            profile.companyName.isEmpty
                                ? 'Agency profile'
                                : profile.companyName,
                            style: AppTextStyles.headingMedium),
                        const SizedBox(height: 6),
                        Text(
                            'Manage your business information and contact details.',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        _StatusChip(label: profile.kycStatus ?? 'Not provided'),
                      ],
                    ),
                  ),
                ],
              );
              final editButton = OutlinedButton.icon(
                onPressed: () => context.push(RouteNames.agencyProfileEdit),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit profile'),
              );
              if (constraints.maxWidth < 560) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      identity,
                      const SizedBox(height: 16),
                      editButton
                    ]);
              }
              return Row(children: [
                Expanded(child: identity),
                const SizedBox(width: 16),
                editButton,
              ]);
            },
          ),
        ),
      );
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _ProfileSection(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) => AgrizelCard(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 21, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(title, style: AppTextStyles.headingSmall),
              ]),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      );
}

class _ProfileValue extends StatelessWidget {
  final String label;
  final String? value;
  const _ProfileValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(value?.isNotEmpty == true ? value! : 'Not provided',
              style: AppTextStyles.bodyLarge),
        ),
      );
}

class _ProfileStatusValue extends StatelessWidget {
  final String label;
  final String? value;
  const _ProfileStatusValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 7),
          child: _StatusChip(label: value ?? 'Not provided'),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  final String label;
  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(20)),
        child: Text(label.replaceAll('_', ' '),
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
      );
}

class AgencyProfileEditPage extends ConsumerStatefulWidget {
  const AgencyProfileEditPage({super.key});

  @override
  ConsumerState<AgencyProfileEditPage> createState() =>
      _AgencyProfileEditPageState();
}

class _AgencyProfileEditPageState extends ConsumerState<AgencyProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  AgencyProfileModel? _profile;
  bool _saving = false;

  static const _editableFields = [
    'companyName',
    'businessRegistrationNumber',
    'taxIdentificationNumber',
    'officeAddress',
    'district',
    'contactPersonName',
    'contactPersonPhone',
  ];

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initialize(AgencyProfileModel profile) {
    if (_profile != null) return;
    _profile = profile;
    final values = profile.toUpdateJson();
    for (final key in _editableFields) {
      _controllers[key] = TextEditingController(text: '${values[key] ?? ''}');
    }
  }

  bool get _dirty {
    final profile = _profile;
    if (profile == null) return false;
    final initial = profile.toUpdateJson();
    return _editableFields.any(
        (key) => _controllers[key]!.text.trim() != '${initial[key] ?? ''}');
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your unsaved profile changes will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep editing')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Discard')),
        ],
      ),
    );
    return discard == true;
  }

  String _errorMessage(Object error) {
    if (error is AppException) {
      switch (error.statusCode) {
        case 400:
        case 422:
          return 'Please check the highlighted information.';
        case 403:
          return 'You do not have permission to update this profile.';
        case 409:
          return 'This business registration number is already registered.';
        case 401:
          return 'Your session has expired. Please sign in again.';
      }
    }
    return 'Something went wrong while updating your profile. Please try again.';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final body = {
        for (final key in _editableFields) key: _controllers[key]!.text.trim(),
      };
      await ref.read(agencyRepositoryProvider).updateProfile(body);
      ref.invalidate(agencyProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agency profile updated')));
      context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required' : null;

  Widget _field(String key, String label,
          {bool required = true, int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: TextFormField(
          controller: _controllers[key],
          maxLines: maxLines,
          textInputAction:
              maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
          decoration: InputDecoration(
              labelText: label, helperText: required ? 'Required' : 'Optional'),
          validator: required ? (value) => _required(value, label) : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agencyProfileProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) async {
        if (await _confirmDiscard() && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit agency profile'),
          leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                if (await _confirmDiscard() && context.mounted) context.pop();
              }),
        ),
        body: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _StateMessage('Unable to load agency profile',
              () => ref.invalidate(agencyProfileProvider)),
          data: (profile) {
            _initialize(profile);
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text('Business information',
                      style: AppTextStyles.headingSmall),
                  const SizedBox(height: 14),
                  _field('companyName', 'Company name'),
                  _field('businessRegistrationNumber',
                      'Business registration number'),
                  _field('taxIdentificationNumber', 'Tax identification number',
                      required: false),
                  const SizedBox(height: 8),
                  Text('Contact and office', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 14),
                  _field('contactPersonName', 'Contact person name'),
                  _field('contactPersonPhone', 'Contact person phone'),
                  _field('officeAddress', 'Office address', maxLines: 3),
                  _field('district', 'District'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () async {
                                  if (await _confirmDiscard() &&
                                      context.mounted) {
                                    context.pop();
                                  }
                                },
                          child: const Text('Cancel')),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save_outlined),
                          label: Text(_saving ? 'Saving...' : 'Save changes')),
                    ),
                  ]),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage();
  @override
  Widget build(BuildContext c) => const Padding(
      padding: EdgeInsets.all(40),
      child: Center(child: Text('No records found.')));
}

class _StateMessage extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const _StateMessage(this.message, this.retry);
  @override
  Widget build(BuildContext c) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(message),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: retry, child: const Text('Retry'))
      ]));
}
