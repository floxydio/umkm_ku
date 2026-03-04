import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../entities/cart_entity.dart';
import '../repositories/pos_repository.dart';

class SaveTransactionParams {
  final CartEntity cart;
  final String cashierId;
  final String cashierName;

  const SaveTransactionParams({
    required this.cart,
    required this.cashierId,
    required this.cashierName,
  });
}

@injectable
class SaveTransactionUseCase {
  final PosRepository _repository;

  SaveTransactionUseCase(this._repository);

  Future<Either<Failure, String>> call(SaveTransactionParams params) {
    return _repository.saveTransaction(
      params.cart,
      params.cashierId,
      params.cashierName,
    );
  }
}
