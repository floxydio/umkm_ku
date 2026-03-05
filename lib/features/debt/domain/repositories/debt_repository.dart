import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/customer_entity.dart';
import '../entities/debt_entity.dart';
import '../entities/debt_summary_entity.dart';

class AddCustomerParams {
  final String name;
  final String phone;

  const AddCustomerParams({required this.name, required this.phone});
}

class AddDebtParams {
  final String customerId;
  final int amount;
  final DateTime? dueDate;
  final String? note;

  const AddDebtParams({
    required this.customerId,
    required this.amount,
    this.dueDate,
    this.note,
  });
}

abstract class DebtRepository {
  Stream<Either<Failure, List<CustomerEntity>>> watchCustomers();

  Future<Either<Failure, Unit>> addCustomer(AddCustomerParams params);

  Future<Either<Failure, int>> countActiveCustomers();

  Stream<Either<Failure, CustomerEntity?>> watchCustomerById(String id);

  Stream<Either<Failure, List<DebtEntity>>> watchDebtsByCustomer(
      String customerId);

  Future<Either<Failure, Unit>> addDebt(AddDebtParams params);

  Future<Either<Failure, Unit>> addPayment(
      String debtId, int amount, DateTime paidAt);

  Future<Either<Failure, DebtSummaryEntity>> getTotalDebtSummary();
}
