import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/transaction_items_table.dart';
import '../tables/transactions_table.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [TransactionsTable, TransactionItemsTable])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  // ── Inserts ──────────────────────────────────────────────────────────────

  Future<void> insertTransaction(TransactionsTableCompanion entry) {
    return into(transactionsTable).insert(entry);
  }

  Future<void> insertTransactionItems(
    List<TransactionItemsTableCompanion> items,
  ) async {
    await batch((b) => b.insertAll(transactionItemsTable, items));
  }

  /// Atomically inserts a transaction and all its line items.
  Future<void> saveFullTransaction(
    TransactionsTableCompanion txn,
    List<TransactionItemsTableCompanion> items,
  ) async {
    await transaction(() async {
      await into(transactionsTable).insert(txn);
      await batch((b) => b.insertAll(transactionItemsTable, items));
    });
  }

  // ── Queries ──────────────────────────────────────────────────────────────

  Stream<List<TransactionData>> watchTodayTransactions() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(transactionsTable)
          ..where(
            (t) =>
                t.createdAt.isBiggerOrEqualValue(startOfDay) &
                t.createdAt.isSmallerThanValue(endOfDay) &
                t.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<int> getTodayTotal() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final sumExpr = transactionsTable.totalAmount.sum();
    final query = selectOnly(transactionsTable)
      ..addColumns([sumExpr])
      ..where(
        transactionsTable.createdAt.isBiggerOrEqualValue(startOfDay) &
            transactionsTable.createdAt.isSmallerThanValue(endOfDay) &
            transactionsTable.isDeleted.equals(false),
      );

    final row = await query.getSingle();
    return row.read(sumExpr) ?? 0;
  }

  Future<List<TransactionData>> getUnsyncedTransactions() {
    return (select(transactionsTable)
          ..where((t) => t.isSynced.equals(false)))
        .get();
  }

  Future<List<TransactionItemData>> getItemsByTransaction(
      String transactionId) {
    return (select(transactionItemsTable)
          ..where((t) => t.transactionId.equals(transactionId) &
              t.isDeleted.equals(false)))
        .get();
  }

  Future<List<TransactionItemData>> getUnsyncedItems() {
    return (select(transactionItemsTable)
          ..where((t) => t.isSynced.equals(false)))
        .get();
  }

  Future<void> markTransactionsSynced(List<String> ids) async {
    await (update(transactionsTable)..where((t) => t.id.isIn(ids))).write(
      TransactionsTableCompanion(
        isSynced: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
