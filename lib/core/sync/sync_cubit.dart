import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'sync_engine.dart';

// ── States ────────────────────────────────────────────────────────────────────

abstract class SyncState extends Equatable {
  const SyncState();
  @override
  List<Object?> get props => [];
}

class SyncIdle extends SyncState {
  const SyncIdle();
}

class SyncInProgress extends SyncState {
  const SyncInProgress();
}

class SyncSuccess extends SyncState {
  final DateTime lastSyncedAt;
  const SyncSuccess(this.lastSyncedAt);
  @override
  List<Object?> get props => [lastSyncedAt];
}

class SyncError extends SyncState {
  final String message;
  const SyncError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

@lazySingleton
class SyncCubit extends Cubit<SyncState> {
  final SyncEngine _engine;

  SyncCubit(this._engine) : super(const SyncIdle()) {
    // Restore last sync time from previous session.
    final lastSync = _engine.lastSyncedAt;
    if (lastSync != null) emit(SyncSuccess(lastSync));
  }

  Future<void> sync() async {
    if (state is SyncInProgress) return;
    emit(const SyncInProgress());
    try {
      await _engine.sync();
      emit(SyncSuccess(_engine.lastSyncedAt ?? DateTime.now()));
    } catch (e) {
      emit(SyncError(e.toString()));
    }
  }
}
