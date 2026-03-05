// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../../features/auth/data/datasources/auth_remote_datasource.dart'
    as _i161;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/domain/usecases/get_session_usecase.dart' as _i230;
import '../../features/auth/domain/usecases/login_usecase.dart' as _i188;
import '../../features/auth/domain/usecases/logout_usecase.dart' as _i48;
import '../../features/auth/domain/usecases/register_usecase.dart' as _i941;
import '../../features/auth/presentation/bloc/auth_bloc.dart' as _i797;
import '../../features/debt/data/datasources/debt_local_datasource.dart'
    as _i589;
import '../../features/debt/data/repositories/debt_repository_impl.dart'
    as _i944;
import '../../features/debt/domain/repositories/debt_repository.dart' as _i701;
import '../../features/debt/presentation/bloc/debt_bloc.dart' as _i893;
import '../../features/pos/data/datasources/pos_local_datasource.dart' as _i499;
import '../../features/pos/data/repositories/pos_repository_impl.dart' as _i84;
import '../../features/pos/domain/repositories/pos_repository.dart' as _i511;
import '../../features/pos/domain/usecases/get_today_summary_usecase.dart'
    as _i157;
import '../../features/pos/domain/usecases/save_transaction_usecase.dart'
    as _i684;
import '../../features/pos/domain/usecases/watch_today_transactions_usecase.dart'
    as _i775;
import '../../features/pos/presentation/bloc/pos_bloc.dart' as _i853;
import '../../features/product/data/datasources/product_local_datasource.dart'
    as _i394;
import '../../features/product/data/repositories/product_repository_impl.dart'
    as _i1040;
import '../../features/product/domain/repositories/product_repository.dart'
    as _i39;
import '../../features/product/domain/usecases/add_product_usecase.dart'
    as _i282;
import '../../features/product/domain/usecases/delete_product_usecase.dart'
    as _i838;
import '../../features/product/domain/usecases/update_product_usecase.dart'
    as _i508;
import '../../features/product/domain/usecases/watch_categories_usecase.dart'
    as _i698;
import '../../features/product/domain/usecases/watch_products_usecase.dart'
    as _i635;
import '../../features/product/presentation/bloc/product_bloc.dart' as _i415;
import '../../features/report/data/datasources/report_local_datasource.dart'
    as _i97;
import '../../features/report/data/repositories/report_repository_impl.dart'
    as _i420;
import '../../features/report/domain/repositories/report_repository.dart'
    as _i23;
import '../../features/report/domain/usecases/get_daily_report_usecase.dart'
    as _i369;
import '../../features/report/domain/usecases/get_monthly_report_usecase.dart'
    as _i674;
import '../../features/report/domain/usecases/get_top_products_usecase.dart'
    as _i333;
import '../../features/report/domain/usecases/get_weekly_report_usecase.dart'
    as _i7;
import '../../features/report/presentation/bloc/report_bloc.dart' as _i852;
import '../../features/settings/presentation/bloc/theme_cubit.dart' as _i609;
import '../database/app_database.dart' as _i982;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.sharedPreferences,
      preResolve: true,
    );
    gh.singleton<_i982.AppDatabase>(() => registerModule.appDatabase);
    gh.singleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.singleton<_i454.SupabaseClient>(() => registerModule.supabaseClient);
    gh.lazySingleton<_i97.ReportLocalDataSource>(
      () => _i97.ReportLocalDataSourceImpl(gh<_i982.AppDatabase>()),
    );
    gh.factory<_i609.ThemeCubit>(
      () => _i609.ThemeCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i589.DebtLocalDataSource>(
      () => _i589.DebtLocalDataSourceImpl(gh<_i982.AppDatabase>()),
    );
    gh.lazySingleton<_i394.ProductLocalDataSource>(
      () => _i394.ProductLocalDataSourceImpl(gh<_i982.AppDatabase>()),
    );
    gh.lazySingleton<_i499.PosLocalDataSource>(
      () => _i499.PosLocalDataSourceImpl(gh<_i982.AppDatabase>()),
    );
    gh.lazySingleton<_i23.ReportRepository>(
      () => _i420.ReportRepositoryImpl(gh<_i97.ReportLocalDataSource>()),
    );
    gh.lazySingleton<_i511.PosRepository>(
      () => _i84.PosRepositoryImpl(gh<_i499.PosLocalDataSource>()),
    );
    gh.lazySingleton<_i39.ProductRepository>(
      () => _i1040.ProductRepositoryImpl(gh<_i394.ProductLocalDataSource>()),
    );
    gh.factory<_i157.GetTodaySummaryUseCase>(
      () => _i157.GetTodaySummaryUseCase(gh<_i511.PosRepository>()),
    );
    gh.factory<_i684.SaveTransactionUseCase>(
      () => _i684.SaveTransactionUseCase(gh<_i511.PosRepository>()),
    );
    gh.factory<_i775.WatchTodayTransactionsUseCase>(
      () => _i775.WatchTodayTransactionsUseCase(gh<_i511.PosRepository>()),
    );
    gh.lazySingleton<_i701.DebtRepository>(
      () => _i944.DebtRepositoryImpl(gh<_i589.DebtLocalDataSource>()),
    );
    gh.factory<_i369.GetDailyReportUseCase>(
      () => _i369.GetDailyReportUseCase(gh<_i23.ReportRepository>()),
    );
    gh.factory<_i674.GetMonthlyReportUseCase>(
      () => _i674.GetMonthlyReportUseCase(gh<_i23.ReportRepository>()),
    );
    gh.factory<_i333.GetTopProductsUseCase>(
      () => _i333.GetTopProductsUseCase(gh<_i23.ReportRepository>()),
    );
    gh.factory<_i7.GetWeeklyReportUseCase>(
      () => _i7.GetWeeklyReportUseCase(gh<_i23.ReportRepository>()),
    );
    gh.lazySingleton<_i161.AuthRemoteDataSource>(
      () => _i161.AuthRemoteDataSourceImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i558.FlutterSecureStorage>(),
      ),
    );
    gh.factory<_i852.ReportBloc>(
      () => _i852.ReportBloc(
        gh<_i369.GetDailyReportUseCase>(),
        gh<_i7.GetWeeklyReportUseCase>(),
        gh<_i674.GetMonthlyReportUseCase>(),
        gh<_i333.GetTopProductsUseCase>(),
      ),
    );
    gh.factory<_i282.AddProductUseCase>(
      () => _i282.AddProductUseCase(gh<_i39.ProductRepository>()),
    );
    gh.factory<_i838.DeleteProductUseCase>(
      () => _i838.DeleteProductUseCase(gh<_i39.ProductRepository>()),
    );
    gh.factory<_i508.UpdateProductUseCase>(
      () => _i508.UpdateProductUseCase(gh<_i39.ProductRepository>()),
    );
    gh.factory<_i698.WatchCategoriesUseCase>(
      () => _i698.WatchCategoriesUseCase(gh<_i39.ProductRepository>()),
    );
    gh.factory<_i635.WatchProductsUseCase>(
      () => _i635.WatchProductsUseCase(gh<_i39.ProductRepository>()),
    );
    gh.lazySingleton<_i787.AuthRepository>(
      () => _i153.AuthRepositoryImpl(gh<_i161.AuthRemoteDataSource>()),
    );
    gh.factory<_i230.GetSessionUseCase>(
      () => _i230.GetSessionUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i188.LoginUseCase>(
      () => _i188.LoginUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i48.LogoutUseCase>(
      () => _i48.LogoutUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i941.RegisterUseCase>(
      () => _i941.RegisterUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i893.DebtBloc>(
      () => _i893.DebtBloc(gh<_i701.DebtRepository>()),
    );
    gh.factory<_i797.AuthBloc>(
      () => _i797.AuthBloc(
        gh<_i188.LoginUseCase>(),
        gh<_i941.RegisterUseCase>(),
        gh<_i48.LogoutUseCase>(),
        gh<_i230.GetSessionUseCase>(),
      ),
    );
    gh.factory<_i415.ProductBloc>(
      () => _i415.ProductBloc(
        gh<_i635.WatchProductsUseCase>(),
        gh<_i282.AddProductUseCase>(),
        gh<_i508.UpdateProductUseCase>(),
        gh<_i838.DeleteProductUseCase>(),
        gh<_i698.WatchCategoriesUseCase>(),
        gh<_i39.ProductRepository>(),
      ),
    );
    gh.factory<_i853.PosBloc>(
      () => _i853.PosBloc(
        gh<_i635.WatchProductsUseCase>(),
        gh<_i684.SaveTransactionUseCase>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
