import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../repositories/product_repository.dart';

@injectable
class DeleteProductUseCase {
  final ProductRepository _repository;

  DeleteProductUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String id) {
    return _repository.deleteProduct(id);
  }
}
