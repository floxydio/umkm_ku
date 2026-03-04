import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../entities/monthly_report_entity.dart';
import '../repositories/report_repository.dart';

@injectable
class GetMonthlyReportUseCase {
  final ReportRepository _repository;

  GetMonthlyReportUseCase(this._repository);

  Future<Either<Failure, MonthlyReportEntity>> call(int month, int year) {
    return _repository.getMonthlyReport(month, year);
  }
}
