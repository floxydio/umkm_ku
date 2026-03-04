import 'package:drift/drift.dart';

import 'categories_table.dart';

@DataClassName('ProductData')
class ProductsTable extends Table {
  @override
  String get tableName => 'products';

  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Selling price in Rupiah (integer, no decimal).
  IntColumn get price => integer()();

  /// Purchase / cost price in Rupiah.
  IntColumn get costPrice => integer()();
  IntColumn get stock => integer()();

  /// Low-stock alert threshold.
  IntColumn get minStock => integer().withDefault(const Constant(0))();
  TextColumn get categoryId =>
      text().references(CategoriesTable, #id)();
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
