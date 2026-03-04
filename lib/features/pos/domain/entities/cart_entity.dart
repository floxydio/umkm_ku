import 'package:equatable/equatable.dart';

import 'cart_item_entity.dart';

class CartEntity extends Equatable {
  final List<CartItemEntity> items;
  final int subtotal;
  final int discount;
  final int total;
  final int paid;
  final int change;

  const CartEntity({
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paid,
    required this.change,
  });

  const CartEntity.empty()
      : items = const [],
        subtotal = 0,
        discount = 0,
        total = 0,
        paid = 0,
        change = 0;

  bool get isEmpty => items.isEmpty;
  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);

  @override
  List<Object?> get props => [items, subtotal, discount, total, paid, change];
}
