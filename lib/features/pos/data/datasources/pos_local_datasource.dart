import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/product_dao.dart';
import '../../../../core/database/daos/stock_dao.dart';
import '../../../../core/database/daos/transaction_dao.dart';
import '../../../../core/database/tables/app_users_table.dart';

abstract class PosLocalDataSource {
  /// Ensures a cashier row exists in app_users; returns the userId.
  Future<String> ensureCashier(String userId, String userName);

  /// Atomically saves transaction + items, then updates stock and logs.
  Future<void> saveFullTransaction(
    TransactionsTableCompanion txn,
    List<TransactionItemsTableCompanion> items,
    List<({String productId, int newStock})> stockUpdates,
    List<StockLogsTableCompanion> stockLogs,
  );

  Stream<List<TransactionData>> watchTodayTransactions();

  Future<List<TransactionItemData>> getItemsByTransaction(String transactionId);

  Future<int> getTodayTotal();

  Future<int> getTodayTransactionCount();

  Future<ProductData?> getProductById(String id);
}

@LazySingleton(as: PosLocalDataSource)
class PosLocalDataSourceImpl implements PosLocalDataSource {
  final AppDatabase _db;

  PosLocalDataSourceImpl(this._db);

  TransactionDao get _txnDao => _db.transactionDao;
  ProductDao get _productDao => _db.productDao;
  StockDao get _stockDao => _db.stockDao;

  @override
  Future<String> ensureCashier(String userId, String userName) async {
    final existing = await (_db.select(_db.appUsersTable)
          ..where((t) => t.id.equals(userId) & t.isDeleted.equals(false)))
        .getSingleOrNull();

    if (existing != null) return userId;

    final now = DateTime.now();
    await _db.into(_db.appUsersTable).insert(
          AppUsersTableCompanion(
            id: Value(userId),
            name: Value(userName),
            role: const Value('owner'),
            isActive: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return userId;
  }

  @override
  Future<void> saveFullTransaction(
    TransactionsTableCompanion txn,
    List<TransactionItemsTableCompanion> items,
    List<({String productId, int newStock})> stockUpdates,
    List<StockLogsTableCompanion> stockLogs,
  ) async {
    await _db.transaction(() async {
      // 1. Insert transaction + items atomically
      await _txnDao.saveFullTransaction(txn, items);

      // 2. Update product stock
      for (final update in stockUpdates) {
        await _productDao.updateStock(update.productId, update.newStock);
      }

      // 3. Log stock changes
      for (final log in stockLogs) {
        await _stockDao.insertStockLog(log);
      }
    });
  }

  @override
  Stream<List<TransactionData>> watchTodayTransactions() {
    return _txnDao.watchTodayTransactions();
  }

  @override
  Future<List<TransactionItemData>> getItemsByTransaction(
      String transactionId) {
    return _txnDao.getItemsByTransaction(transactionId);
  }

  @override
  Future<int> getTodayTotal() {
    return _txnDao.getTodayTotal();
  }

  @override
  Future<int> getTodayTransactionCount() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final countExpr = _db.transactionsTable.id.count();
    final query = _db.selectOnly(_db.transactionsTable)
      ..addColumns([countExpr])
      ..where(
        _db.transactionsTable.createdAt.isBiggerOrEqualValue(startOfDay) &
            _db.transactionsTable.createdAt.isSmallerThanValue(endOfDay) &
            _db.transactionsTable.isDeleted.equals(false),
      );

    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  @override
  Future<ProductData?> getProductById(String id) {
    return _productDao.getProductById(id);
  }
}
