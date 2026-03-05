import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/categories_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [CategoriesTable])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Stream<List<CategoryData>> watchAllCategories() {
    return (select(categoriesTable)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<CategoryData?> getCategoryById(String id) {
    return (select(categoriesTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insertCategory(CategoriesTableCompanion entry) {
    return into(categoriesTable).insert(entry);
  }

  Future<bool> updateCategory(CategoriesTableCompanion entry) {
    return update(categoriesTable).replace(entry);
  }

  Future<void> softDelete(String id) async {
    await (update(categoriesTable)..where((t) => t.id.equals(id))).write(
      CategoriesTableCompanion(
        isDeleted: const Value(true),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<CategoryData>> getUnsyncedCategories() {
    return (select(categoriesTable)
          ..where((t) => t.isSynced.equals(false)))
        .get();
  }

  Future<void> markSynced(List<String> ids) async {
    await (update(categoriesTable)..where((t) => t.id.isIn(ids))).write(
      const CategoriesTableCompanion(isSynced: Value(true)),
    );
  }

  Future<void> upsertFromRemote(CategoriesTableCompanion entry) {
    return into(categoriesTable).insertOnConflictUpdate(entry);
  }
}
