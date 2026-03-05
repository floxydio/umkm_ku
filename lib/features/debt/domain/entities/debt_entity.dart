import 'package:equatable/equatable.dart';

class DebtPaymentEntity extends Equatable {
  final String id;
  final String debtId;
  final int amount;
  final DateTime paidAt;

  const DebtPaymentEntity({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.paidAt,
  });

  @override
  List<Object?> get props => [id, debtId, amount, paidAt];
}

class DebtEntity extends Equatable {
  final String id;
  final String customerId;
  final int amount;
  final int paidAmount;
  final int remainingAmount;
  final DateTime? dueDate;
  final String? note;
  final DateTime createdAt;
  final List<DebtPaymentEntity> payments;

  const DebtEntity({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.paidAmount,
    required this.remainingAmount,
    this.dueDate,
    this.note,
    required this.createdAt,
    this.payments = const [],
  });

  bool get isPaid => remainingAmount <= 0;

  @override
  List<Object?> get props => [
        id,
        customerId,
        amount,
        paidAmount,
        remainingAmount,
        dueDate,
        note,
        createdAt,
        payments,
      ];
}
