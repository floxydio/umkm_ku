import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../repositories/product_repository.dart';

@injectable
class UpdateProductUseCase {
  final ProductRepository _repository;

  UpdateProductUseCase(this._repository);

  Future<Either<Failure, Unit>> call(UpdateProductParams params) {
    return _repository.updateProduct(params);
  }
}
