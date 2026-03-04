import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../entities/weekly_report_entity.dart';
import '../repositories/report_repository.dart';

@injectable
class GetWeeklyReportUseCase {
  final ReportRepository _repository;

  GetWeeklyReportUseCase(this._repository);

  Future<Either<Failure, WeeklyReportEntity>> call(DateTime startDate) {
    return _repository.getWeeklyReport(startDate);
  }
}
