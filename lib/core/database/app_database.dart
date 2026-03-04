import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/category_dao.dart';
import 'daos/customer_dao.dart';
import 'daos/debt_dao.dart';
import 'daos/feature_dao.dart';
import 'daos/product_dao.dart';
import 'daos/stock_dao.dart';
import 'daos/transaction_dao.dart';
import 'tables/app_users_table.dart';
import 'tables/categories_table.dart';
import 'tables/customers_table.dart';
import 'tables/debt_payments_table.dart';
import 'tables/debts_table.dart';
import 'tables/products_table.dart';
import 'tables/purchased_features_table.dart';
import 'tables/stock_logs_table.dart';
import 'tables/transaction_items_table.dart';
import 'tables/transactions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    CategoriesTable,
    ProductsTable,
    AppUsersTable,
    TransactionsTable,
    TransactionItemsTable,
    CustomersTable,
    DebtsTable,
    DebtPaymentsTable,
    StockLogsTable,
    PurchasedFeaturesTable,
  ],
  daos: [
    CategoryDao,
    ProductDao,
    TransactionDao,
    CustomerDao,
    DebtDao,
    StockDao,
    FeatureDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'umkm_ku_db'));

  /// Increment this whenever you add/change tables and add a migration below.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Add migration steps here as the schema evolves.
          // Example:
          // if (from < 2) {
          //   await m.addColumn(productsTable, productsTable.barcode);
          // }
        },
        beforeOpen: (details) async {
          // Enable FK enforcement for every connection.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
