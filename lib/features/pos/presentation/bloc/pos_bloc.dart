import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../product/domain/entities/product_entity.dart';
import '../../../product/domain/usecases/watch_products_usecase.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/usecases/save_transaction_usecase.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class PosEvent extends Equatable {
  const PosEvent();
  @override
  List<Object?> get props => [];
}

class LoadProducts extends PosEvent {
  const LoadProducts();
}

class ProcessTransaction extends PosEvent {
  final CartEntity cart;
  final String cashierId;
  final String cashierName;

  const ProcessTransaction({
    required this.cart,
    required this.cashierId,
    required this.cashierName,
  });

  @override
  List<Object?> get props => [cart, cashierId, cashierName];
}

class _ProductsUpdated extends PosEvent {
  final List<ProductEntity> products;
  const _ProductsUpdated(this.products);
  @override
  List<Object?> get props => [products];
}

class _ProductStreamError extends PosEvent {
  final String message;
  const _ProductStreamError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class PosState extends Equatable {
  const PosState();
  @override
  List<Object?> get props => [];
}

class PosInitial extends PosState {
  const PosInitial();
}

class PosLoading extends PosState {
  const PosLoading();
}

class PosReady extends PosState {
  final List<ProductEntity> products;

  const PosReady({required this.products});

  @override
  List<Object?> get props => [products];
}

class PosSuccess extends PosState {
  final String transactionId;
  final CartEntity savedCart;

  const PosSuccess({required this.transactionId, required this.savedCart});

  @override
  List<Object?> get props => [transactionId, savedCart];
}

class PosError extends PosState {
  final String message;

  const PosError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Bloc ──────────────────────────────────────────────────────────────────────

@injectable
class PosBloc extends Bloc<PosEvent, PosState> {
  final WatchProductsUseCase _watchProducts;
  final SaveTransactionUseCase _saveTransaction;

  StreamSubscription<dynamic>? _productsSub;
  List<ProductEntity> _products = [];

  PosBloc(this._watchProducts, this._saveTransaction)
      : super(const PosInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<ProcessTransaction>(_onProcessTransaction);
    on<_ProductsUpdated>(_onProductsUpdated);
    on<_ProductStreamError>(_onProductStreamError);
  }

  Future<void> _onLoadProducts(
      LoadProducts event, Emitter<PosState> emit) async {
    emit(const PosLoading());
    await _productsSub?.cancel();

    _productsSub = _watchProducts().listen(
      (result) => result.fold(
        (failure) => add(_ProductStreamError(failure.message)),
        (products) => add(_ProductsUpdated(products)),
      ),
    );
  }

  void _onProductsUpdated(
      _ProductsUpdated event, Emitter<PosState> emit) {
    _products = event.products;
    emit(PosReady(products: _products));
  }

  void _onProductStreamError(
      _ProductStreamError event, Emitter<PosState> emit) {
    emit(PosError(event.message));
  }

  Future<void> _onProcessTransaction(
      ProcessTransaction event, Emitter<PosState> emit) async {
    // Keep products available but show processing state
    emit(const PosLoading());

    final result = await _saveTransaction(
      SaveTransactionParams(
        cart: event.cart,
        cashierId: event.cashierId,
        cashierName: event.cashierName,
      ),
    );

    result.fold(
      (failure) => emit(PosError(failure.message)),
      (transactionId) => emit(
        PosSuccess(transactionId: transactionId, savedCart: event.cart),
      ),
    );
  }

  /// Restore to ready state after a transaction (success or retry).
  void resetToReady() {
    emit(PosReady(products: _products));
  }

  @override
  Future<void> close() {
    _productsSub?.cancel();
    return super.close();
  }
}
