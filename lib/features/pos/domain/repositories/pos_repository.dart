import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/cart_entity.dart';
import '../entities/today_summary_entity.dart';
import '../entities/transaction_entity.dart';

abstract class PosRepository {
  /// Saves transaction atomically; returns the new transactionId.
  Future<Either<Failure, String>> saveTransaction(
    CartEntity cart,
    String cashierId,
    String cashierName,
  );

  Stream<Either<Failure, List<TransactionEntity>>> watchTodayTransactions();

  Future<Either<Failure, TodaySummaryEntity>> getTodaySummary();
}
