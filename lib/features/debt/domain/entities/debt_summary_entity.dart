import 'package:equatable/equatable.dart';

class DebtSummaryEntity extends Equatable {
  final int totalCustomers;
  final int totalDebt;
  final int totalPaid;
  final int totalRemaining;

  const DebtSummaryEntity({
    required this.totalCustomers,
    required this.totalDebt,
    required this.totalPaid,
    required this.totalRemaining,
  });

  @override
  List<Object?> get props => [
        totalCustomers,
        totalDebt,
        totalPaid,
        totalRemaining,
      ];
}
