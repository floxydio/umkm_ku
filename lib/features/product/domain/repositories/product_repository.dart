import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/category_entity.dart';
import '../entities/product_entity.dart';

class AddProductParams {
  final String name;
  final int price;
  final int costPrice;
  final int stock;
  final int minStock;
  final String categoryId;
  final String? imageUrl;

  const AddProductParams({
    required this.name,
    required this.price,
    required this.costPrice,
    required this.stock,
    required this.minStock,
    required this.categoryId,
    this.imageUrl,
  });
}

class UpdateProductParams {
  final String id;
  final String name;
  final int price;
  final int costPrice;
  final int stock;
  final int minStock;
  final String categoryId;
  final String? imageUrl;

  const UpdateProductParams({
    required this.id,
    required this.name,
    required this.price,
    required this.costPrice,
    required this.stock,
    required this.minStock,
    required this.categoryId,
    this.imageUrl,
  });
}

abstract class ProductRepository {
  Stream<Either<Failure, List<ProductEntity>>> watchProducts();
  Future<Either<Failure, Unit>> addProduct(AddProductParams params);
  Future<Either<Failure, Unit>> updateProduct(UpdateProductParams params);
  Future<Either<Failure, Unit>> deleteProduct(String id);
  Stream<Either<Failure, List<CategoryEntity>>> watchCategories();
  Future<Either<Failure, Unit>> addCategory(String name);
}
