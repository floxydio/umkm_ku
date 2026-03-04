import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.username,
    required super.fullName,
    required super.storeName,
    required super.businessType,
    required super.phone,
    required super.plan,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        username: json['username'] as String,
        fullName: json['full_name'] as String,
        storeName: json['store_name'] as String,
        businessType: json['business_type'] as String,
        phone: json['phone'] as String? ?? '',
        plan: json['plan'] as String? ?? 'free',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'full_name': fullName,
        'store_name': storeName,
        'business_type': businessType,
        'phone': phone,
        'plan': plan,
      };

  factory UserModel.fromSupabase(Map<String, dynamic> data) =>
      UserModel.fromJson(data);
}
