import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/customer_dao.dart';
import '../../../../core/database/daos/debt_dao.dart';

class DebtSummaryData {
  final int totalCustomers;
  final int totalDebt;
  final int totalPaid;
  final int totalRemaining;

  const DebtSummaryData({
    required this.totalCustomers,
    required this.totalDebt,
    required this.totalPaid,
    required this.totalRemaining,
  });
}

abstract class DebtLocalDataSource {
  Stream<List<CustomerData>> watchAllCustomers();
  Future<void> insertCustomer(CustomersTableCompanion entry);
  Future<int> countActiveCustomers();
  Stream<CustomerData?> watchCustomerById(String id);
  Stream<List<DebtData>> watchDebtsByCustomer(String customerId);
  Future<void> insertDebtAndUpdateCustomer(DebtsTableCompanion entry);
  Future<void> addPayment({
    required String debtId,
    required int amount,
    required DateTime paidAt,
    required String paymentId,
  });
  Future<DebtSummaryData> getTotalDebtSummary();
}

@LazySingleton(as: DebtLocalDataSource)
class DebtLocalDataSourceImpl implements DebtLocalDataSource {
  final AppDatabase _db;

  DebtLocalDataSourceImpl(this._db);

  CustomerDao get _customerDao => _db.customerDao;
  DebtDao get _debtDao => _db.debtDao;

  @override
  Stream<List<CustomerData>> watchAllCustomers() =>
      _customerDao.watchAllCustomers();

  @override
  Future<void> insertCustomer(CustomersTableCompanion entry) =>
      _customerDao.insertCustomer(entry);

  @override
  Future<int> countActiveCustomers() => _customerDao.countActiveCustomers();

  @override
  Stream<CustomerData?> watchCustomerById(String id) {
    return (_db.select(_db.customersTable)
          ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
        .watchSingleOrNull();
  }

  @override
  Stream<List<DebtData>> watchDebtsByCustomer(String customerId) =>
      _debtDao.watchDebtsByCustomer(customerId);

  @override
  Future<void> insertDebtAndUpdateCustomer(DebtsTableCompanion entry) async {
    await _debtDao.insertDebt(entry);
    final customerId = entry.customerId.value;
    await _recalculateCustomerDebt(customerId);
  }

  @override
  Future<void> addPayment({
    required String debtId,
    required int amount,
    required DateTime paidAt,
    required String paymentId,
  }) async {
    final now = DateTime.now();
    await _debtDao.insertPayment(
      DebtPaymentsTableCompanion(
        id: Value(paymentId),
        debtId: Value(debtId),
        amount: Value(amount),
        paidAt: Value(paidAt),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    final debt = await _debtDao.getDebtById(debtId);
    if (debt != null) {
      await _recalculateCustomerDebt(debt.customerId);
    }
  }

  @override
  Future<DebtSummaryData> getTotalDebtSummary() async {
    final customers = await (_db.select(_db.customersTable)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    final debts = await (_db.select(_db.debtsTable)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    return DebtSummaryData(
      totalCustomers: customers.length,
      totalDebt: debts.fold(0, (sum, d) => sum + d.amount),
      totalPaid: debts.fold(0, (sum, d) => sum + d.paidAmount),
      totalRemaining: debts.fold(0, (sum, d) => sum + d.remainingAmount),
    );
  }

  Future<void> _recalculateCustomerDebt(String customerId) async {
    final allDebts = await (_db.select(_db.debtsTable)
          ..where((t) =>
              t.customerId.equals(customerId) & t.isDeleted.equals(false)))
        .get();
    final totalRemaining =
        allDebts.fold(0, (sum, d) => sum + d.remainingAmount);
    await _customerDao.updateTotalDebt(customerId, totalRemaining);
  }
}
