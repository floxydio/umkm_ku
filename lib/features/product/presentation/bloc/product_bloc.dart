import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/add_product_usecase.dart';
import '../../domain/usecases/delete_product_usecase.dart';
import '../../domain/usecases/update_product_usecase.dart';
import '../../domain/usecases/watch_categories_usecase.dart';
import '../../domain/usecases/watch_products_usecase.dart';

// ── Events ──────────────────────────────────────────────────────────────────

abstract class ProductEvent extends Equatable {
  const ProductEvent();
  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {
  const LoadProducts();
}

class AddProduct extends ProductEvent {
  final AddProductParams params;
  const AddProduct(this.params);
  @override
  List<Object?> get props => [params];
}

class UpdateProduct extends ProductEvent {
  final UpdateProductParams params;
  const UpdateProduct(this.params);
  @override
  List<Object?> get props => [params];
}

class DeleteProduct extends ProductEvent {
  final String id;
  const DeleteProduct(this.id);
  @override
  List<Object?> get props => [id];
}

class _ProductsUpdated extends ProductEvent {
  final List<ProductEntity> products;
  const _ProductsUpdated(this.products);
  @override
  List<Object?> get props => [products];
}

class _CategoriesUpdated extends ProductEvent {
  final List<CategoryEntity> categories;
  const _CategoriesUpdated(this.categories);
  @override
  List<Object?> get props => [categories];
}

class AddCategory extends ProductEvent {
  final String name;
  const AddCategory(this.name);
  @override
  List<Object?> get props => [name];
}

class _StreamError extends ProductEvent {
  final String message;
  const _StreamError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── States ───────────────────────────────────────────────────────────────────

abstract class ProductState extends Equatable {
  const ProductState();
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {
  const ProductInitial();
}

class ProductLoading extends ProductState {
  const ProductLoading();
}

class ProductLoaded extends ProductState {
  final List<ProductEntity> products;
  final List<CategoryEntity> categories;

  const ProductLoaded({required this.products, required this.categories});

  @override
  List<Object?> get props => [products, categories];
}

class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);
  @override
  List<Object?> get props => [message];
}

class ProductActionSuccess extends ProductState {
  final List<ProductEntity> products;
  final List<CategoryEntity> categories;

  const ProductActionSuccess({required this.products, required this.categories});

  @override
  List<Object?> get props => [products, categories];
}

// ── Bloc ─────────────────────────────────────────────────────────────────────

@injectable
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final WatchProductsUseCase _watchProducts;
  final AddProductUseCase _addProduct;
  final UpdateProductUseCase _updateProduct;
  final DeleteProductUseCase _deleteProduct;
  final WatchCategoriesUseCase _watchCategories;
  final ProductRepository _repository;

  StreamSubscription<dynamic>? _productsSub;
  StreamSubscription<dynamic>? _categoriesSub;

  List<ProductEntity> _products = [];
  List<CategoryEntity> _categories = [];

  ProductBloc(
    this._watchProducts,
    this._addProduct,
    this._updateProduct,
    this._deleteProduct,
    this._watchCategories,
    this._repository,
  ) : super(const ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
    on<AddCategory>(_onAddCategory);
    on<_ProductsUpdated>(_onProductsUpdated);
    on<_CategoriesUpdated>(_onCategoriesUpdated);
    on<_StreamError>(_onStreamError);
  }

  Future<void> _onLoadProducts(
      LoadProducts event, Emitter<ProductState> emit) async {
    emit(const ProductLoading());

    await _productsSub?.cancel();
    await _categoriesSub?.cancel();

    _productsSub = _watchProducts().listen(
      (result) => result.fold(
        (failure) => add(_StreamError(failure.message)),
        (products) => add(_ProductsUpdated(products)),
      ),
    );

    _categoriesSub = _watchCategories().listen(
      (result) => result.fold(
        (failure) => add(_StreamError(failure.message)),
        (categories) => add(_CategoriesUpdated(categories)),
      ),
    );
  }

  void _onProductsUpdated(
      _ProductsUpdated event, Emitter<ProductState> emit) {
    _products = event.products;
    emit(ProductLoaded(products: _products, categories: _categories));
  }

  void _onCategoriesUpdated(
      _CategoriesUpdated event, Emitter<ProductState> emit) {
    _categories = event.categories;
    if (state is! ProductLoading) {
      emit(ProductLoaded(products: _products, categories: _categories));
    }
  }

  void _onStreamError(_StreamError event, Emitter<ProductState> emit) {
    emit(ProductError(event.message));
  }

  Future<void> _onAddProduct(
      AddProduct event, Emitter<ProductState> emit) async {
    final result = await _addProduct(event.params);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (_) => emit(
          ProductActionSuccess(products: _products, categories: _categories)),
    );
  }

  Future<void> _onUpdateProduct(
      UpdateProduct event, Emitter<ProductState> emit) async {
    final result = await _updateProduct(event.params);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (_) => emit(
          ProductActionSuccess(products: _products, categories: _categories)),
    );
  }

  Future<void> _onDeleteProduct(
      DeleteProduct event, Emitter<ProductState> emit) async {
    final result = await _deleteProduct(event.id);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (_) => emit(
          ProductActionSuccess(products: _products, categories: _categories)),
    );
  }

  Future<void> _onAddCategory(
      AddCategory event, Emitter<ProductState> emit) async {
    final result = await _repository.addCategory(event.name);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (_) => emit(ProductLoaded(products: _products, categories: _categories)),
    );
  }

  @override
  Future<void> close() {
    _productsSub?.cancel();
    _categoriesSub?.cancel();
    return super.close();
  }
}
