import 'package:equatable/equatable.dart';

class TransactionItemEntity extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int subtotal;

  const TransactionItemEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  @override
  List<Object?> get props =>
      [id, productId, productName, quantity, unitPrice, subtotal];
}

class TransactionEntity extends Equatable {
  final String id;
  final int totalAmount;
  final int discountAmount;
  final int paidAmount;
  final int changeAmount;
  final String cashierId;
  final DateTime createdAt;
  final List<TransactionItemEntity> items;

  const TransactionEntity({
    required this.id,
    required this.totalAmount,
    required this.discountAmount,
    required this.paidAmount,
    required this.changeAmount,
    required this.cashierId,
    required this.createdAt,
    required this.items,
  });

  @override
  List<Object?> get props => [
        id,
        totalAmount,
        discountAmount,
        paidAmount,
        changeAmount,
        cashierId,
        createdAt,
        items,
      ];
}
