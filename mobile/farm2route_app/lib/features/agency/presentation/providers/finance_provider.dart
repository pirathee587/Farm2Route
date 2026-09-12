import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/finance_models.dart';
import 'agency_provider.dart';

final agencyFinanceSummaryProvider = FutureProvider<AgencyFinanceSummaryModel>(
  (ref) async {
    final data = await ref.watch(agencyRepositoryProvider).financeSummary();
    return AgencyFinanceSummaryModel.fromJson(Map<String, dynamic>.from(data));
  },
);

final agencyTransactionsProvider =
    FutureProvider<List<FinancialTransactionModel>>((ref) async {
  final data = await ref.watch(agencyRepositoryProvider).transactions();
  return data
      .map((item) => FinancialTransactionModel.fromJson(
          Map<String, dynamic>.from(item as Map)))
      .toList();
});

final agencyWithdrawalsProvider =
    FutureProvider<List<WithdrawalModel>>((ref) async {
  final data = await ref.watch(agencyRepositoryProvider).withdrawals();
  return data
      .map((item) =>
          WithdrawalModel.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
});
