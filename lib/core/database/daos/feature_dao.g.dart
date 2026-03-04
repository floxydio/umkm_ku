// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feature_dao.dart';

// ignore_for_file: type=lint
mixin _$FeatureDaoMixin on DatabaseAccessor<AppDatabase> {
  $PurchasedFeaturesTableTable get purchasedFeaturesTable =>
      attachedDatabase.purchasedFeaturesTable;
  FeatureDaoManager get managers => FeatureDaoManager(this);
}

class FeatureDaoManager {
  final _$FeatureDaoMixin _db;
  FeatureDaoManager(this._db);
  $$PurchasedFeaturesTableTableTableManager get purchasedFeaturesTable =>
      $$PurchasedFeaturesTableTableTableManager(
        _db.attachedDatabase,
        _db.purchasedFeaturesTable,
      );
}
