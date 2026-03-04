import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/category_dao.dart';
import '../../../../core/database/daos/product_dao.dart';

abstract class ProductLocalDataSource {
  Stream<List<ProductWithCategory>> watchProductsWithCategory();
  Future<void> insertProduct(ProductsTableCompanion entry);
  Future<bool> updateProduct(ProductsTableCompanion entry);
  Future<void> deleteProduct(String id);
  Future<int> countActiveProducts();
  Stream<List<CategoryData>> watchAllCategories();
  Future<void> insertCategory(CategoriesTableCompanion entry);
}

class ProductWithCategory {
  final ProductData product;
  final CategoryData? category;

  ProductWithCategory({required this.product, this.category});
}

@LazySingleton(as: ProductLocalDataSource)
class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final AppDatabase _db;

  ProductLocalDataSourceImpl(this._db);

  ProductDao get _productDao => _db.productDao;
  CategoryDao get _categoryDao => _db.categoryDao;

  @override
  Stream<List<ProductWithCategory>> watchProductsWithCategory() {
    final query = _db.select(_db.productsTable).join([
      leftOuterJoin(
        _db.categoriesTable,
        _db.categoriesTable.id.equalsExp(_db.productsTable.categoryId),
      ),
    ])
      ..where(_db.productsTable.isDeleted.equals(false))
      ..orderBy([OrderingTerm.asc(_db.productsTable.name)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return ProductWithCategory(
          product: row.readTable(_db.productsTable),
          category: row.readTableOrNull(_db.categoriesTable),
        );
      }).toList();
    });
  }

  @override
  Future<void> insertProduct(ProductsTableCompanion entry) {
    return _productDao.insertProduct(entry);
  }

  @override
  Future<bool> updateProduct(ProductsTableCompanion entry) {
    return _productDao.updateProduct(entry);
  }

  @override
  Future<void> deleteProduct(String id) {
    return _productDao.softDelete(id);
  }

  @override
  Future<int> countActiveProducts() {
    return _productDao.countActiveProducts();
  }

  @override
  Stream<List<CategoryData>> watchAllCategories() {
    return _categoryDao.watchAllCategories();
  }

  @override
  Future<void> insertCategory(CategoriesTableCompanion entry) {
    return _categoryDao.insertCategory(entry);
  }
}
