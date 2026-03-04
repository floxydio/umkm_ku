import 'dart:async';

import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/entities/today_summary_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/pos_repository.dart';
import '../datasources/pos_local_datasource.dart';

@LazySingleton(as: PosRepository)
class PosRepositoryImpl implements PosRepository {
  final PosLocalDataSource _datasource;
  final _uuid = const Uuid();

  PosRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, String>> saveTransaction(
    CartEntity cart,
    String cashierId,
    String cashierName,
  ) async {
    try {
      // Ensure cashier exists in local app_users table
      final resolvedCashierId =
          await _datasource.ensureCashier(cashierId, cashierName);

      final now = DateTime.now();
      final transactionId = _uuid.v4();
      final shortId = transactionId.substring(0, 8).toUpperCase();

      // Build transaction companion
      final txn = TransactionsTableCompanion(
        id: Value(transactionId),
        totalAmount: Value(cart.total),
        discountAmount: Value(cart.discount),
        paidAmount: Value(cart.paid),
        changeAmount: Value(cart.change),
        cashierId: Value(resolvedCashierId),
        createdAt: Value(now),
        updatedAt: Value(now),
      );

      // Build items
      final items = cart.items.map((item) {
        return TransactionItemsTableCompanion(
          id: Value(_uuid.v4()),
          transactionId: Value(transactionId),
          productId: Value(item.product.id),
          productName: Value(item.product.name),
          quantity: Value(item.quantity),
          unitPrice: Value(item.product.price),
          subtotal: Value(item.subtotal),
          createdAt: Value(now),
          updatedAt: Value(now),
        );
      }).toList();

      // Build stock updates
      final stockUpdates = cart.items.map((item) {
        final newStock = (item.product.stock - item.quantity).clamp(0, 999999);
        return (productId: item.product.id, newStock: newStock);
      }).toList();

      // Build stock logs
      final stockLogs = cart.items.map((item) {
        return StockLogsTableCompanion(
          id: Value(_uuid.v4()),
          productId: Value(item.product.id),
          type: const Value('out'),
          quantity: Value(item.quantity),
          note: Value('Penjualan #$shortId'),
          createdAt: Value(now),
          updatedAt: Value(now),
        );
      }).toList();

      // Save everything atomically
      await _datasource.saveFullTransaction(txn, items, stockUpdates, stockLogs);

      return Right(transactionId);
    } catch (e) {
      return Left(LocalFailure('Gagal menyimpan transaksi: ${e.toString()}'));
    }
  }

  @override
  Stream<Either<Failure, List<TransactionEntity>>> watchTodayTransactions() {
    return _datasource.watchTodayTransactions().asyncMap((txnList) async {
      try {
        final result = <TransactionEntity>[];
        for (final txn in txnList) {
          final items = await _datasource.getItemsByTransaction(txn.id);
          result.add(
            TransactionEntity(
              id: txn.id,
              totalAmount: txn.totalAmount,
              discountAmount: txn.discountAmount,
              paidAmount: txn.paidAmount,
              changeAmount: txn.changeAmount,
              cashierId: txn.cashierId,
              createdAt: txn.createdAt,
              items: items
                  .map((i) => TransactionItemEntity(
                        id: i.id,
                        productId: i.productId,
                        productName: i.productName,
                        quantity: i.quantity,
                        unitPrice: i.unitPrice,
                        subtotal: i.subtotal,
                      ))
                  .toList(),
            ),
          );
        }
        return Right<Failure, List<TransactionEntity>>(result);
      } catch (e) {
        return Left<Failure, List<TransactionEntity>>(
            LocalFailure('Gagal memuat transaksi: ${e.toString()}'));
      }
    });
  }

  @override
  Future<Either<Failure, TodaySummaryEntity>> getTodaySummary() async {
    try {
      final total = await _datasource.getTodayTotal();
      final count = await _datasource.getTodayTransactionCount();
      return Right(TodaySummaryEntity(
        totalRevenue: total,
        transactionCount: count,
      ));
    } catch (e) {
      return Left(LocalFailure('Gagal memuat ringkasan: ${e.toString()}'));
    }
  }
}
