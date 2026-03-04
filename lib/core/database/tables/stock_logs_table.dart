import 'package:drift/drift.dart';

import 'products_table.dart';

@DataClassName('StockLogData')
class StockLogsTable extends Table {
  @override
  String get tableName => 'stock_logs';

  TextColumn get id => text()();
  TextColumn get productId =>
      text().references(ProductsTable, #id)();

  /// 'in' = stock added, 'out' = stock reduced.
  TextColumn get type => text()();
  IntColumn get quantity => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
