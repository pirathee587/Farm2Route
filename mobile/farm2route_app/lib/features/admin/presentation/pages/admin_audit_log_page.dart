import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../data/models/audit_log_model.dart';
import '../providers/admin_audit_log_provider.dart';

class AdminAuditLogPage extends ConsumerStatefulWidget {
  const AdminAuditLogPage({super.key});

  @override
  ConsumerState<AdminAuditLogPage> createState() => _AdminAuditLogPageState();
}

class _AdminAuditLogPageState extends ConsumerState<AdminAuditLogPage> {
  final _actionController = TextEditingController();
  final _entityController = TextEditingController();
  final _actorController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _actionController.dispose();
    _entityController.dispose();
    _actorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminAuditLogProvider);
    final notifier = ref.read(adminAuditLogProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        title: Text(
          'Platform Audit Logs',
          style: AppTextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            key: const Key('toggle_filters_btn'),
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: AppColors.primary,
            ),
            tooltip: 'Toggle Filters',
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            key: const Key('refresh_audit_logs_btn'),
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Refresh',
            onPressed: () => notifier.fetchLogs(page: state.pageNumber),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => notifier.fetchLogs(page: state.pageNumber),
        child: Column(
          children: [
            if (_showFilters) _buildFilterSection(ref, notifier, state),
            if (state.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: AppColors.error.withOpacity(0.1),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : state.logs.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: state.logs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final log = state.logs[index];
                            return _AuditLogItemCard(log: log);
                          },
                        ),
            ),
            _buildPaginationFooter(state, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(
    WidgetRef ref,
    AdminAuditLogNotifier notifier,
    AdminAuditLogState state,
  ) {
    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Compliance Audit Trail',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('filter_action_input'),
                  controller: _actionController,
                  decoration: const InputDecoration(
                    labelText: 'Action (e.g. KycReviewed)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const Key('filter_entity_input'),
                  controller: _entityController,
                  decoration: const InputDecoration(
                    labelText: 'Entity Name',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('filter_actor_input'),
            controller: _actorController,
            decoration: const InputDecoration(
              labelText: 'Actor ID (UUID)',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: const Key('reset_filters_btn'),
                onPressed: () {
                  _actionController.clear();
                  _entityController.clear();
                  _actorController.clear();
                  notifier.resetFilters();
                },
                child: const Text('Reset', style: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                key: const Key('apply_filters_btn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Apply Filters'),
                onPressed: () {
                  notifier.setActionFilter(_actionController.text.trim().isEmpty ? null : _actionController.text.trim());
                  notifier.setEntityNameFilter(_entityController.text.trim().isEmpty ? null : _entityController.text.trim());
                  notifier.setActorIdFilter(_actorController.text.trim().isEmpty ? null : _actorController.text.trim());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No Audit Logs Found',
              style: AppTextStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No platform audit records matched your query filters.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(AdminAuditLogState state, AdminAuditLogNotifier notifier) {
    final totalPages = state.totalPages == 0 ? 1 : state.totalPages;
    final currentPage = state.pageNumber + 1;

    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page $currentPage of $totalPages (${state.totalElements} entries)',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          Row(
            children: [
              IconButton(
                key: const Key('prev_page_btn'),
                icon: const Icon(Icons.chevron_left),
                onPressed: state.pageNumber > 0 ? () => notifier.previousPage() : null,
              ),
              IconButton(
                key: const Key('next_page_btn'),
                icon: const Icon(Icons.chevron_right),
                onPressed: !state.isLastPage ? () => notifier.nextPage() : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuditLogItemCard extends StatefulWidget {
  final AuditLogModel log;
  const _AuditLogItemCard({required this.log});

  @override
  State<_AuditLogItemCard> createState() => _AuditLogItemCardState();
}

class _AuditLogItemCardState extends State<_AuditLogItemCard> {
  bool _expanded = false;

  Color _getActionColor(String action) {
    final upper = action.toUpperCase();
    if (upper.contains('RESOLVE') || upper.contains('APPROVE') || upper.contains('RESTORE')) {
      return AppColors.success;
    }
    if (upper.contains('REJECT') || upper.contains('HIDE') || upper.contains('CANCEL')) {
      return AppColors.error;
    }
    if (upper.contains('ESCALATE') || upper.contains('PENDING')) {
      return AppColors.warning;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final actionColor = _getActionColor(log.action);
    final hasDiff = (log.oldValue != null && log.oldValue!.isNotEmpty) ||
        (log.newValue != null && log.newValue!.isNotEmpty);

    return AgrizelCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    log.action,
                    style: TextStyle(
                      color: actionColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (log.createdAt != null)
                  Text(
                    '${log.createdAt!.day}/${log.createdAt!.month}/${log.createdAt!.year} ${log.createdAt!.hour.toString().padLeft(2, '0')}:${log.createdAt!.minute.toString().padLeft(2, '0')}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Entity: ',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${log.entityName}${log.entityId != null ? ' (#${log.entityId})' : ''}',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Actor: ',
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${log.actorRole ?? 'USER'} (${log.actorId ?? 'System'})',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            if (log.ipAddress != null || log.userAgent != null) ...[
              const SizedBox(height: 4),
              Text(
                'IP: ${log.ipAddress ?? 'N/A'} | Client: ${log.userAgent ?? 'Unknown'}',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.textLight),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (hasDiff) ...[
              const Divider(height: 16),
              GestureDetector(
                key: Key('toggle_diff_${log.id}'),
                onTap: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _expanded ? 'Hide JSON Value Diff' : 'Expand JSON Value Diff',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (_expanded) ...[
                const SizedBox(height: 8),
                if (log.oldValue != null && log.oldValue!.isNotEmpty) ...[
                  Text('Old Value:', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.error)),
                  const SizedBox(height: 2),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      log.oldValue!,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.error),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                if (log.newValue != null && log.newValue!.isNotEmpty) ...[
                  Text('New Value:', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.success)),
                  const SizedBox(height: 2),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      log.newValue!,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.success),
                    ),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}
