import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity;
  StreamSubscription<ConnectivityResult>? _subscription;
  bool _isOffline = false;

  ConnectivityProvider({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  bool get isOffline => _isOffline;

  /// Start monitoring connectivity. Call once on app start.
  Future<void> initialize() async {
    // Check current status
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(ConnectivityResult result) {
    final wasOffline = _isOffline;
    _isOffline = result == ConnectivityResult.none;
    if (wasOffline != _isOffline) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
