import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/audit_log_model.dart';
import '../../data/repositories/admin_repository.dart';
import 'admin_provider.dart';

class AdminAuditLogState {
  final bool isLoading;
  final List<AuditLogModel> logs;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool isLastPage;
  final String? actionFilter;
  final String? entityNameFilter;
  final String? actorIdFilter;
  final String? fromDateFilter;
  final String? toDateFilter;
  final String? errorMessage;

  const AdminAuditLogState({
    this.isLoading = false,
    this.logs = const [],
    this.pageNumber = 0,
    this.pageSize = 20,
    this.totalElements = 0,
    this.totalPages = 0,
    this.isLastPage = true,
    this.actionFilter,
    this.entityNameFilter,
    this.actorIdFilter,
    this.fromDateFilter,
    this.toDateFilter,
    this.errorMessage,
  });

  AdminAuditLogState copyWith({
    bool? isLoading,
    List<AuditLogModel>? logs,
    int? pageNumber,
    int? pageSize,
    int? totalElements,
    int? totalPages,
    bool? isLastPage,
    String? actionFilter,
    String? entityNameFilter,
    String? actorIdFilter,
    String? fromDateFilter,
    String? toDateFilter,
    String? errorMessage,
  }) {
    return AdminAuditLogState(
      isLoading: isLoading ?? this.isLoading,
      logs: logs ?? this.logs,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      totalElements: totalElements ?? this.totalElements,
      totalPages: totalPages ?? this.totalPages,
      isLastPage: isLastPage ?? this.isLastPage,
      actionFilter: actionFilter ?? this.actionFilter,
      entityNameFilter: entityNameFilter ?? this.entityNameFilter,
      actorIdFilter: actorIdFilter ?? this.actorIdFilter,
      fromDateFilter: fromDateFilter ?? this.fromDateFilter,
      toDateFilter: toDateFilter ?? this.toDateFilter,
      errorMessage: errorMessage,
    );
  }
}

class AdminAuditLogNotifier extends StateNotifier<AdminAuditLogState> {
  final AdminRepository _repository;

  AdminAuditLogNotifier(this._repository) : super(const AdminAuditLogState()) {
    fetchLogs();
  }

  Future<void> fetchLogs({int page = 0}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final pagedLogs = await _repository.getAuditLogs(
        action: state.actionFilter,
        entityName: state.entityNameFilter,
        actorId: state.actorIdFilter,
        fromDate: state.fromDateFilter,
        toDate: state.toDateFilter,
        page: page,
        size: state.pageSize,
      );

      state = state.copyWith(
        isLoading: false,
        logs: pagedLogs.content,
        pageNumber: pagedLogs.pageNumber,
        pageSize: pagedLogs.pageSize,
        totalElements: pagedLogs.totalElements,
        totalPages: pagedLogs.totalPages,
        isLastPage: pagedLogs.last,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load audit logs: $e',
      );
    }
  }

  void setActionFilter(String? action) {
    state = state.copyWith(actionFilter: action);
    fetchLogs(page: 0);
  }

  void setEntityNameFilter(String? entityName) {
    state = state.copyWith(entityNameFilter: entityName);
    fetchLogs(page: 0);
  }

  void setActorIdFilter(String? actorId) {
    state = state.copyWith(actorIdFilter: actorId);
    fetchLogs(page: 0);
  }

  void setDateFilter(String? from, String? to) {
    state = state.copyWith(fromDateFilter: from, toDateFilter: to);
    fetchLogs(page: 0);
  }

  void resetFilters() {
    state = const AdminAuditLogState();
    fetchLogs(page: 0);
  }

  void nextPage() {
    if (!state.isLastPage) {
      fetchLogs(page: state.pageNumber + 1);
    }
  }

  void previousPage() {
    if (state.pageNumber > 0) {
      fetchLogs(page: state.pageNumber - 1);
    }
  }
}

final adminAuditLogProvider =
    StateNotifierProvider<AdminAuditLogNotifier, AdminAuditLogState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminAuditLogNotifier(repository);
});
