import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../repositories/product_repository.dart';

@injectable
class AddProductUseCase {
  final ProductRepository _repository;

  AddProductUseCase(this._repository);

  Future<Either<Failure, Unit>> call(AddProductParams params) {
    return _repository.addProduct(params);
  }
}
