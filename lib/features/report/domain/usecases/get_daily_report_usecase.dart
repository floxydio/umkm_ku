import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../entities/daily_report_entity.dart';
import '../repositories/report_repository.dart';

@injectable
class GetDailyReportUseCase {
  final ReportRepository _repository;

  GetDailyReportUseCase(this._repository);

  Future<Either<Failure, DailyReportEntity>> call(DateTime date) {
    return _repository.getDailyReport(date);
  }
}
