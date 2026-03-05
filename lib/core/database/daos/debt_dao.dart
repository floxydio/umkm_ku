import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/debt_payments_table.dart';
import '../tables/debts_table.dart';

part 'debt_dao.g.dart';

@DriftAccessor(tables: [DebtsTable, DebtPaymentsTable])
class DebtDao extends DatabaseAccessor<AppDatabase> with _$DebtDaoMixin {
  DebtDao(super.db);

  Stream<List<DebtData>> watchDebtsByCustomer(String customerId) {
    return (select(debtsTable)
          ..where(
            (t) =>
                t.customerId.equals(customerId) & t.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<DebtData>> watchUnpaidDebts() {
    return (select(debtsTable)
          ..where(
            (t) =>
                t.remainingAmount.isBiggerThanValue(0) &
                t.isDeleted.equals(false),
          ))
        .watch();
  }

  Future<DebtData?> getDebtById(String id) {
    return (select(debtsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insertDebt(DebtsTableCompanion entry) {
    return into(debtsTable).insert(entry);
  }

  Future<bool> updateDebt(DebtsTableCompanion entry) {
    return update(debtsTable).replace(entry);
  }

  /// Inserts a payment and atomically updates the debt's paid/remaining amounts.
  /// [entry] must have [debtId] and [amount] set (not absent).
  Future<void> insertPayment(DebtPaymentsTableCompanion entry) async {
    await transaction(() async {
      await into(debtPaymentsTable).insert(entry);

      final debtId = entry.debtId.value;
      final payment = entry.amount.value;

      final debt = await (select(debtsTable)
            ..where((t) => t.id.equals(debtId)))
          .getSingle();

      final newPaid = debt.paidAmount + payment;
      final newRemaining = (debt.amount - newPaid).clamp(0, debt.amount);

      await (update(debtsTable)..where((t) => t.id.equals(debtId))).write(
        DebtsTableCompanion(
          paidAmount: Value(newPaid),
          remainingAmount: Value(newRemaining),
          isSynced: const Value(false),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<List<DebtPaymentData>> getPaymentsByDebt(String debtId) {
    return (select(debtPaymentsTable)
          ..where(
            (t) =>
                t.debtId.equals(debtId) & t.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.paidAt)]))
        .get();
  }

  Future<List<DebtData>> getUnsyncedDebts() {
    return (select(debtsTable)..where((t) => t.isSynced.equals(false))).get();
  }

  Future<List<DebtPaymentData>> getUnsyncedPayments() {
    return (select(debtPaymentsTable)
          ..where((t) => t.isSynced.equals(false)))
        .get();
  }

  Future<void> markDebtsSynced(List<String> ids) async {
    await (update(debtsTable)..where((t) => t.id.isIn(ids))).write(
      const DebtsTableCompanion(isSynced: Value(true)),
    );
  }

  Future<void> markPaymentsSynced(List<String> ids) async {
    await (update(debtPaymentsTable)..where((t) => t.id.isIn(ids))).write(
      const DebtPaymentsTableCompanion(isSynced: Value(true)),
    );
  }

  Future<void> upsertDebtFromRemote(DebtsTableCompanion entry) {
    return into(debtsTable).insertOnConflictUpdate(entry);
  }

  Future<void> upsertPaymentFromRemote(DebtPaymentsTableCompanion entry) {
    return into(debtPaymentsTable).insertOnConflictUpdate(entry);
  }
}
