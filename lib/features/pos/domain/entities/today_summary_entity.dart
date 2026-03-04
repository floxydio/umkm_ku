import 'package:equatable/equatable.dart';

class TodaySummaryEntity extends Equatable {
  final int totalRevenue;
  final int transactionCount;

  const TodaySummaryEntity({
    required this.totalRevenue,
    required this.transactionCount,
  });

  @override
  List<Object?> get props => [totalRevenue, transactionCount];
}
