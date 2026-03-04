import 'package:equatable/equatable.dart';

import 'daily_report_entity.dart';

class WeeklyReportEntity extends Equatable {
  final DateTime startDate;
  final List<DailyReportEntity> days;

  const WeeklyReportEntity({required this.startDate, required this.days});

  int get totalRevenue => days.fold(0, (s, d) => s + d.totalRevenue);
  int get totalTransactions => days.fold(0, (s, d) => s + d.totalTransactions);
  int get totalProfit => days.fold(0, (s, d) => s + d.totalProfit);

  @override
  List<Object?> get props => [startDate, days];
}
