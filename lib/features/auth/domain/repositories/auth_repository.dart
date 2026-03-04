import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

class RegisterParams extends Equatable {
  final String fullName;
  final String username;
  final String storeName;
  final String businessType;
  final String phone;
  final String? email;
  final String password;

  const RegisterParams({
    required this.fullName,
    required this.username,
    required this.storeName,
    required this.businessType,
    required this.phone,
    this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [
        fullName,
        username,
        storeName,
        businessType,
        phone,
        email,
        password,
      ];
}

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> loginWithEmail(
      String email, String password);

  Future<Either<Failure, UserEntity>> loginWithUsername(
      String username, String password);

  Future<Either<Failure, UserEntity>> register(RegisterParams params);

  Future<Either<Failure, Unit>> logout();

  Future<Either<Failure, UserEntity?>> getSession();
}
