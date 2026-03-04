import 'package:drift/drift.dart';

@DataClassName('PurchasedFeatureData')
class PurchasedFeaturesTable extends Table {
  @override
  String get tableName => 'purchased_features';

  TextColumn get id => text()();

  /// Matches PremiumFeature enum key (e.g. 'unlimited_products').
  TextColumn get featureKey => text()();
  DateTimeColumn get purchasedAt => dateTime()();

  /// null = lifetime unlock.
  DateTimeColumn get expiresAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
