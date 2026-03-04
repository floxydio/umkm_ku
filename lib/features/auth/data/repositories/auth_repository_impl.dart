import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _datasource;

  AuthRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, UserEntity>> loginWithEmail(
      String email, String password) async {
    try {
      final user = await _datasource.loginWithEmail(email, password);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(_mapAuthMessage(e.message)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithUsername(
      String username, String password) async {
    try {
      final user = await _datasource.loginWithUsername(username, password);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(_mapAuthMessage(e.message)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register(RegisterParams params) async {
    try {
      final user = await _datasource.register(params);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(_mapAuthMessage(e.message)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  String _mapAuthMessage(String raw) {
    final msg = raw.toLowerCase();
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Terlalu banyak percobaan. Silakan tunggu beberapa menit.';
    }
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return 'Email/username atau kata sandi salah.';
    }
    if (msg.contains('user already registered') || msg.contains('already been registered')) {
      return 'Akun dengan email ini sudah terdaftar.';
    }
    if (msg.contains('password') && msg.contains('short')) {
      return 'Kata sandi terlalu pendek.';
    }
    return raw;
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await _datasource.logout();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getSession() async {
    try {
      final user = await _datasource.getSession();
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
