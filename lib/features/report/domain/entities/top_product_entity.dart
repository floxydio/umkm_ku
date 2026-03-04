import 'package:equatable/equatable.dart';

class TopProductEntity extends Equatable {
  final String productId;
  final String productName;
  final int quantitySold;
  final int totalRevenue;

  const TopProductEntity({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.totalRevenue,
  });

  @override
  List<Object?> get props => [productId, productName, quantitySold, totalRevenue];
}
