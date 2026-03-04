import 'package:drift/drift.dart';

import 'app_users_table.dart';

@DataClassName('TransactionData')
class TransactionsTable extends Table {
  @override
  String get tableName => 'transactions';

  TextColumn get id => text()();
  IntColumn get totalAmount => integer()();
  IntColumn get discountAmount =>
      integer().withDefault(const Constant(0))();
  IntColumn get paidAmount => integer()();
  IntColumn get changeAmount => integer()();
  TextColumn get cashierId =>
      text().references(AppUsersTable, #id)();
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
