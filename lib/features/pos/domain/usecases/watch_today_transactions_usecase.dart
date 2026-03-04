import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../entities/transaction_entity.dart';
import '../repositories/pos_repository.dart';

@injectable
class WatchTodayTransactionsUseCase {
  final PosRepository _repository;

  WatchTodayTransactionsUseCase(this._repository);

  Stream<Either<Failure, List<TransactionEntity>>> call() {
    return _repository.watchTodayTransactions();
  }
}
