import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/daily_report_entity.dart';
import '../entities/monthly_report_entity.dart';
import '../entities/top_product_entity.dart';
import '../entities/weekly_report_entity.dart';

abstract class ReportRepository {
  Future<Either<Failure, DailyReportEntity>> getDailyReport(DateTime date);

  Future<Either<Failure, WeeklyReportEntity>> getWeeklyReport(
      DateTime startDate);

  Future<Either<Failure, MonthlyReportEntity>> getMonthlyReport(
      int month, int year);

  Future<Either<Failure, List<TopProductEntity>>> getTopProducts(
    DateTime start,
    DateTime end, {
    int limit = 5,
  });
}
