import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/debt_summary_entity.dart';
import '../../domain/repositories/debt_repository.dart';
import '../datasources/debt_local_datasource.dart';

@LazySingleton(as: DebtRepository)
class DebtRepositoryImpl implements DebtRepository {
  final DebtLocalDataSource _datasource;
  final _uuid = const Uuid();

  DebtRepositoryImpl(this._datasource);

  @override
  Stream<Either<Failure, List<CustomerEntity>>> watchCustomers() {
    return _datasource.watchAllCustomers().map((rows) {
      try {
        return Right(rows
            .map((c) => CustomerEntity(
                  id: c.id,
                  name: c.name,
                  phone: c.phone,
                  totalDebt: c.totalDebt,
                ))
            .toList());
      } catch (e) {
        return Left(LocalFailure('Gagal memuat pelanggan: ${e.toString()}'));
      }
    });
  }

  @override
  Future<Either<Failure, Unit>> addCustomer(AddCustomerParams params) async {
    try {
      final now = DateTime.now();
      await _datasource.insertCustomer(
        CustomersTableCompanion(
          id: Value(_uuid.v4()),
          name: Value(params.name),
          phone: Value(params.phone),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      return const Right(unit);
    } catch (e) {
      return Left(LocalFailure('Gagal menambah pelanggan: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> countActiveCustomers() async {
    try {
      final count = await _datasource.countActiveCustomers();
      return Right(count);
    } catch (e) {
      return Left(
          LocalFailure('Gagal menghitung pelanggan: ${e.toString()}'));
    }
  }

  @override
  Stream<Either<Failure, CustomerEntity?>> watchCustomerById(String id) {
    return _datasource.watchCustomerById(id).map((c) {
      try {
        if (c == null) return const Right(null);
        return Right(CustomerEntity(
          id: c.id,
          name: c.name,
          phone: c.phone,
          totalDebt: c.totalDebt,
        ));
      } catch (e) {
        return Left(LocalFailure('Gagal memuat pelanggan: ${e.toString()}'));
      }
    });
  }

  @override
  Stream<Either<Failure, List<DebtEntity>>> watchDebtsByCustomer(
      String customerId) {
    return _datasource.watchDebtsByCustomer(customerId).map((rows) {
      try {
        return Right(rows
            .map((d) => DebtEntity(
                  id: d.id,
                  customerId: d.customerId,
                  amount: d.amount,
                  paidAmount: d.paidAmount,
                  remainingAmount: d.remainingAmount,
                  dueDate: d.dueDate,
                  note: d.note,
                  createdAt: d.createdAt,
                ))
            .toList());
      } catch (e) {
        return Left(LocalFailure('Gagal memuat hutang: ${e.toString()}'));
      }
    });
  }

  @override
  Future<Either<Failure, Unit>> addDebt(AddDebtParams params) async {
    try {
      final now = DateTime.now();
      await _datasource.insertDebtAndUpdateCustomer(
        DebtsTableCompanion(
          id: Value(_uuid.v4()),
          customerId: Value(params.customerId),
          amount: Value(params.amount),
          remainingAmount: Value(params.amount),
          dueDate: Value(params.dueDate),
          note: Value(params.note),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      return const Right(unit);
    } catch (e) {
      return Left(LocalFailure('Gagal mencatat hutang: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> addPayment(
      String debtId, int amount, DateTime paidAt) async {
    try {
      await _datasource.addPayment(
        debtId: debtId,
        amount: amount,
        paidAt: paidAt,
        paymentId: _uuid.v4(),
      );
      return const Right(unit);
    } catch (e) {
      return Left(LocalFailure('Gagal mencatat pembayaran: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, DebtSummaryEntity>> getTotalDebtSummary() async {
    try {
      final data = await _datasource.getTotalDebtSummary();
      return Right(DebtSummaryEntity(
        totalCustomers: data.totalCustomers,
        totalDebt: data.totalDebt,
        totalPaid: data.totalPaid,
        totalRemaining: data.totalRemaining,
      ));
    } catch (e) {
      return Left(
          LocalFailure('Gagal memuat ringkasan hutang: ${e.toString()}'));
    }
  }
}
