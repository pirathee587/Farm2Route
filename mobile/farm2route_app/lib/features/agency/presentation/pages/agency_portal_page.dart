import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/agency_provider.dart';
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: Text(_items[section] ?? 'Agency Portal'), actions: [
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
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: [
                'dashboard',
                'bookings',
                'drivers',
                'vehicles',
                'finance'
              ].indexOf(section).clamp(0, 4),
              onDestinationSelected: (i) => context.go(_path([
                    'dashboard',
                    'bookings',
                    'drivers',
                    'vehicles',
                    'finance'
                  ][i])),
              destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.grid_view_rounded), label: 'Home'),
                  NavigationDestination(
                      icon: Icon(Icons.receipt_long), label: 'Bookings'),
                  NavigationDestination(
                      icon: Icon(Icons.groups), label: 'Drivers'),
                  NavigationDestination(
                      icon: Icon(Icons.local_shipping), label: 'Vehicles'),
                  NavigationDestination(
                      icon: Icon(Icons.account_balance_wallet),
                      label: 'Finance')
                ]),
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
  Widget build(BuildContext c) {
    final groups = [
      ('Bookings', 'bookingSummary', Icons.receipt_long),
      ('Drivers', 'driverSummary', Icons.groups),
      ('Vehicles', 'vehicleSummary', Icons.local_shipping),
      ('Maintenance', 'maintenanceSummary', Icons.build_circle),
      ('Assignments', 'assignmentSummary', Icons.assignment_turned_in),
      ('Finance', 'financeSummary', Icons.account_balance_wallet)
    ];
    return GridView.count(
        crossAxisCount: MediaQuery.sizeOf(c).width > 1000 ? 3 : 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.6,
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
  }
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
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(title, style: AppTextStyles.headingLarge),
                if (['drivers', 'vehicles', 'packages'].contains(resource))
                  FilledButton.icon(
                      onPressed: () => _showCreate(c),
                      icon: const Icon(Icons.add),
                      label: const Text('Add'))
              ]),
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
    final state = ref.watch(agencyRepositoryProvider).getProfile();
    return FutureBuilder(
        future: state,
        builder: (_, s) {
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final m = Map<String, dynamic>.from(s.data as Map);
          return ListView(padding: const EdgeInsets.all(24), children: [
            Text('Agency profile', style: AppTextStyles.headingLarge),
            const SizedBox(height: 18),
            AgrizelCard(
                child: Column(
                    children: m.entries
                        .map((e) => ListTile(
                            title: Text(e.key
                                .replaceAllMapped(
                                    RegExp(r'([A-Z])'), (x) => ' ${x.group(1)}')
                                .toUpperCase()),
                            subtitle: Text('${e.value ?? '—'}')))
                        .toList()))
          ]);
        });
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
