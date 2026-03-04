// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i300;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:supabase_flutter/supabase_flutter.dart' as _i301;

import '../../features/auth/data/datasources/auth_remote_datasource.dart'
    as _i302;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i304;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i303;
import '../../features/auth/domain/usecases/get_session_usecase.dart' as _i309;
import '../../features/auth/domain/usecases/login_usecase.dart' as _i306;
import '../../features/auth/domain/usecases/logout_usecase.dart' as _i308;
import '../../features/auth/domain/usecases/register_usecase.dart' as _i307;
import '../../features/auth/presentation/bloc/auth_bloc.dart' as _i310;
import '../../features/product/data/datasources/product_local_datasource.dart'
    as _i401;
import '../../features/product/data/repositories/product_repository_impl.dart'
    as _i403;
import '../../features/product/domain/repositories/product_repository.dart'
    as _i402;
import '../../features/product/domain/usecases/add_product_usecase.dart'
    as _i404;
import '../../features/product/domain/usecases/delete_product_usecase.dart'
    as _i405;
import '../../features/product/domain/usecases/update_product_usecase.dart'
    as _i406;
import '../../features/product/domain/usecases/watch_categories_usecase.dart'
    as _i407;
import '../../features/product/domain/usecases/watch_products_usecase.dart'
    as _i408;
import '../../features/product/presentation/bloc/product_bloc.dart' as _i409;
import '../../features/pos/data/datasources/pos_local_datasource.dart'
    as _i501;
import '../../features/pos/data/repositories/pos_repository_impl.dart'
    as _i503;
import '../../features/pos/domain/repositories/pos_repository.dart' as _i502;
import '../../features/pos/domain/usecases/get_today_summary_usecase.dart'
    as _i504;
import '../../features/pos/domain/usecases/save_transaction_usecase.dart'
    as _i505;
import '../../features/pos/domain/usecases/watch_today_transactions_usecase.dart'
    as _i506;
import '../../features/pos/presentation/bloc/pos_bloc.dart' as _i507;
import '../../features/report/data/datasources/report_local_datasource.dart'
    as _i701;
import '../../features/report/data/repositories/report_repository_impl.dart'
    as _i703;
import '../../features/report/domain/repositories/report_repository.dart'
    as _i702;
import '../../features/report/domain/usecases/get_daily_report_usecase.dart'
    as _i704;
import '../../features/report/domain/usecases/get_monthly_report_usecase.dart'
    as _i706;
import '../../features/report/domain/usecases/get_top_products_usecase.dart'
    as _i707;
import '../../features/report/domain/usecases/get_weekly_report_usecase.dart'
    as _i705;
import '../../features/report/presentation/bloc/report_bloc.dart' as _i708;
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
    gh.singleton<_i300.FlutterSecureStorage>(
        () => registerModule.secureStorage);
    gh.singleton<_i301.SupabaseClient>(() => registerModule.supabaseClient);
    gh.lazySingleton<_i302.AuthRemoteDataSource>(
      () => _i302.AuthRemoteDataSourceImpl(
        gh<_i301.SupabaseClient>(),
        gh<_i300.FlutterSecureStorage>(),
      ),
    );
    gh.lazySingleton<_i303.AuthRepository>(
      () => _i304.AuthRepositoryImpl(gh<_i302.AuthRemoteDataSource>()),
    );
    gh.factory<_i306.LoginUseCase>(
      () => _i306.LoginUseCase(gh<_i303.AuthRepository>()),
    );
    gh.factory<_i307.RegisterUseCase>(
      () => _i307.RegisterUseCase(gh<_i303.AuthRepository>()),
    );
    gh.factory<_i308.LogoutUseCase>(
      () => _i308.LogoutUseCase(gh<_i303.AuthRepository>()),
    );
    gh.factory<_i309.GetSessionUseCase>(
      () => _i309.GetSessionUseCase(gh<_i303.AuthRepository>()),
    );
    gh.factory<_i310.AuthBloc>(
      () => _i310.AuthBloc(
        gh<_i306.LoginUseCase>(),
        gh<_i307.RegisterUseCase>(),
        gh<_i308.LogoutUseCase>(),
        gh<_i309.GetSessionUseCase>(),
      ),
    );
    // ── Product ──────────────────────────────────────────────────────────────
    gh.lazySingleton<_i401.ProductLocalDataSource>(
      () => _i401.ProductLocalDataSourceImpl(gh<_i982.AppDatabase>()),
    );
    gh.lazySingleton<_i402.ProductRepository>(
      () => _i403.ProductRepositoryImpl(gh<_i401.ProductLocalDataSource>()),
    );
    gh.factory<_i404.AddProductUseCase>(
      () => _i404.AddProductUseCase(gh<_i402.ProductRepository>()),
    );
    gh.factory<_i405.DeleteProductUseCase>(
      () => _i405.DeleteProductUseCase(gh<_i402.ProductRepository>()),
    );
    gh.factory<_i406.UpdateProductUseCase>(
      () => _i406.UpdateProductUseCase(gh<_i402.ProductRepository>()),
    );
    gh.factory<_i407.WatchCategoriesUseCase>(
      () => _i407.WatchCategoriesUseCase(gh<_i402.ProductRepository>()),
    );
    gh.factory<_i408.WatchProductsUseCase>(
      () => _i408.WatchProductsUseCase(gh<_i402.ProductRepository>()),
    );
    gh.factory<_i409.ProductBloc>(
      () => _i409.ProductBloc(
        gh<_i408.WatchProductsUseCase>(),
        gh<_i404.AddProductUseCase>(),
        gh<_i406.UpdateProductUseCase>(),
        gh<_i405.DeleteProductUseCase>(),
        gh<_i407.WatchCategoriesUseCase>(),
        gh<_i402.ProductRepository>(),
      ),
    );

    gh.factory<_i609.ThemeCubit>(
      () => _i609.ThemeCubit(gh<_i460.SharedPreferences>()),
    );

    // ── POS ──────────────────────────────────────────────────────────────────
    gh.lazySingleton<_i501.PosLocalDataSource>(
      () => _i501.PosLocalDataSourceImpl(gh<_i982.AppDatabase>()),
    );
    gh.lazySingleton<_i502.PosRepository>(
      () => _i503.PosRepositoryImpl(gh<_i501.PosLocalDataSource>()),
    );
    gh.factory<_i504.GetTodaySummaryUseCase>(
      () => _i504.GetTodaySummaryUseCase(gh<_i502.PosRepository>()),
    );
    gh.factory<_i505.SaveTransactionUseCase>(
      () => _i505.SaveTransactionUseCase(gh<_i502.PosRepository>()),
    );
    gh.factory<_i506.WatchTodayTransactionsUseCase>(
      () => _i506.WatchTodayTransactionsUseCase(gh<_i502.PosRepository>()),
    );
    gh.factory<_i507.PosBloc>(
      () => _i507.PosBloc(
        gh<_i408.WatchProductsUseCase>(),
        gh<_i505.SaveTransactionUseCase>(),
      ),
    );

    // ── Report ────────────────────────────────────────────────────────────────
    gh.lazySingleton<_i701.ReportLocalDataSource>(
      () => _i701.ReportLocalDataSourceImpl(gh<_i982.AppDatabase>()),
    );
    gh.lazySingleton<_i702.ReportRepository>(
      () => _i703.ReportRepositoryImpl(gh<_i701.ReportLocalDataSource>()),
    );
    gh.factory<_i704.GetDailyReportUseCase>(
      () => _i704.GetDailyReportUseCase(gh<_i702.ReportRepository>()),
    );
    gh.factory<_i705.GetWeeklyReportUseCase>(
      () => _i705.GetWeeklyReportUseCase(gh<_i702.ReportRepository>()),
    );
    gh.factory<_i706.GetMonthlyReportUseCase>(
      () => _i706.GetMonthlyReportUseCase(gh<_i702.ReportRepository>()),
    );
    gh.factory<_i707.GetTopProductsUseCase>(
      () => _i707.GetTopProductsUseCase(gh<_i702.ReportRepository>()),
    );
    gh.factory<_i708.ReportBloc>(
      () => _i708.ReportBloc(
        gh<_i704.GetDailyReportUseCase>(),
        gh<_i705.GetWeeklyReportUseCase>(),
        gh<_i706.GetMonthlyReportUseCase>(),
        gh<_i707.GetTopProductsUseCase>(),
      ),
    );

    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
