import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/daily_report_entity.dart';
import '../../domain/entities/monthly_report_entity.dart';
import '../../domain/entities/top_product_entity.dart';
import '../../domain/entities/weekly_report_entity.dart';

/// Thrown when a premium feature is accessed without a valid purchase.
class PremiumRequiredException implements Exception {
  final String featureKey;
  const PremiumRequiredException(this.featureKey);
}

abstract class ReportLocalDataSource {
  Future<DailyReportEntity> getDailyReport(DateTime date);
  Future<WeeklyReportEntity> getWeeklyReport(DateTime startDate);
  Future<MonthlyReportEntity> getMonthlyReport(int month, int year);
  Future<List<TopProductEntity>> getTopProducts(
    DateTime start,
    DateTime end, {
    int limit = 5,
  });
}

@LazySingleton(as: ReportLocalDataSource)
class ReportLocalDataSourceImpl implements ReportLocalDataSource {
  final AppDatabase _db;

  ReportLocalDataSourceImpl(this._db);

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<List<TransactionData>> _txnsInRange(
      DateTime start, DateTime end) async {
    return (_db.select(_db.transactionsTable)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(start) &
              t.createdAt.isSmallerThanValue(end) &
              t.isDeleted.equals(false)))
        .get();
  }

  Future<List<TransactionItemData>> _itemsForTxns(List<String> ids) async {
    if (ids.isEmpty) return [];
    return (_db.select(_db.transactionItemsTable)
          ..where((t) =>
              t.transactionId.isIn(ids) & t.isDeleted.equals(false)))
        .get();
  }

  Future<Map<String, int>> _costPrices(Set<String> productIds) async {
    if (productIds.isEmpty) return {};
    final products = await (_db.select(_db.productsTable)
          ..where((t) => t.id.isIn(productIds.toList())))
        .get();
    return {for (final p in products) p.id: p.costPrice};
  }

  ({int revenue, int transactions, int profit}) _totals(
    List<TransactionData> txns,
    List<TransactionItemData> items,
    Map<String, int> costs,
  ) {
    return (
      revenue: txns.fold(0, (s, t) => s + t.totalAmount),
      transactions: txns.length,
      profit: items.fold(
        0,
        (s, i) => s + (i.unitPrice - (costs[i.productId] ?? 0)) * i.quantity,
      ),
    );
  }

  List<HourlyRevenuePoint> _hourlyData(List<TransactionData> txns) {
    final map = <int, int>{};
    for (final t in txns) {
      map[t.createdAt.hour] = (map[t.createdAt.hour] ?? 0) + t.totalAmount;
    }
    return List.generate(
      24,
      (h) => HourlyRevenuePoint(hour: h, revenue: map[h] ?? 0),
    );
  }

  DailyReportEntity _buildDay(
    DateTime date,
    List<TransactionData> txns,
    List<TransactionItemData> items,
    Map<String, int> costs, {
    bool includeHourly = true,
  }) {
    final t = _totals(txns, items, costs);
    return DailyReportEntity(
      date: date,
      totalRevenue: t.revenue,
      totalTransactions: t.transactions,
      totalProfit: t.profit,
      hourlyRevenue: includeHourly ? _hourlyData(txns) : const [],
    );
  }

  // ── Public interface ─────────────────────────────────────────────────────

  @override
  Future<DailyReportEntity> getDailyReport(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final txns = await _txnsInRange(start, end);
    final ids = txns.map((t) => t.id).toList();
    final items = await _itemsForTxns(ids);
    final costs = await _costPrices(items.map((i) => i.productId).toSet());

    return _buildDay(start, txns, items, costs);
  }

  @override
  Future<WeeklyReportEntity> getWeeklyReport(DateTime startDate) async {
    final isUnlocked =
        await _db.featureDao.isFeatureUnlocked('weekly_report');
    if (!isUnlocked) throw const PremiumRequiredException('weekly_report');

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = start.add(const Duration(days: 7));

    final allTxns = await _txnsInRange(start, end);
    final allItems =
        await _itemsForTxns(allTxns.map((t) => t.id).toList());
    final costs =
        await _costPrices(allItems.map((i) => i.productId).toSet());

    final days = <DailyReportEntity>[];
    for (int i = 0; i < 7; i++) {
      final dayStart = start.add(Duration(days: i));
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayTxns = allTxns
          .where((t) =>
              !t.createdAt.isBefore(dayStart) &&
              t.createdAt.isBefore(dayEnd))
          .toList();
      final dayTxnIds = {for (final t in dayTxns) t.id};
      final dayItems = allItems
          .where((i) => dayTxnIds.contains(i.transactionId))
          .toList();

      days.add(_buildDay(dayStart, dayTxns, dayItems, costs));
    }

    return WeeklyReportEntity(startDate: start, days: days);
  }

  @override
  Future<MonthlyReportEntity> getMonthlyReport(int month, int year) async {
    final isUnlocked =
        await _db.featureDao.isFeatureUnlocked('monthly_report');
    if (!isUnlocked) throw const PremiumRequiredException('monthly_report');

    final start = DateTime(year, month, 1);
    // Dart normalises month 13 → Jan of next year automatically.
    final end = DateTime(year, month + 1, 1);

    final allTxns = await _txnsInRange(start, end);
    final allItems =
        await _itemsForTxns(allTxns.map((t) => t.id).toList());
    final costs =
        await _costPrices(allItems.map((i) => i.productId).toSet());

    final totals = _totals(allTxns, allItems, costs);
    final daysInMonth = end.subtract(const Duration(days: 1)).day;

    final weeks = <WeeklyReportEntity>[];
    int dayOfMonth = 1;
    while (dayOfMonth <= daysInMonth) {
      final weekStart = DateTime(year, month, dayOfMonth);
      final weekDays = <DailyReportEntity>[];

      for (int d = 0; d < 7 && (dayOfMonth + d) <= daysInMonth; d++) {
        final dayStart = DateTime(year, month, dayOfMonth + d);
        final dayEnd = dayStart.add(const Duration(days: 1));

        final dayTxns = allTxns
            .where((t) =>
                !t.createdAt.isBefore(dayStart) &&
                t.createdAt.isBefore(dayEnd))
            .toList();
        final dayTxnIds = {for (final t in dayTxns) t.id};
        final dayItems = allItems
            .where((i) => dayTxnIds.contains(i.transactionId))
            .toList();

        weekDays.add(_buildDay(dayStart, dayTxns, dayItems, costs,
            includeHourly: false));
      }

      weeks.add(WeeklyReportEntity(startDate: weekStart, days: weekDays));
      dayOfMonth += 7;
    }

    return MonthlyReportEntity(
      month: month,
      year: year,
      weeks: weeks,
      totalRevenue: totals.revenue,
      totalProfit: totals.profit,
      totalTransactions: totals.transactions,
    );
  }

  @override
  Future<List<TopProductEntity>> getTopProducts(
    DateTime start,
    DateTime end, {
    int limit = 5,
  }) async {
    final txns = await _txnsInRange(start, end);
    final items = await _itemsForTxns(txns.map((t) => t.id).toList());

    final map = <String, ({String name, int qty, int revenue})>{};
    for (final item in items) {
      final ex = map[item.productId];
      map[item.productId] = ex == null
          ? (name: item.productName, qty: item.quantity, revenue: item.subtotal)
          : (
              name: ex.name,
              qty: ex.qty + item.quantity,
              revenue: ex.revenue + item.subtotal
            );
    }

    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.qty.compareTo(a.value.qty));

    return sorted.take(limit).map((e) => TopProductEntity(
          productId: e.key,
          productName: e.value.name,
          quantitySold: e.value.qty,
          totalRevenue: e.value.revenue,
        )).toList();
  }
}
