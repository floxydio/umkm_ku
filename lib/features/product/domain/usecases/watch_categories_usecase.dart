import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../entities/category_entity.dart';
import '../repositories/product_repository.dart';

@injectable
class WatchCategoriesUseCase {
  final ProductRepository _repository;

  WatchCategoriesUseCase(this._repository);

  Stream<Either<Failure, List<CategoryEntity>>> call() {
    return _repository.watchCategories();
  }
}
