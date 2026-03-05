import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/entities/debt_summary_entity.dart';
import '../../domain/repositories/debt_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class DebtEvent extends Equatable {
  const DebtEvent();
  @override
  List<Object?> get props => [];
}

class LoadCustomers extends DebtEvent {
  const LoadCustomers();
}

class AddCustomer extends DebtEvent {
  final AddCustomerParams params;
  const AddCustomer(this.params);
  @override
  List<Object?> get props => [params];
}

class LoadDebtsByCustomer extends DebtEvent {
  final CustomerEntity customer;
  const LoadDebtsByCustomer(this.customer);
  @override
  List<Object?> get props => [customer];
}

class AddDebt extends DebtEvent {
  final AddDebtParams params;
  const AddDebt(this.params);
  @override
  List<Object?> get props => [params];
}

class AddPayment extends DebtEvent {
  final String debtId;
  final int amount;
  final DateTime paidAt;
  const AddPayment({
    required this.debtId,
    required this.amount,
    required this.paidAt,
  });
  @override
  List<Object?> get props => [debtId, amount, paidAt];
}

class _CustomersUpdated extends DebtEvent {
  final List<CustomerEntity> customers;
  const _CustomersUpdated(this.customers);
  @override
  List<Object?> get props => [customers];
}

class _DebtsUpdated extends DebtEvent {
  final List<DebtEntity> debts;
  const _DebtsUpdated(this.debts);
  @override
  List<Object?> get props => [debts];
}

class _CurrentCustomerUpdated extends DebtEvent {
  final CustomerEntity? customer;
  const _CurrentCustomerUpdated(this.customer);
  @override
  List<Object?> get props => [customer];
}

class _StreamError extends DebtEvent {
  final String message;
  const _StreamError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class DebtState extends Equatable {
  const DebtState();
  @override
  List<Object?> get props => [];
}

class DebtInitial extends DebtState {
  const DebtInitial();
}

class DebtLoading extends DebtState {
  const DebtLoading();
}

class CustomersLoaded extends DebtState {
  final List<CustomerEntity> customers;
  final DebtSummaryEntity summary;

  const CustomersLoaded({required this.customers, required this.summary});

  @override
  List<Object?> get props => [customers, summary];
}

class DebtsLoaded extends DebtState {
  final CustomerEntity customer;
  final List<DebtEntity> debts;

  const DebtsLoaded({required this.customer, required this.debts});

  @override
  List<Object?> get props => [customer, debts];
}

class DebtActionSuccess extends DebtState {
  const DebtActionSuccess();
}

class DebtError extends DebtState {
  final String message;
  const DebtError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Bloc ──────────────────────────────────────────────────────────────────────

@injectable
class DebtBloc extends Bloc<DebtEvent, DebtState> {
  final DebtRepository _repository;

  StreamSubscription<dynamic>? _customersSub;
  StreamSubscription<dynamic>? _debtsSub;
  StreamSubscription<dynamic>? _currentCustomerSub;

  List<CustomerEntity> _customers = [];
  DebtSummaryEntity _summary = const DebtSummaryEntity(
    totalCustomers: 0,
    totalDebt: 0,
    totalPaid: 0,
    totalRemaining: 0,
  );
  List<DebtEntity> _debts = [];
  CustomerEntity? _currentCustomer;

  DebtBloc(this._repository) : super(const DebtInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<AddCustomer>(_onAddCustomer);
    on<LoadDebtsByCustomer>(_onLoadDebtsByCustomer);
    on<AddDebt>(_onAddDebt);
    on<AddPayment>(_onAddPayment);
    on<_CustomersUpdated>(_onCustomersUpdated);
    on<_DebtsUpdated>(_onDebtsUpdated);
    on<_CurrentCustomerUpdated>(_onCurrentCustomerUpdated);
    on<_StreamError>(_onStreamError);
  }

  Future<void> _onLoadCustomers(
      LoadCustomers event, Emitter<DebtState> emit) async {
    emit(const DebtLoading());
    await _debtsSub?.cancel();
    await _currentCustomerSub?.cancel();
    await _customersSub?.cancel();

    _customersSub = _repository.watchCustomers().listen(
      (result) => result.fold(
        (f) => add(_StreamError(f.message)),
        (customers) => add(_CustomersUpdated(customers)),
      ),
    );
  }

  Future<void> _onCustomersUpdated(
      _CustomersUpdated event, Emitter<DebtState> emit) async {
    _customers = event.customers;
    final summaryResult = await _repository.getTotalDebtSummary();
    summaryResult.fold(
      (_) => emit(CustomersLoaded(customers: _customers, summary: _summary)),
      (summary) {
        _summary = summary;
        emit(CustomersLoaded(customers: _customers, summary: _summary));
      },
    );
  }

  Future<void> _onAddCustomer(
      AddCustomer event, Emitter<DebtState> emit) async {
    final result = await _repository.addCustomer(event.params);
    result.fold(
      (f) => emit(DebtError(f.message)),
      (_) => emit(const DebtActionSuccess()),
    );
  }

  Future<void> _onLoadDebtsByCustomer(
      LoadDebtsByCustomer event, Emitter<DebtState> emit) async {
    emit(const DebtLoading());
    await _customersSub?.cancel();
    await _debtsSub?.cancel();
    await _currentCustomerSub?.cancel();

    _currentCustomer = event.customer;
    _debts = [];

    _debtsSub = _repository.watchDebtsByCustomer(event.customer.id).listen(
      (result) => result.fold(
        (f) => add(_StreamError(f.message)),
        (debts) => add(_DebtsUpdated(debts)),
      ),
    );

    _currentCustomerSub =
        _repository.watchCustomerById(event.customer.id).listen(
      (result) => result.fold(
        (_) {},
        (customer) => add(_CurrentCustomerUpdated(customer)),
      ),
    );
  }

  void _onDebtsUpdated(_DebtsUpdated event, Emitter<DebtState> emit) {
    _debts = event.debts;
    if (_currentCustomer != null) {
      emit(DebtsLoaded(customer: _currentCustomer!, debts: _debts));
    }
  }

  void _onCurrentCustomerUpdated(
      _CurrentCustomerUpdated event, Emitter<DebtState> emit) {
    if (event.customer != null) {
      _currentCustomer = event.customer;
    }
    if (_currentCustomer != null) {
      emit(DebtsLoaded(customer: _currentCustomer!, debts: _debts));
    }
  }

  Future<void> _onAddDebt(AddDebt event, Emitter<DebtState> emit) async {
    final result = await _repository.addDebt(event.params);
    result.fold(
      (f) => emit(DebtError(f.message)),
      (_) => emit(const DebtActionSuccess()),
    );
  }

  Future<void> _onAddPayment(
      AddPayment event, Emitter<DebtState> emit) async {
    final result = await _repository.addPayment(
        event.debtId, event.amount, event.paidAt);
    result.fold(
      (f) => emit(DebtError(f.message)),
      (_) => emit(const DebtActionSuccess()),
    );
  }

  void _onStreamError(_StreamError event, Emitter<DebtState> emit) {
    emit(DebtError(event.message));
  }

  @override
  Future<void> close() {
    _customersSub?.cancel();
    _debtsSub?.cancel();
    _currentCustomerSub?.cancel();
    return super.close();
  }
}
