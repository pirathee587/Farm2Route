import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/admin_incident_model.dart';
import 'admin_provider.dart';

class AdminIncidentFilter {
  final String? status;
  final String? incidentType;
  final String? fromDate;
  final String? toDate;
  final int page;

  const AdminIncidentFilter({
    this.status,
    this.incidentType,
    this.fromDate,
    this.toDate,
    this.page = 0,
  });

  AdminIncidentFilter copyWith({
    Object? status = _sentinel,
    Object? incidentType = _sentinel,
    Object? fromDate = _sentinel,
    Object? toDate = _sentinel,
    int? page,
  }) {
    return AdminIncidentFilter(
      status: status == _sentinel ? this.status : status as String?,
      incidentType: incidentType == _sentinel ? this.incidentType : incidentType as String?,
      fromDate: fromDate == _sentinel ? this.fromDate : fromDate as String?,
      toDate: toDate == _sentinel ? this.toDate : toDate as String?,
      page: page ?? this.page,
    );
  }
}

const _sentinel = Object();

class AdminIncidentNotifier extends StateNotifier<AsyncValue<List<AdminIncidentModel>>> {
  final Ref _ref;
  AdminIncidentFilter _filter = const AdminIncidentFilter();

  AdminIncidentNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchIncidents();
  }

  AdminIncidentFilter get filter => _filter;

  Future<void> fetchIncidents() async {
    state = const AsyncValue.loading();
    try {
      final repository = _ref.read(adminRepositoryProvider);
      final list = await repository.searchIncidents(
        status: _filter.status,
        incidentType: _filter.incidentType,
        fromDate: _filter.fromDate,
        toDate: _filter.toDate,
        page: _filter.page,
      );
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void setFilter({
    Object? status = _sentinel,
    Object? incidentType = _sentinel,
    Object? fromDate = _sentinel,
    Object? toDate = _sentinel,
    int? page,
  }) {
    _filter = _filter.copyWith(
      status: status,
      incidentType: incidentType,
      fromDate: fromDate,
      toDate: toDate,
      page: page,
    );
    fetchIncidents();
  }
}

final adminIncidentNotifierProvider =
    StateNotifierProvider<AdminIncidentNotifier, AsyncValue<List<AdminIncidentModel>>>((ref) {
  return AdminIncidentNotifier(ref);
});

final adminIncidentDetailProvider =
    FutureProvider.family<AdminIncidentModel, String>((ref, id) async {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.getIncidentDetail(id);
});
