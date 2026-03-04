import 'package:drift/drift.dart';

import 'debts_table.dart';

@DataClassName('DebtPaymentData')
class DebtPaymentsTable extends Table {
  @override
  String get tableName => 'debt_payments';

  TextColumn get id => text()();
  TextColumn get debtId => text().references(DebtsTable, #id)();
  IntColumn get amount => integer()();
  DateTimeColumn get paidAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
