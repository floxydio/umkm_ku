import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/daily_report_entity.dart';
import '../../domain/entities/monthly_report_entity.dart';
import '../../domain/entities/top_product_entity.dart';
import '../../domain/entities/weekly_report_entity.dart';
import '../../domain/usecases/get_daily_report_usecase.dart';
import '../../domain/usecases/get_monthly_report_usecase.dart';
import '../../domain/usecases/get_top_products_usecase.dart';
import '../../domain/usecases/get_weekly_report_usecase.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class ReportEvent extends Equatable {
  const ReportEvent();
  @override
  List<Object?> get props => [];
}

class LoadDailyReport extends ReportEvent {
  final DateTime date;
  const LoadDailyReport(this.date);
  @override
  List<Object?> get props => [date];
}

class LoadWeeklyReport extends ReportEvent {
  final DateTime startDate;
  const LoadWeeklyReport(this.startDate);
  @override
  List<Object?> get props => [startDate];
}

class LoadMonthlyReport extends ReportEvent {
  final int month;
  final int year;
  const LoadMonthlyReport({required this.month, required this.year});
  @override
  List<Object?> get props => [month, year];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class ReportState extends Equatable {
  const ReportState();
  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {
  const ReportInitial();
}

class ReportLoading extends ReportState {
  const ReportLoading();
}

class DailyReportLoaded extends ReportState {
  final DailyReportEntity report;
  final List<TopProductEntity> topProducts;

  const DailyReportLoaded({required this.report, required this.topProducts});

  @override
  List<Object?> get props => [report, topProducts];
}

class WeeklyReportLoaded extends ReportState {
  final WeeklyReportEntity report;
  final List<TopProductEntity> topProducts;

  const WeeklyReportLoaded({required this.report, required this.topProducts});

  @override
  List<Object?> get props => [report, topProducts];
}

class MonthlyReportLoaded extends ReportState {
  final MonthlyReportEntity report;
  final List<TopProductEntity> topProducts;

  const MonthlyReportLoaded({required this.report, required this.topProducts});

  @override
  List<Object?> get props => [report, topProducts];
}

class ReportFeatureLocked extends ReportState {
  final String featureKey;
  const ReportFeatureLocked(this.featureKey);
  @override
  List<Object?> get props => [featureKey];
}

class ReportError extends ReportState {
  final String message;
  const ReportError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Bloc ──────────────────────────────────────────────────────────────────────

@injectable
class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final GetDailyReportUseCase _getDailyReport;
  final GetWeeklyReportUseCase _getWeeklyReport;
  final GetMonthlyReportUseCase _getMonthlyReport;
  final GetTopProductsUseCase _getTopProducts;

  ReportBloc(
    this._getDailyReport,
    this._getWeeklyReport,
    this._getMonthlyReport,
    this._getTopProducts,
  ) : super(const ReportInitial()) {
    on<LoadDailyReport>(_onLoadDaily);
    on<LoadWeeklyReport>(_onLoadWeekly);
    on<LoadMonthlyReport>(_onLoadMonthly);
  }

  Future<void> _onLoadDaily(
      LoadDailyReport event, Emitter<ReportState> emit) async {
    emit(const ReportLoading());

    final start = DateTime(event.date.year, event.date.month, event.date.day);
    final end = start.add(const Duration(days: 1));

    final reportResult = await _getDailyReport(event.date);
    final topResult = await _getTopProducts(
        GetTopProductsParams(start: start, end: end));

    reportResult.fold(
      (f) => emit(ReportError(f.message)),
      (report) => topResult.fold(
        (f) => emit(ReportError(f.message)),
        (top) => emit(DailyReportLoaded(report: report, topProducts: top)),
      ),
    );
  }

  Future<void> _onLoadWeekly(
      LoadWeeklyReport event, Emitter<ReportState> emit) async {
    emit(const ReportLoading());

    final end = event.startDate.add(const Duration(days: 7));

    final reportResult = await _getWeeklyReport(event.startDate);
    final topResult = await _getTopProducts(
        GetTopProductsParams(start: event.startDate, end: end));

    reportResult.fold(
      (f) {
        if (f is LimitExceededFailure) {
          emit(ReportFeatureLocked(f.message));
        } else {
          emit(ReportError(f.message));
        }
      },
      (report) => topResult.fold(
        (f) => emit(ReportError(f.message)),
        (top) =>
            emit(WeeklyReportLoaded(report: report, topProducts: top)),
      ),
    );
  }

  Future<void> _onLoadMonthly(
      LoadMonthlyReport event, Emitter<ReportState> emit) async {
    emit(const ReportLoading());

    final start = DateTime(event.year, event.month, 1);
    final end = DateTime(event.year, event.month + 1, 1);

    final reportResult = await _getMonthlyReport(event.month, event.year);
    final topResult = await _getTopProducts(
        GetTopProductsParams(start: start, end: end));

    reportResult.fold(
      (f) {
        if (f is LimitExceededFailure) {
          emit(ReportFeatureLocked(f.message));
        } else {
          emit(ReportError(f.message));
        }
      },
      (report) => topResult.fold(
        (f) => emit(ReportError(f.message)),
        (top) =>
            emit(MonthlyReportLoaded(report: report, topProducts: top)),
      ),
    );
  }
}
