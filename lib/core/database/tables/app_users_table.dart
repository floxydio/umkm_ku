import 'package:drift/drift.dart';

/// Local kasir/owner accounts — separate from Supabase auth users.
@DataClassName('AppUserData')
class AppUsersTable extends Table {
  @override
  String get tableName => 'app_users';

  TextColumn get id => text()();
  TextColumn get name => text()();

  /// 'owner' | 'cashier'
  TextColumn get role => text()();
  TextColumn get pin => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
