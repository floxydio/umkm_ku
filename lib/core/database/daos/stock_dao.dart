import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/stock_logs_table.dart';

part 'stock_dao.g.dart';

@DriftAccessor(tables: [StockLogsTable])
class StockDao extends DatabaseAccessor<AppDatabase> with _$StockDaoMixin {
  StockDao(super.db);

  Future<void> insertStockLog(StockLogsTableCompanion entry) {
    return into(stockLogsTable).insert(entry);
  }

  Stream<List<StockLogData>> watchStockLogs(String productId) {
    return (select(stockLogsTable)
          ..where(
            (t) =>
                t.productId.equals(productId) & t.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<List<StockLogData>> getUnsyncedStockLogs() {
    return (select(stockLogsTable)
          ..where((t) => t.isSynced.equals(false)))
        .get();
  }

  Future<void> markSynced(List<String> ids) async {
    await (update(stockLogsTable)..where((t) => t.id.isIn(ids))).write(
      StockLogsTableCompanion(
        isSynced: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
