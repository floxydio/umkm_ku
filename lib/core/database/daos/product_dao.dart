import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/categories_table.dart';
import '../tables/products_table.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [ProductsTable, CategoriesTable])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  Stream<List<ProductData>> watchAllProducts() {
    return (select(productsTable)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Stream<List<ProductData>> watchLowStockProducts() {
    return (select(productsTable)
          ..where(
            (t) =>
                t.isDeleted.equals(false) &
                t.stock.isSmallerOrEqualValue(0).not() &
                // stock <= minStock
                Expression.and([t.stock.isSmallerOrEqualValue(0)]).not(),
          ))
        .watch();
  }

  Future<ProductData?> getProductById(String id) {
    return (select(productsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> countActiveProducts() async {
    final countExpr = productsTable.id.count();
    final query = selectOnly(productsTable)
      ..addColumns([countExpr])
      ..where(productsTable.isDeleted.equals(false));
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  Future<void> insertProduct(ProductsTableCompanion entry) {
    return into(productsTable).insert(entry);
  }

  Future<bool> updateProduct(ProductsTableCompanion entry) {
    return update(productsTable).replace(entry);
  }

  Future<void> updateStock(String id, int newStock) async {
    await (update(productsTable)..where((t) => t.id.equals(id))).write(
      ProductsTableCompanion(
        stock: Value(newStock),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> softDelete(String id) async {
    await (update(productsTable)..where((t) => t.id.equals(id))).write(
      ProductsTableCompanion(
        isDeleted: const Value(true),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<ProductData>> getUnsyncedProducts() {
    return (select(productsTable)
          ..where((t) => t.isSynced.equals(false)))
        .get();
  }

  Future<void> markSynced(List<String> ids) async {
    await (update(productsTable)..where((t) => t.id.isIn(ids))).write(
      ProductsTableCompanion(
        isSynced: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> upsertFromRemote(ProductsTableCompanion entry) {
    return into(productsTable).insertOnConflictUpdate(entry);
  }
}
