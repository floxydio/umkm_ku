import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

import 'sync_cubit.dart';

/// Watches network state and triggers [SyncCubit.sync] on reconnect.
/// Debounces 3 seconds to avoid rapid firing when toggling WiFi.
@lazySingleton
class ConnectivityListener {
  final SyncCubit _syncCubit;

  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _debounce;

  ConnectivityListener(this._syncCubit);

  void start() {
    _sub = Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  void dispose() {
    _debounce?.cancel();
    _sub?.cancel();
    _sub = null;
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasNetwork = results.any((r) => r != ConnectivityResult.none);
    if (hasNetwork) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 3), _syncCubit.sync);
    } else {
      // Cancel pending sync if connectivity is lost before the debounce fires.
      _debounce?.cancel();
    }
  }
}
