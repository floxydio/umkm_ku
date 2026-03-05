import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';
import '../database/tables/app_users_table.dart';
import '../database/tables/categories_table.dart';
import '../database/tables/customers_table.dart';
import '../database/tables/debt_payments_table.dart';
import '../database/tables/debts_table.dart';
import '../database/tables/products_table.dart';
import '../database/tables/purchased_features_table.dart';
import '../database/tables/stock_logs_table.dart';
import '../database/tables/transaction_items_table.dart';
import '../database/tables/transactions_table.dart';

@lazySingleton
class SyncEngine {
  final AppDatabase _db;
  final SupabaseClient _supabase;
  final SharedPreferences _prefs;

  static const String _lastSyncKey = 'last_synced_at';

  SyncEngine(this._db, this._supabase, this._prefs);

  DateTime? get lastSyncedAt {
    final ms = _prefs.getInt(_lastSyncKey);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  Future<bool> isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  Future<void> sync() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    if (!await isConnected()) return;

    final userId = user.id;
    await pushLocalChanges(userId);
    await pushDeletedRows(userId);
    await pullRemoteChanges(userId);
    await _updateLastSyncedAt();
  }

  // ── Push local (active) ──────────────────────────────────────────────────

  Future<void> pushLocalChanges(String userId) async {
    await _pushTable<CategoryData>(
      fetchUnsynced: _db.categoryDao.getUnsyncedCategories,
      toMap: (r) => _categoryToMap(r, userId),
      getId: (r) => r.id,
      isDeleted: (r) => r.isDeleted,
      tableName: 'categories',
      markSynced: _db.categoryDao.markSynced,
    );
    await _pushTable<CustomerData>(
      fetchUnsynced: _db.customerDao.getUnsyncedCustomers,
      toMap: (r) => _customerToMap(r, userId),
      getId: (r) => r.id,
      isDeleted: (r) => r.isDeleted,
      tableName: 'customers',
      markSynced: _db.customerDao.markSynced,
    );
    await _pushTable<ProductData>(
      fetchUnsynced: _db.productDao.getUnsyncedProducts,
      toMap: (r) => _productToMap(r, userId),
      getId: (r) => r.id,
      isDeleted: (r) => r.isDeleted,
      tableName: 'products',
      markSynced: _db.productDao.markSynced,
    );
    await _pushTransactions(userId, activeOnly: true);
    await _pushTable<DebtData>(
      fetchUnsynced: _db.debtDao.getUnsyncedDebts,
      toMap: (r) => _debtToMap(r, userId),
      getId: (r) => r.id,
      isDeleted: (r) => r.isDeleted,
      tableName: 'debts',
      markSynced: _db.debtDao.markDebtsSynced,
    );
    await _pushTable<DebtPaymentData>(
      fetchUnsynced: _db.debtDao.getUnsyncedPayments,
      toMap: (r) => _debtPaymentToMap(r, userId),
      getId: (r) => r.id,
      isDeleted: (r) => r.isDeleted,
      tableName: 'debt_payments',
      markSynced: _db.debtDao.markPaymentsSynced,
    );
    await _pushTable<StockLogData>(
      fetchUnsynced: _db.stockDao.getUnsyncedStockLogs,
      toMap: (r) => _stockLogToMap(r, userId),
      getId: (r) => r.id,
      isDeleted: (r) => r.isDeleted,
      tableName: 'stock_logs',
      markSynced: _db.stockDao.markSynced,
    );
    await _pushTable<PurchasedFeatureData>(
      fetchUnsynced: _db.featureDao.getUnsyncedFeatures,
      toMap: (r) => _featureToMap(r, userId),
      getId: (r) => r.id,
      isDeleted: (r) => r.isDeleted,
      tableName: 'purchased_features',
      markSynced: _db.featureDao.markSynced,
    );
    await _pushAppUsers(userId, activeOnly: true);
  }

  // ── Push deleted ─────────────────────────────────────────────────────────

  Future<void> pushDeletedRows(String userId) async {
    await _pushTable<CategoryData>(
      fetchUnsynced: _db.categoryDao.getUnsyncedCategories,
      toMap: (r) => _categoryToMap(r, userId),
      getId: (r) => r.id,
      isDeleted: (r) => r.isDeleted,
      tableName: 'categories',
      markSynced: _db.categoryDao.markSynced,
      deletedOnly: true,
    );
    await _pushTable<CustomerData>(
      fetchUnsynced: _db.customerDao.getUnsyncedCustomers,
      toMap: (r) => _customerToMap(r, userId),
      getId: (r) => r.id,
      isDeleted: (r) => r.isDeleted,
      tableName: 'customers',
      markSynced: _db.customerDao.markSynced,
      deletedOnly: true,
    );
    await _pushTable<ProductData>(
      fetchUnsynced: _db.productDao.getUnsyncedProducts,
      toMap: (r) => _productToMap(r, userId),
      getId: (r) => r.id,
      isDeleted: (r) => r.isDeleted,
      tableName: 'products',
      markSynced: _db.productDao.markSynced,
      deletedOnly: true,
    );
    await _pushTransactions(userId, activeOnly: false, deletedOnly: true);
    await _pushTable<DebtData>(
      fetchUnsynced: _db.debtDao.getUnsyncedDebts,
      toMap: (r) => _debtToMap(r, userId),
      getId: (r) => r.id,
      isDeleted: (r) => r.isDeleted,
      tableName: 'debts',
      markSynced: _db.debtDao.markDebtsSynced,
      deletedOnly: true,
    );
    await _pushTable<DebtPaymentData>(
      fetchUnsynced: _db.debtDao.getUnsyncedPayments,
      toMap: (r) => _debtPaymentToMap(r, userId),
      getId: (r) => r.id,
      isDeleted: (r) => r.isDeleted,
      tableName: 'debt_payments',
      markSynced: _db.debtDao.markPaymentsSynced,
      deletedOnly: true,
    );
    await _pushTable<StockLogData>(
      fetchUnsynced: _db.stockDao.getUnsyncedStockLogs,
      toMap: (r) => _stockLogToMap(r, userId),
      getId: (r) => r.id,
      isDeleted: (r) => r.isDeleted,
      tableName: 'stock_logs',
      markSynced: _db.stockDao.markSynced,
      deletedOnly: true,
    );
    await _pushTable<PurchasedFeatureData>(
      fetchUnsynced: _db.featureDao.getUnsyncedFeatures,
      toMap: (r) => _featureToMap(r, userId),
      getId: (r) => r.id,
      isDeleted: (r) => r.isDeleted,
      tableName: 'purchased_features',
      markSynced: _db.featureDao.markSynced,
      deletedOnly: true,
    );
    await _pushAppUsers(userId, activeOnly: false, deletedOnly: true);
  }

  // ── Generic push helper ──────────────────────────────────────────────────

  Future<void> _pushTable<T>({
    required Future<List<T>> Function() fetchUnsynced,
    required Map<String, dynamic> Function(T) toMap,
    required String Function(T) getId,
    required bool Function(T) isDeleted,
    required String tableName,
    required Future<void> Function(List<String>) markSynced,
    bool deletedOnly = false,
    bool activeOnly = true,
  }) async {
    final all = await fetchUnsynced();
    final rows = deletedOnly
        ? all.where((r) => isDeleted(r)).toList()
        : all.where((r) => !isDeleted(r)).toList();
    if (rows.isEmpty) return;

    await _supabase.from(tableName).upsert(rows.map(toMap).toList());
    await markSynced(rows.map(getId).toList());
  }

  // ── Transactions (header + items together) ───────────────────────────────

  Future<void> _pushTransactions(
    String userId, {
    bool activeOnly = false,
    bool deletedOnly = false,
  }) async {
    // Headers
    final allTxns = await _db.transactionDao.getUnsyncedTransactions();
    final txns = deletedOnly
        ? allTxns.where((t) => t.isDeleted).toList()
        : allTxns.where((t) => !t.isDeleted).toList();
    if (txns.isNotEmpty) {
      await _supabase
          .from('transactions')
          .upsert(txns.map((t) => _transactionToMap(t, userId)).toList());
      await _db.transactionDao
          .markTransactionsSynced(txns.map((t) => t.id).toList());
    }

    // Items
    final allItems = await _db.transactionDao.getUnsyncedItems();
    final items = deletedOnly
        ? allItems.where((i) => i.isDeleted).toList()
        : allItems.where((i) => !i.isDeleted).toList();
    if (items.isNotEmpty) {
      await _supabase
          .from('transaction_items')
          .upsert(items.map((i) => _transactionItemToMap(i, userId)).toList());
      await _db.transactionDao
          .markItemsSynced(items.map((i) => i.id).toList());
    }
  }

  // ── App users (no DAO — access DB directly) ──────────────────────────────

  Future<void> _pushAppUsers(
    String userId, {
    bool activeOnly = false,
    bool deletedOnly = false,
  }) async {
    final query = _db.select(_db.appUsersTable)
      ..where(
        (t) => deletedOnly
            ? t.isSynced.equals(false) & t.isDeleted.equals(true)
            : t.isSynced.equals(false) & t.isDeleted.equals(false),
      );
    final rows = await query.get();
    if (rows.isEmpty) return;

    await _supabase
        .from('app_users')
        .upsert(rows.map((u) => _appUserToMap(u, userId)).toList());
    await (_db.update(_db.appUsersTable)
          ..where((t) => t.id.isIn(rows.map((u) => u.id).toList())))
        .write(const AppUsersTableCompanion(isSynced: Value(true)));
  }

  // ── Pull remote changes ──────────────────────────────────────────────────

  Future<void> pullRemoteChanges(String userId) async {
    final since = lastSyncedAt?.toUtc().toIso8601String() ??
        DateTime.fromMillisecondsSinceEpoch(0).toIso8601String();

    await _pullCategories(userId, since);
    await _pullCustomers(userId, since);
    await _pullProducts(userId, since);
    await _pullTransactions(userId, since);
    await _pullTransactionItems(userId, since);
    await _pullDebts(userId, since);
    await _pullDebtPayments(userId, since);
    await _pullStockLogs(userId, since);
    await _pullFeatures(userId, since);
    await _pullAppUsers(userId, since);
  }

  Future<void> _pullCategories(String userId, String since) async {
    final rows = await _supabase
        .from('categories')
        .select()
        .eq('user_id', userId)
        .gte('updated_at', since);
    for (final row in rows) {
      await _db.categoryDao.upsertFromRemote(_categoryFromMap(row));
    }
  }

  Future<void> _pullCustomers(String userId, String since) async {
    final rows = await _supabase
        .from('customers')
        .select()
        .eq('user_id', userId)
        .gte('updated_at', since);
    for (final row in rows) {
      await _db.customerDao.upsertFromRemote(_customerFromMap(row));
    }
  }

  Future<void> _pullProducts(String userId, String since) async {
    final rows = await _supabase
        .from('products')
        .select()
        .eq('user_id', userId)
        .gte('updated_at', since);
    for (final row in rows) {
      await _db.productDao.upsertFromRemote(_productFromMap(row));
    }
  }

  Future<void> _pullTransactions(String userId, String since) async {
    final rows = await _supabase
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .gte('updated_at', since);
    for (final row in rows) {
      await _db.transactionDao
          .upsertTransactionFromRemote(_transactionFromMap(row));
    }
  }

  Future<void> _pullTransactionItems(String userId, String since) async {
    final rows = await _supabase
        .from('transaction_items')
        .select()
        .eq('user_id', userId)
        .gte('updated_at', since);
    for (final row in rows) {
      await _db.transactionDao.upsertItemFromRemote(_transactionItemFromMap(row));
    }
  }

  Future<void> _pullDebts(String userId, String since) async {
    final rows = await _supabase
        .from('debts')
        .select()
        .eq('user_id', userId)
        .gte('updated_at', since);
    for (final row in rows) {
      await _db.debtDao.upsertDebtFromRemote(_debtFromMap(row));
    }
  }

  Future<void> _pullDebtPayments(String userId, String since) async {
    final rows = await _supabase
        .from('debt_payments')
        .select()
        .eq('user_id', userId)
        .gte('updated_at', since);
    for (final row in rows) {
      await _db.debtDao.upsertPaymentFromRemote(_debtPaymentFromMap(row));
    }
  }

  Future<void> _pullStockLogs(String userId, String since) async {
    final rows = await _supabase
        .from('stock_logs')
        .select()
        .eq('user_id', userId)
        .gte('updated_at', since);
    for (final row in rows) {
      await _db.stockDao.upsertFromRemote(_stockLogFromMap(row));
    }
  }

  Future<void> _pullFeatures(String userId, String since) async {
    final rows = await _supabase
        .from('purchased_features')
        .select()
        .eq('user_id', userId)
        .gte('updated_at', since);
    for (final row in rows) {
      await _db.featureDao.upsertFromRemote(_featureFromMap(row));
    }
  }

  Future<void> _pullAppUsers(String userId, String since) async {
    final rows = await _supabase
        .from('app_users')
        .select()
        .eq('user_id', userId)
        .gte('updated_at', since);
    for (final row in rows) {
      await _db
          .into(_db.appUsersTable)
          .insertOnConflictUpdate(_appUserFromMap(row));
    }
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  Future<void> _updateLastSyncedAt() async {
    await _prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  // ── toMap: local → Supabase ───────────────────────────────────────────────

  Map<String, dynamic> _categoryToMap(CategoryData c, String userId) => {
        'id': c.id,
        'name': c.name,
        'created_at': c.createdAt.toUtc().toIso8601String(),
        'updated_at': c.updatedAt.toUtc().toIso8601String(),
        'is_deleted': c.isDeleted,
        'user_id': userId,
      };

  Map<String, dynamic> _customerToMap(CustomerData c, String userId) => {
        'id': c.id,
        'name': c.name,
        'phone': c.phone,
        'total_debt': c.totalDebt,
        'created_at': c.createdAt.toUtc().toIso8601String(),
        'updated_at': c.updatedAt.toUtc().toIso8601String(),
        'is_deleted': c.isDeleted,
        'user_id': userId,
      };

  Map<String, dynamic> _productToMap(ProductData p, String userId) => {
        'id': p.id,
        'name': p.name,
        'price': p.price,
        'cost_price': p.costPrice,
        'stock': p.stock,
        'min_stock': p.minStock,
        'category_id': p.categoryId,
        'image_url': p.imageUrl,
        'created_at': p.createdAt.toUtc().toIso8601String(),
        'updated_at': p.updatedAt.toUtc().toIso8601String(),
        'is_deleted': p.isDeleted,
        'user_id': userId,
      };

  Map<String, dynamic> _transactionToMap(TransactionData t, String userId) => {
        'id': t.id,
        'total_amount': t.totalAmount,
        'discount_amount': t.discountAmount,
        'paid_amount': t.paidAmount,
        'change_amount': t.changeAmount,
        'cashier_id': t.cashierId,
        'note': t.note,
        'created_at': t.createdAt.toUtc().toIso8601String(),
        'updated_at': t.updatedAt.toUtc().toIso8601String(),
        'is_deleted': t.isDeleted,
        'user_id': userId,
      };

  Map<String, dynamic> _transactionItemToMap(
    TransactionItemData i,
    String userId,
  ) =>
      {
        'id': i.id,
        'transaction_id': i.transactionId,
        'product_id': i.productId,
        'product_name': i.productName,
        'quantity': i.quantity,
        'unit_price': i.unitPrice,
        'subtotal': i.subtotal,
        'created_at': i.createdAt.toUtc().toIso8601String(),
        'updated_at': i.updatedAt.toUtc().toIso8601String(),
        'is_deleted': i.isDeleted,
        'user_id': userId,
      };

  Map<String, dynamic> _debtToMap(DebtData d, String userId) => {
        'id': d.id,
        'customer_id': d.customerId,
        'amount': d.amount,
        'paid_amount': d.paidAmount,
        'remaining_amount': d.remainingAmount,
        'due_date': d.dueDate?.toUtc().toIso8601String(),
        'note': d.note,
        'created_at': d.createdAt.toUtc().toIso8601String(),
        'updated_at': d.updatedAt.toUtc().toIso8601String(),
        'is_deleted': d.isDeleted,
        'user_id': userId,
      };

  Map<String, dynamic> _debtPaymentToMap(
    DebtPaymentData p,
    String userId,
  ) =>
      {
        'id': p.id,
        'debt_id': p.debtId,
        'amount': p.amount,
        'paid_at': p.paidAt.toUtc().toIso8601String(),
        'created_at': p.createdAt.toUtc().toIso8601String(),
        'updated_at': p.updatedAt.toUtc().toIso8601String(),
        'is_deleted': p.isDeleted,
        'user_id': userId,
      };

  Map<String, dynamic> _stockLogToMap(StockLogData s, String userId) => {
        'id': s.id,
        'product_id': s.productId,
        'type': s.type,
        'quantity': s.quantity,
        'note': s.note,
        'created_at': s.createdAt.toUtc().toIso8601String(),
        'updated_at': s.updatedAt.toUtc().toIso8601String(),
        'is_deleted': s.isDeleted,
        'user_id': userId,
      };

  Map<String, dynamic> _featureToMap(PurchasedFeatureData f, String userId) =>
      {
        'id': f.id,
        'feature_key': f.featureKey,
        'purchased_at': f.purchasedAt.toUtc().toIso8601String(),
        'expires_at': f.expiresAt?.toUtc().toIso8601String(),
        'created_at': f.createdAt.toUtc().toIso8601String(),
        'updated_at': f.updatedAt.toUtc().toIso8601String(),
        'is_deleted': f.isDeleted,
        'user_id': userId,
      };

  Map<String, dynamic> _appUserToMap(AppUserData u, String userId) => {
        'id': u.id,
        'name': u.name,
        'role': u.role,
        'pin': u.pin,
        'is_active': u.isActive,
        'created_at': u.createdAt.toUtc().toIso8601String(),
        'updated_at': u.updatedAt.toUtc().toIso8601String(),
        'is_deleted': u.isDeleted,
        'user_id': userId,
      };

  // ── fromMap: Supabase → local companion ───────────────────────────────────

  CategoriesTableCompanion _categoryFromMap(Map<String, dynamic> row) =>
      CategoriesTableCompanion(
        id: Value(row['id'] as String),
        name: Value(row['name'] as String),
        createdAt: Value(DateTime.parse(row['created_at'] as String)),
        updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
        isDeleted: Value((row['is_deleted'] as bool?) ?? false),
        isSynced: const Value(true),
      );

  CustomersTableCompanion _customerFromMap(Map<String, dynamic> row) =>
      CustomersTableCompanion(
        id: Value(row['id'] as String),
        name: Value(row['name'] as String),
        phone: Value(row['phone'] as String),
        totalDebt: Value((row['total_debt'] as int?) ?? 0),
        createdAt: Value(DateTime.parse(row['created_at'] as String)),
        updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
        isDeleted: Value((row['is_deleted'] as bool?) ?? false),
        isSynced: const Value(true),
      );

  ProductsTableCompanion _productFromMap(Map<String, dynamic> row) =>
      ProductsTableCompanion(
        id: Value(row['id'] as String),
        name: Value(row['name'] as String),
        price: Value(row['price'] as int),
        costPrice: Value(row['cost_price'] as int),
        stock: Value(row['stock'] as int),
        minStock: Value((row['min_stock'] as int?) ?? 0),
        categoryId: Value(row['category_id'] as String),
        imageUrl: Value(row['image_url'] as String?),
        createdAt: Value(DateTime.parse(row['created_at'] as String)),
        updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
        isDeleted: Value((row['is_deleted'] as bool?) ?? false),
        isSynced: const Value(true),
      );

  TransactionsTableCompanion _transactionFromMap(Map<String, dynamic> row) =>
      TransactionsTableCompanion(
        id: Value(row['id'] as String),
        totalAmount: Value(row['total_amount'] as int),
        discountAmount: Value((row['discount_amount'] as int?) ?? 0),
        paidAmount: Value(row['paid_amount'] as int),
        changeAmount: Value(row['change_amount'] as int),
        cashierId: Value(row['cashier_id'] as String),
        note: Value(row['note'] as String?),
        createdAt: Value(DateTime.parse(row['created_at'] as String)),
        updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
        isDeleted: Value((row['is_deleted'] as bool?) ?? false),
        isSynced: const Value(true),
      );

  TransactionItemsTableCompanion _transactionItemFromMap(
    Map<String, dynamic> row,
  ) =>
      TransactionItemsTableCompanion(
        id: Value(row['id'] as String),
        transactionId: Value(row['transaction_id'] as String),
        productId: Value(row['product_id'] as String),
        productName: Value(row['product_name'] as String),
        quantity: Value(row['quantity'] as int),
        unitPrice: Value(row['unit_price'] as int),
        subtotal: Value(row['subtotal'] as int),
        createdAt: Value(DateTime.parse(row['created_at'] as String)),
        updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
        isDeleted: Value((row['is_deleted'] as bool?) ?? false),
        isSynced: const Value(true),
      );

  DebtsTableCompanion _debtFromMap(Map<String, dynamic> row) =>
      DebtsTableCompanion(
        id: Value(row['id'] as String),
        customerId: Value(row['customer_id'] as String),
        amount: Value(row['amount'] as int),
        paidAmount: Value((row['paid_amount'] as int?) ?? 0),
        remainingAmount: Value(row['remaining_amount'] as int),
        dueDate: Value(
          row['due_date'] != null
              ? DateTime.parse(row['due_date'] as String)
              : null,
        ),
        note: Value(row['note'] as String?),
        createdAt: Value(DateTime.parse(row['created_at'] as String)),
        updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
        isDeleted: Value((row['is_deleted'] as bool?) ?? false),
        isSynced: const Value(true),
      );

  DebtPaymentsTableCompanion _debtPaymentFromMap(Map<String, dynamic> row) =>
      DebtPaymentsTableCompanion(
        id: Value(row['id'] as String),
        debtId: Value(row['debt_id'] as String),
        amount: Value(row['amount'] as int),
        paidAt: Value(DateTime.parse(row['paid_at'] as String)),
        createdAt: Value(DateTime.parse(row['created_at'] as String)),
        updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
        isDeleted: Value((row['is_deleted'] as bool?) ?? false),
        isSynced: const Value(true),
      );

  StockLogsTableCompanion _stockLogFromMap(Map<String, dynamic> row) =>
      StockLogsTableCompanion(
        id: Value(row['id'] as String),
        productId: Value(row['product_id'] as String),
        type: Value(row['type'] as String),
        quantity: Value(row['quantity'] as int),
        note: Value(row['note'] as String?),
        createdAt: Value(DateTime.parse(row['created_at'] as String)),
        updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
        isDeleted: Value((row['is_deleted'] as bool?) ?? false),
        isSynced: const Value(true),
      );

  PurchasedFeaturesTableCompanion _featureFromMap(Map<String, dynamic> row) =>
      PurchasedFeaturesTableCompanion(
        id: Value(row['id'] as String),
        featureKey: Value(row['feature_key'] as String),
        purchasedAt: Value(DateTime.parse(row['purchased_at'] as String)),
        expiresAt: Value(
          row['expires_at'] != null
              ? DateTime.parse(row['expires_at'] as String)
              : null,
        ),
        createdAt: Value(DateTime.parse(row['created_at'] as String)),
        updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
        isDeleted: Value((row['is_deleted'] as bool?) ?? false),
        isSynced: const Value(true),
      );

  AppUsersTableCompanion _appUserFromMap(Map<String, dynamic> row) =>
      AppUsersTableCompanion(
        id: Value(row['id'] as String),
        name: Value(row['name'] as String),
        role: Value(row['role'] as String),
        pin: Value(row['pin'] as String?),
        isActive: Value((row['is_active'] as bool?) ?? true),
        createdAt: Value(DateTime.parse(row['created_at'] as String)),
        updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
        isDeleted: Value((row['is_deleted'] as bool?) ?? false),
        isSynced: const Value(true),
      );
}
