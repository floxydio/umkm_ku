import 'package:drift/drift.dart';

import 'customers_table.dart';

@DataClassName('DebtData')
class DebtsTable extends Table {
  @override
  String get tableName => 'debts';

  TextColumn get id => text()();
  TextColumn get customerId =>
      text().references(CustomersTable, #id)();
  IntColumn get amount => integer()();
  IntColumn get paidAmount =>
      integer().withDefault(const Constant(0))();
  IntColumn get remainingAmount => integer()();
  DateTimeColumn get dueDate => dateTime().nullable()();
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
