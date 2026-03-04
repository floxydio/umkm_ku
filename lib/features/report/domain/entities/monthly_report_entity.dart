import 'package:equatable/equatable.dart';

import 'daily_report_entity.dart';
import 'weekly_report_entity.dart';

class MonthlyReportEntity extends Equatable {
  final int month;
  final int year;
  final List<WeeklyReportEntity> weeks;
  final int totalRevenue;
  final int totalProfit;
  final int totalTransactions;

  const MonthlyReportEntity({
    required this.month,
    required this.year,
    required this.weeks,
    required this.totalRevenue,
    required this.totalProfit,
    required this.totalTransactions,
  });

  List<DailyReportEntity> get allDays =>
      weeks.expand((w) => w.days).toList();

  @override
  List<Object?> get props => [
        month,
        year,
        weeks,
        totalRevenue,
        totalProfit,
        totalTransactions,
      ];
}
