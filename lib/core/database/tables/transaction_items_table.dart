import 'package:drift/drift.dart';

import 'products_table.dart';
import 'transactions_table.dart';

@DataClassName('TransactionItemData')
class TransactionItemsTable extends Table {
  @override
  String get tableName => 'transaction_items';

  TextColumn get id => text()();
  TextColumn get transactionId =>
      text().references(TransactionsTable, #id)();
  TextColumn get productId =>
      text().references(ProductsTable, #id)();

  /// Snapshot of name at time of sale — survives product deletion/rename.
  TextColumn get productName => text()();
  IntColumn get quantity => integer()();

  /// Unit price at time of sale.
  IntColumn get unitPrice => integer()();
  IntColumn get subtotal => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
