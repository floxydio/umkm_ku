import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/daily_report_entity.dart';
import '../../domain/entities/monthly_report_entity.dart';
import '../../domain/entities/top_product_entity.dart';
import '../../domain/entities/weekly_report_entity.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_local_datasource.dart';

@LazySingleton(as: ReportRepository)
class ReportRepositoryImpl implements ReportRepository {
  final ReportLocalDataSource _datasource;

  ReportRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, DailyReportEntity>> getDailyReport(
      DateTime date) async {
    try {
      return Right(await _datasource.getDailyReport(date));
    } catch (e) {
      return Left(LocalFailure('Gagal memuat laporan harian: $e'));
    }
  }

  @override
  Future<Either<Failure, WeeklyReportEntity>> getWeeklyReport(
      DateTime startDate) async {
    try {
      return Right(await _datasource.getWeeklyReport(startDate));
    } on PremiumRequiredException catch (e) {
      return Left(LimitExceededFailure(e.featureKey));
    } catch (e) {
      return Left(LocalFailure('Gagal memuat laporan mingguan: $e'));
    }
  }

  @override
  Future<Either<Failure, MonthlyReportEntity>> getMonthlyReport(
      int month, int year) async {
    try {
      return Right(await _datasource.getMonthlyReport(month, year));
    } on PremiumRequiredException catch (e) {
      return Left(LimitExceededFailure(e.featureKey));
    } catch (e) {
      return Left(LocalFailure('Gagal memuat laporan bulanan: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TopProductEntity>>> getTopProducts(
    DateTime start,
    DateTime end, {
    int limit = 5,
  }) async {
    try {
      return Right(
          await _datasource.getTopProducts(start, end, limit: limit));
    } catch (e) {
      return Left(LocalFailure('Gagal memuat produk terlaris: $e'));
    }
  }
}
