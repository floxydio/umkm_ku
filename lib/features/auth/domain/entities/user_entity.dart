import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String fullName;
  final String storeName;
  final String businessType;
  final String phone;
  final String plan;

  const UserEntity({
    required this.id,
    required this.username,
    required this.fullName,
    required this.storeName,
    required this.businessType,
    required this.phone,
    required this.plan,
  });

  @override
  List<Object?> get props => [
        id,
        username,
        fullName,
        storeName,
        businessType,
        phone,
        plan,
      ];
}
