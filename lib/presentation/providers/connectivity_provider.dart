import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity? _connectivity;
  final Stream<ConnectivityResult>? _overrideStream;
  StreamSubscription<ConnectivityResult>? _subscription;
  bool _isOffline = false;

  /// Production constructor — wraps [connectivity_plus].
  ConnectivityProvider({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity(),
      _overrideStream = null;

  /// Test constructor — accepts a stream of connectivity events directly,
  /// bypassing the platform plugin entirely.
  ConnectivityProvider.fromStream(Stream<ConnectivityResult> stream)
    : _connectivity = null,
      _overrideStream = stream;

  bool get isOffline => _isOffline;

  /// Start monitoring connectivity. Call once on app start.
  Future<void> initialize() async {
    if (_overrideStream != null) {
      _subscription = _overrideStream.listen(_updateStatus);
      return;
    }

    // Check current status
    final result = await _connectivity!.checkConnectivity();
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
