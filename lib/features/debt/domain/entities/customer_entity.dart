import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final int totalDebt;

  const CustomerEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalDebt,
  });

  @override
  List<Object?> get props => [id, name, phone, totalDebt];
}
