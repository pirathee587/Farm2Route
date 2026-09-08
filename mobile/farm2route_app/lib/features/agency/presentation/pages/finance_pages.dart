import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/agrizel_card.dart';
import '../../data/finance_models.dart';
import '../providers/agency_provider.dart';
import '../providers/finance_provider.dart';

class FinanceOverviewPage extends ConsumerWidget {
  const FinanceOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agencyFinanceSummaryProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _FinanceError(
        message: 'Unable to load finance summary',
        onRetry: () => ref.invalidate(agencyFinanceSummaryProvider),
      ),
      data: (summary) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(agencyFinanceSummaryProvider),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('Finance', style: AppTextStyles.headingLarge),
                ),
                FilledButton.icon(
                  onPressed: () =>
                      context.go('/agency/finance/withdrawals/new'),
                  icon: const Icon(Icons.request_page_outlined),
                  label: const Text('Withdraw'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Backend-calculated agency earnings and balance',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            _SummaryGrid(summary: summary),
            const SizedBox(height: 24),
            _FinanceLinkCard(
              icon: Icons.receipt_long,
              title: 'Transactions',
              subtitle: 'Review financial transaction history',
              onTap: () => context.go('/agency/finance/transactions'),
            ),
            const SizedBox(height: 12),
            _FinanceLinkCard(
              icon: Icons.payments_outlined,
              title: 'Withdrawal requests',
              subtitle: 'View request status and history',
              onTap: () => context.go('/agency/finance/withdrawals'),
            ),
          ],
        ),
      ),
    );
  }
}

class FinanceTransactionsPage extends ConsumerWidget {
  const FinanceTransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agencyTransactionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _FinanceError(
          message: 'Unable to load transactions',
          onRetry: () => ref.invalidate(agencyTransactionsProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(agencyTransactionsProvider),
          child: items.isEmpty
              ? ListView(children: const [
                  _FinanceEmpty(message: 'No financial transactions found.')
                ])
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: items.length,
                  itemBuilder: (_, index) => _TransactionCard(
                    transaction: items[index],
                  ),
                ),
        ),
      ),
    );
  }
}

class FinanceWithdrawalsPage extends ConsumerWidget {
  const FinanceWithdrawalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agencyWithdrawalsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdrawal requests'),
        actions: [
          IconButton(
            tooltip: 'Request withdrawal',
            onPressed: () => context.go('/agency/finance/withdrawals/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _FinanceError(
          message: 'Unable to load withdrawal requests',
          onRetry: () => ref.invalidate(agencyWithdrawalsProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(agencyWithdrawalsProvider),
          child: items.isEmpty
              ? ListView(children: const [
                  _FinanceEmpty(message: 'No withdrawal requests found.')
                ])
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: items.length,
                  itemBuilder: (_, index) => _WithdrawalCard(
                    withdrawal: items[index],
                  ),
                ),
        ),
      ),
    );
  }
}

class WithdrawalFormPage extends ConsumerStatefulWidget {
  const WithdrawalFormPage({super.key});

  @override
  ConsumerState<WithdrawalFormPage> createState() => _WithdrawalFormPageState();
}

class _WithdrawalFormPageState extends ConsumerState<WithdrawalFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final summary = ref.read(agencyFinanceSummaryProvider).valueOrNull;
    if (summary == null) {
      _showMessage(
          'Refresh the finance summary before requesting a withdrawal.');
      return;
    }
    final amount = _amountController.text.trim();
    if (_compareDecimal(amount, summary.availableBalance) > 0) {
      _showMessage(
          'The requested amount exceeds the displayed available balance.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm withdrawal'),
        content: Text(
          'Request $amount from the available balance of '
          '${summary.availableBalance}? The backend will validate the current balance and primary bank account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await ref.read(agencyRepositoryProvider).withdraw({'amount': amount});
      ref.invalidate(agencyFinanceSummaryProvider);
      ref.invalidate(agencyWithdrawalsProvider);
      ref.invalidate(agencyTransactionsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdrawal request submitted.')),
      );
      context.go('/agency/finance/withdrawals');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_friendlyFinanceError(error));
      if (error is AppException && error.statusCode == 409) {
        ref.invalidate(agencyFinanceSummaryProvider);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(agencyFinanceSummaryProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Request withdrawal')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (summary != null)
            AgrizelCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Available balance'),
                subtitle: Text(summary.availableBalance,
                    style: AppTextStyles.headingSmall),
              ),
            ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Withdrawal amount',
                hintText: '0.00',
                border: OutlineInputBorder(),
              ),
              validator: _validateAmount,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The backend uses the agency primary bank account. No bank details are entered here.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Review request'),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateAmount(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter an amount';
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
      return 'Enter a valid decimal amount';
    }
    if (_compareDecimal(text, '0') <= 0) return 'Amount must be positive';
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SummaryGrid extends StatelessWidget {
  final AgencyFinanceSummaryModel summary;
  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cards = [
      ('Gross earnings', summary.grossEarnings, Icons.trending_up),
      ('Commission', summary.commission, Icons.percent),
      ('Net earnings', summary.netEarnings, Icons.account_balance),
      ('Withdrawn', summary.withdrawn, Icons.outbox),
      ('Available balance', summary.availableBalance, Icons.wallet),
    ];
    final columns = MediaQuery.sizeOf(context).width >= 1000 ? 3 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.7,
      ),
      itemBuilder: (_, index) {
        final card = cards[index];
        return AgrizelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(card.$3, color: AppColors.primary),
              const SizedBox(height: 10),
              Text(card.$2, style: AppTextStyles.headingSmall),
              Text(card.$1,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        );
      },
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final FinancialTransactionModel transaction;
  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return AgrizelCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(_label(transaction.type),
                    style: AppTextStyles.headingSmall),
              ),
              _StatusChip(value: transaction.status),
            ],
          ),
          const SizedBox(height: 12),
          _DataLine('Amount', transaction.amount),
          _DataLine('Commission', transaction.commission),
          _DataLine('Net amount', transaction.netAmount),
          if (transaction.reference != null)
            _DataLine('Reference', transaction.reference!),
          if (transaction.bookingId != null)
            _DataLine('Booking ID', transaction.bookingId!),
          if (transaction.createdAt != null)
            _DataLine('Created', _date(transaction.createdAt!)),
        ],
      ),
    );
  }
}

class _WithdrawalCard extends StatelessWidget {
  final WithdrawalModel withdrawal;
  const _WithdrawalCard({required this.withdrawal});

  @override
  Widget build(BuildContext context) {
    return AgrizelCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.payments_outlined, color: AppColors.primary),
        title: Text(withdrawal.amount, style: AppTextStyles.headingSmall),
        subtitle: Text([
          if (withdrawal.createdAt != null) _date(withdrawal.createdAt!),
          'ID ${withdrawal.id}',
        ].join(' • ')),
        trailing: _StatusChip(value: withdrawal.status),
      ),
    );
  }
}

class _FinanceLinkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _FinanceLinkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => AgrizelCard(
        onTap: onTap,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: AppColors.primary),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  final String value;
  const _StatusChip({required this.value});

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(_label(value)),
        visualDensity: VisualDensity.compact,
      );
}

class _DataLine extends StatelessWidget {
  final String label;
  final String value;
  const _DataLine(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 105,
              child: Text(label,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}

class _FinanceError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _FinanceError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

class _FinanceEmpty extends StatelessWidget {
  final String message;
  const _FinanceEmpty({required this.message});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(48),
        child: Center(child: Text(message)),
      );
}

String _label(String value) => value
    .replaceAll('_', ' ')
    .toLowerCase()
    .split(' ')
    .map((word) =>
        word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

String _date(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return parsed.toLocal().toString().split('.').first;
}

String _friendlyFinanceError(Object error) {
  if (error is AppException) {
    if (error.statusCode == 409) {
      return 'The balance changed while processing the request. Finance data was refreshed; please try again.';
    }
    if (error.statusCode == 400 || error.statusCode == 422) {
      return error.message;
    }
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'You are not authorized to request an agency withdrawal.';
    }
    return 'Unable to submit the withdrawal request. Please try again.';
  }
  return 'Unable to submit the withdrawal request. Please try again.';
}

int _compareDecimal(String left, String right) {
  final a = _minorUnits(left);
  final b = _minorUnits(right);
  return a.compareTo(b);
}

BigInt _minorUnits(String value) {
  final parts = value.split('.');
  final whole = BigInt.tryParse(parts.first) ?? BigInt.zero;
  final fraction =
      parts.length > 1 ? parts[1].padRight(2, '0').substring(0, 2) : '00';
  return whole * BigInt.from(100) + BigInt.parse(fraction);
}
