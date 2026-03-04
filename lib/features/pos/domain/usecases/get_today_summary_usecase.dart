import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../entities/today_summary_entity.dart';
import '../repositories/pos_repository.dart';

@injectable
class GetTodaySummaryUseCase {
  final PosRepository _repository;

  GetTodaySummaryUseCase(this._repository);

  Future<Either<Failure, TodaySummaryEntity>> call() {
    return _repository.getTodaySummary();
  }
}
