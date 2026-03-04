import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final int price;
  final int costPrice;
  final int stock;
  final int minStock;
  final String categoryId;
  final String categoryName;
  final String? imageUrl;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.costPrice,
    required this.stock,
    required this.minStock,
    required this.categoryId,
    required this.categoryName,
    this.imageUrl,
  });

  bool get isLowStock => stock <= minStock;

  @override
  List<Object?> get props => [
        id,
        name,
        price,
        costPrice,
        stock,
        minStock,
        categoryId,
        categoryName,
        imageUrl,
      ];
}
