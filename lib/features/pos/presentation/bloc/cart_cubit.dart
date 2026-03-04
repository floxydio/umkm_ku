import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../product/domain/entities/product_entity.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/entities/cart_item_entity.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class CartState extends Equatable {
  final List<CartItemEntity> items;
  final int subtotal;
  final int discount;
  final int total;
  final int paid;
  final int change;

  const CartState({
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paid,
    required this.change,
  });

  const CartState.empty()
      : items = const [],
        subtotal = 0,
        discount = 0,
        total = 0,
        paid = 0,
        change = 0;

  bool get isEmpty => items.isEmpty;
  bool get canPay => !isEmpty && paid >= total && total > 0;
  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);

  CartEntity toCartEntity() => CartEntity(
        items: items,
        subtotal: subtotal,
        discount: discount,
        total: total,
        paid: paid,
        change: change,
      );

  @override
  List<Object?> get props =>
      [items, subtotal, discount, total, paid, change];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState.empty());

  void addToCart(ProductEntity product) {
    if (product.stock <= 0) return;

    final existingIndex =
        state.items.indexWhere((i) => i.product.id == product.id);
    List<CartItemEntity> updatedItems;

    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      // Don't exceed stock
      if (existing.quantity >= product.stock) return;
      updatedItems = List.of(state.items);
      updatedItems[existingIndex] =
          existing.copyWith(quantity: existing.quantity + 1);
    } else {
      updatedItems = [...state.items, CartItemEntity(product: product, quantity: 1)];
    }

    emit(_compute(items: updatedItems, discount: state.discount, paid: state.paid));
  }

  void removeFromCart(String productId) {
    final updatedItems =
        state.items.where((i) => i.product.id != productId).toList();
    emit(_compute(items: updatedItems, discount: state.discount, paid: state.paid));
  }

  void updateQuantity(String productId, int qty) {
    if (qty <= 0) {
      removeFromCart(productId);
      return;
    }

    final updatedItems = List.of(state.items);
    final idx = updatedItems.indexWhere((i) => i.product.id == productId);
    if (idx < 0) return;

    final item = updatedItems[idx];
    // Don't exceed stock
    final clampedQty = qty.clamp(1, item.product.stock);
    updatedItems[idx] = item.copyWith(quantity: clampedQty);

    emit(_compute(items: updatedItems, discount: state.discount, paid: state.paid));
  }

  void applyDiscount(int amount) {
    final safeDiscount = amount.clamp(0, state.subtotal);
    emit(_compute(
        items: state.items, discount: safeDiscount, paid: state.paid));
  }

  void updatePaid(int amount) {
    emit(_compute(
        items: state.items, discount: state.discount, paid: amount));
  }

  void clearCart() {
    emit(const CartState.empty());
  }

  CartState _compute({
    required List<CartItemEntity> items,
    required int discount,
    required int paid,
  }) {
    final subtotal = items.fold(0, (sum, i) => sum + i.subtotal);
    final safeDiscount = discount.clamp(0, subtotal);
    final total = (subtotal - safeDiscount).clamp(0, subtotal);
    final change = paid >= total ? paid - total : 0;

    return CartState(
      items: items,
      subtotal: subtotal,
      discount: safeDiscount,
      total: total,
      paid: paid,
      change: change,
    );
  }
}
