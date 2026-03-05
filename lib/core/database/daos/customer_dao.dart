import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/customers_table.dart';

part 'customer_dao.g.dart';

@DriftAccessor(tables: [CustomersTable])
class CustomerDao extends DatabaseAccessor<AppDatabase>
    with _$CustomerDaoMixin {
  CustomerDao(super.db);

  Stream<List<CustomerData>> watchAllCustomers() {
    return (select(customersTable)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<CustomerData?> getCustomerById(String id) {
    return (select(customersTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> countActiveCustomers() async {
    final countExpr = customersTable.id.count();
    final query = selectOnly(customersTable)
      ..addColumns([countExpr])
      ..where(customersTable.isDeleted.equals(false));
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  Future<void> insertCustomer(CustomersTableCompanion entry) {
    return into(customersTable).insert(entry);
  }

  Future<bool> updateCustomer(CustomersTableCompanion entry) {
    return update(customersTable).replace(entry);
  }

  Future<void> updateTotalDebt(String customerId, int totalDebt) async {
    await (update(customersTable)
          ..where((t) => t.id.equals(customerId)))
        .write(
      CustomersTableCompanion(
        totalDebt: Value(totalDebt),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> softDelete(String id) async {
    await (update(customersTable)..where((t) => t.id.equals(id))).write(
      CustomersTableCompanion(
        isDeleted: const Value(true),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<CustomerData>> getUnsyncedCustomers() {
    return (select(customersTable)
          ..where((t) => t.isSynced.equals(false)))
        .get();
  }

  Future<void> markSynced(List<String> ids) async {
    await (update(customersTable)..where((t) => t.id.isIn(ids))).write(
      const CustomersTableCompanion(isSynced: Value(true)),
    );
  }

  Future<void> upsertFromRemote(CustomersTableCompanion entry) {
    return into(customersTable).insertOnConflictUpdate(entry);
  }
}
