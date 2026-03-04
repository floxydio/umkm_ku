import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> loginWithEmail(String email, String password);
  Future<UserModel> loginWithUsername(String username, String password);
  Future<UserModel> register(RegisterParams params);
  Future<void> logout();
  Future<UserModel?> getSession();
  Future<bool> isUsernameAvailable(String username);
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _client;
  final FlutterSecureStorage _storage;

  static const _refreshTokenKey = 'auth_refresh_token';

  AuthRemoteDataSourceImpl(this._client, this._storage);

  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    final response = await _client.auth
        .signInWithPassword(email: email, password: password);
    final userId = response.user!.id;
    final userData =
        await _client.from('profiles').select().eq('id', userId).single();
    if (response.session != null) {
      await _storage.write(
        key: _refreshTokenKey,
        value: response.session!.refreshToken!,
      );
    }
    return UserModel.fromSupabase(userData);
  }

  @override
  Future<UserModel> loginWithUsername(
      String username, String password) async {
    final data = await _client
        .from('profiles')
        .select('email')
        .eq('username', username)
        .maybeSingle();
    if (data == null) {
      throw const AuthException('Username tidak ditemukan.');
    }
    final email = data['email'] as String;
    return loginWithEmail(email, password);
  }

  @override
  Future<UserModel> register(RegisterParams params) async {
    // Check username uniqueness
    final existing = await _client
        .from('profiles')
        .select('id')
        .eq('username', params.username)
        .maybeSingle();
    if (existing != null) {
      throw const AuthException(
          'Username sudah digunakan. Silakan pilih yang lain.');
    }

    // Generate email if not provided
    final email =
        (params.email != null && params.email!.trim().isNotEmpty)
            ? params.email!.trim()
            : '${params.username}@umkmapp.local';

    final response =
        await _client.auth.signUp(email: email, password: params.password);
    if (response.user == null) {
      throw const AuthException('Pendaftaran gagal. Silakan coba lagi.');
    }

    final userId = response.user!.id;
    final userRecord = <String, dynamic>{
      'id': userId,
      'username': params.username,
      'full_name': params.fullName,
      'store_name': params.storeName,
      'business_type': params.businessType,
      'phone': params.phone,
      'email': email,
      'plan': 'free',
    };

    await _client.from('profiles').insert(userRecord);

    if (response.session != null) {
      await _storage.write(
        key: _refreshTokenKey,
        value: response.session!.refreshToken!,
      );
    }

    return UserModel.fromSupabase(userRecord);
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
    await _storage.delete(key: _refreshTokenKey);
  }

  @override
  Future<UserModel?> getSession() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return null;
    try {
      final response = await _client.auth.setSession(refreshToken);
      final userId = response.user!.id;
      final userData =
          await _client.from('profiles').select().eq('id', userId).single();
      if (response.session != null) {
        await _storage.write(
          key: _refreshTokenKey,
          value: response.session!.refreshToken!,
        );
      }
      return UserModel.fromSupabase(userData);
    } catch (_) {
      await _storage.delete(key: _refreshTokenKey);
      return null;
    }
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final data = await _client
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();
    return data == null;
  }
}
