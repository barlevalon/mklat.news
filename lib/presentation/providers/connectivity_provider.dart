import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Tracks connectivity via two signals:
/// 1. [connectivity_plus] plugin (network interface state)
/// 2. HTTP request success/failure from polling (actual reachability)
///
/// Goes offline when EITHER:
/// - connectivity_plus reports [ConnectivityResult.none]
/// - [consecutiveFailureThreshold] HTTP failures in a row
///
/// Goes online when EITHER:
/// - An HTTP request succeeds ([reportHttpSuccess])
/// - connectivity_plus reports a connection AND no recent HTTP failures
class ConnectivityProvider extends ChangeNotifier {
  final Connectivity? _connectivity;
  final Stream<ConnectivityResult>? _overrideStream;
  StreamSubscription<ConnectivityResult>? _subscription;

  bool _isOffline = false;
  bool _pluginSaysOffline = false;
  int _consecutiveHttpFailures = 0;

  /// How many consecutive HTTP failures before declaring offline.
  static const int consecutiveFailureThreshold = 2;

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
      _subscription = _overrideStream.listen(_onPluginEvent);
      return;
    }

    // Check current status
    final result = await _connectivity!.checkConnectivity();
    _onPluginEvent(result);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_onPluginEvent);
  }

  /// Called by the polling manager when an HTTP request succeeds.
  void reportHttpSuccess() {
    _consecutiveHttpFailures = 0;
    _updateOfflineState();
  }

  /// Called by the polling manager when an HTTP request fails.
  void reportHttpFailure() {
    _consecutiveHttpFailures++;
    _updateOfflineState();
  }

  void _onPluginEvent(ConnectivityResult result) {
    _pluginSaysOffline = result == ConnectivityResult.none;
    _updateOfflineState();
  }

  void _updateOfflineState() {
    final wasOffline = _isOffline;
    _isOffline =
        _pluginSaysOffline ||
        _consecutiveHttpFailures >= consecutiveFailureThreshold;
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
