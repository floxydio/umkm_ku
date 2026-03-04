import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_datasource.dart';

@LazySingleton(as: ProductRepository)
class ProductRepositoryImpl implements ProductRepository {
  final ProductLocalDataSource _datasource;
  final _uuid = const Uuid();

  ProductRepositoryImpl(this._datasource);

  @override
  Stream<Either<Failure, List<ProductEntity>>> watchProducts() {
    return _datasource.watchProductsWithCategory().map((rows) {
      try {
        final products = rows.map((row) {
          return ProductEntity(
            id: row.product.id,
            name: row.product.name,
            price: row.product.price,
            costPrice: row.product.costPrice,
            stock: row.product.stock,
            minStock: row.product.minStock,
            categoryId: row.product.categoryId,
            categoryName: row.category?.name ?? 'Tanpa Kategori',
            imageUrl: row.product.imageUrl,
          );
        }).toList();
        return Right<Failure, List<ProductEntity>>(products);
      } catch (e) {
        return Left<Failure, List<ProductEntity>>(
            LocalFailure('Gagal memuat produk: ${e.toString()}'));
      }
    });
  }

  @override
  Future<Either<Failure, Unit>> addProduct(AddProductParams params) async {
    try {
      final now = DateTime.now();
      await _datasource.insertProduct(
        ProductsTableCompanion(
          id: Value(_uuid.v4()),
          name: Value(params.name),
          price: Value(params.price),
          costPrice: Value(params.costPrice),
          stock: Value(params.stock),
          minStock: Value(params.minStock),
          categoryId: Value(params.categoryId),
          imageUrl: Value(params.imageUrl),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      return const Right(unit);
    } catch (e) {
      return Left(LocalFailure('Gagal menambah produk: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateProduct(UpdateProductParams params) async {
    try {
      final now = DateTime.now();
      await _datasource.updateProduct(
        ProductsTableCompanion(
          id: Value(params.id),
          name: Value(params.name),
          price: Value(params.price),
          costPrice: Value(params.costPrice),
          stock: Value(params.stock),
          minStock: Value(params.minStock),
          categoryId: Value(params.categoryId),
          imageUrl: Value(params.imageUrl),
          updatedAt: Value(now),
          isSynced: const Value(false),
        ),
      );
      return const Right(unit);
    } catch (e) {
      return Left(LocalFailure('Gagal memperbarui produk: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteProduct(String id) async {
    try {
      await _datasource.deleteProduct(id);
      return const Right(unit);
    } catch (e) {
      return Left(LocalFailure('Gagal menghapus produk: ${e.toString()}'));
    }
  }

  @override
  Stream<Either<Failure, List<CategoryEntity>>> watchCategories() {
    return _datasource.watchAllCategories().map((rows) {
      try {
        final categories = rows
            .map((c) => CategoryEntity(id: c.id, name: c.name))
            .toList();
        return Right<Failure, List<CategoryEntity>>(categories);
      } catch (e) {
        return Left<Failure, List<CategoryEntity>>(
            LocalFailure('Gagal memuat kategori: ${e.toString()}'));
      }
    });
  }

  @override
  Future<Either<Failure, Unit>> addCategory(String name) async {
    try {
      final now = DateTime.now();
      await _datasource.insertCategory(
        CategoriesTableCompanion(
          id: Value(_uuid.v4()),
          name: Value(name),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      return const Right(unit);
    } catch (e) {
      return Left(LocalFailure('Gagal menambah kategori: ${e.toString()}'));
    }
  }
}
