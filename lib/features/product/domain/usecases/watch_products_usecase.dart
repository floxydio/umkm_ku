import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../entities/product_entity.dart';
import '../repositories/product_repository.dart';

@injectable
class WatchProductsUseCase {
  final ProductRepository _repository;

  WatchProductsUseCase(this._repository);

  Stream<Either<Failure, List<ProductEntity>>> call() {
    return _repository.watchProducts();
  }
}
