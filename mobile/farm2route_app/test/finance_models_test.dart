import 'package:flutter_test/flutter_test.dart';
import 'package:farm2route_app/features/agency/data/finance_models.dart';

void main() {
  test('parses backend summary without converting decimals to double', () {
    final summary = AgencyFinanceSummaryModel.fromJson({
      'grossEarnings': '125000.10',
      'commission': '12500.01',
      'netEarnings': '112500.09',
      'withdrawn': '1000.00',
      'availableBalance': '111500.09',
    });

    expect(summary.grossEarnings, '125000.10');
    expect(summary.availableBalance, '111500.09');
  });

  test('parses nullable transaction and withdrawal fields', () {
    final transaction = FinancialTransactionModel.fromJson({
      'id': 'tx-1',
      'reference': 'BOOKING-1',
      'bookingId': null,
      'amount': 1200.50,
      'commission': '120.05',
      'netAmount': '1080.45',
      'type': 'BOOKING_PAYMENT',
      'status': 'COMPLETED',
      'createdAt': '2026-09-08T10:00:00Z',
    });
    final withdrawal = WithdrawalModel.fromJson({
      'id': 'wd-1',
      'amount': '500.00',
      'status': 'PENDING',
      'createdAt': '2026-09-08T10:00:00Z',
      'updatedAt': null,
    });

    expect(transaction.bookingId, isNull);
    expect(transaction.amount, '1200.5');
    expect(withdrawal.status, 'PENDING');
    expect(withdrawal.updatedAt, isNull);
  });
}
