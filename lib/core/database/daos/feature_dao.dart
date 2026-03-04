import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/purchased_features_table.dart';

part 'feature_dao.g.dart';

@DriftAccessor(tables: [PurchasedFeaturesTable])
class FeatureDao extends DatabaseAccessor<AppDatabase> with _$FeatureDaoMixin {
  FeatureDao(super.db);

  /// Returns true if the feature is purchased and not expired.
  Future<bool> isFeatureUnlocked(String featureKey) async {
    final now = DateTime.now();
    final row = await (select(purchasedFeaturesTable)
          ..where(
            (t) =>
                t.featureKey.equals(featureKey) &
                t.isDeleted.equals(false),
          ))
        .getSingleOrNull();

    if (row == null) return false;
    if (row.expiresAt == null) return true; // lifetime
    return row.expiresAt!.isAfter(now);
  }

  Future<void> unlockFeature(PurchasedFeaturesTableCompanion entry) {
    return into(purchasedFeaturesTable).insertOnConflictUpdate(entry);
  }

  Future<List<PurchasedFeatureData>> getAllUnlocked() async {
    final now = DateTime.now();
    final all = await (select(purchasedFeaturesTable)
          ..where((t) => t.isDeleted.equals(false)))
        .get();

    // Filter out expired features in-memory (simplest approach for small lists).
    return all
        .where((f) => f.expiresAt == null || f.expiresAt!.isAfter(now))
        .toList();
  }

  Future<List<PurchasedFeatureData>> getUnsyncedFeatures() {
    return (select(purchasedFeaturesTable)
          ..where((t) => t.isSynced.equals(false)))
        .get();
  }
}
