import 'package:equatable/equatable.dart';

class HourlyRevenuePoint extends Equatable {
  final int hour;
  final int revenue;

  const HourlyRevenuePoint({required this.hour, required this.revenue});

  @override
  List<Object?> get props => [hour, revenue];
}

class DailyReportEntity extends Equatable {
  final DateTime date;
  final int totalRevenue;
  final int totalTransactions;
  final int totalProfit;
  final List<HourlyRevenuePoint> hourlyRevenue;

  const DailyReportEntity({
    required this.date,
    required this.totalRevenue,
    required this.totalTransactions,
    required this.totalProfit,
    required this.hourlyRevenue,
  });

  @override
  List<Object?> get props => [
        date,
        totalRevenue,
        totalTransactions,
        totalProfit,
        hourlyRevenue,
      ];
}
