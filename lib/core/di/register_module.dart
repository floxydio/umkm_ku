import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';

@module
abstract class RegisterModule {
  /// Async — resolved before the rest of the graph is built.
  @preResolve
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();

  /// Database singleton — synchronous constructor.
  @singleton
  AppDatabase get appDatabase => AppDatabase();

  /// Secure storage for auth tokens.
  @singleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  /// Supabase client singleton.
  @singleton
  SupabaseClient get supabaseClient => Supabase.instance.client;
}
