class AgencyFinanceSummaryModel {
  final String grossEarnings;
  final String commission;
  final String netEarnings;
  final String withdrawn;
  final String availableBalance;

  const AgencyFinanceSummaryModel({
    required this.grossEarnings,
    required this.commission,
    required this.netEarnings,
    required this.withdrawn,
    required this.availableBalance,
  });

  factory AgencyFinanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return AgencyFinanceSummaryModel(
      grossEarnings: _decimal(json['grossEarnings']),
      commission: _decimal(json['commission']),
      netEarnings: _decimal(json['netEarnings']),
      withdrawn: _decimal(json['withdrawn']),
      availableBalance: _decimal(json['availableBalance']),
    );
  }
}

class FinancialTransactionModel {
  final String id;
  final String? reference;
  final String? bookingId;
  final String amount;
  final String commission;
  final String netAmount;
  final String type;
  final String status;
  final String? createdAt;

  const FinancialTransactionModel({
    required this.id,
    this.reference,
    this.bookingId,
    required this.amount,
    required this.commission,
    required this.netAmount,
    required this.type,
    required this.status,
    this.createdAt,
  });

  factory FinancialTransactionModel.fromJson(Map<String, dynamic> json) {
    return FinancialTransactionModel(
      id: '${json['id'] ?? ''}',
      reference: _optional(json['reference']),
      bookingId: _optional(json['bookingId']),
      amount: _decimal(json['amount']),
      commission: _decimal(json['commission']),
      netAmount: _decimal(json['netAmount']),
      type: '${json['type'] ?? ''}',
      status: '${json['status'] ?? ''}',
      createdAt: _optional(json['createdAt']),
    );
  }
}

class WithdrawalModel {
  final String id;
  final String amount;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  const WithdrawalModel({
    required this.id,
    required this.amount,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalModel(
      id: '${json['id'] ?? ''}',
      amount: _decimal(json['amount']),
      status: '${json['status'] ?? ''}',
      createdAt: _optional(json['createdAt']),
      updatedAt: _optional(json['updatedAt']),
    );
  }
}

String _decimal(Object? value) => value == null ? '0.00' : value.toString();

String? _optional(Object? value) => value?.toString();
