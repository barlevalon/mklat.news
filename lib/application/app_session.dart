import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../data/services/http_client.dart';
import '../data/services/oref_alerts_service.dart';
import '../data/services/oref_districts_service.dart';
import '../data/services/oref_history_service.dart';
import 'polling_manager.dart';
import '../data/services/rss_news_service.dart';
import '../presentation/providers/alerts_provider.dart';
import '../presentation/providers/connectivity_provider.dart';
import '../presentation/providers/location_provider.dart';
import '../presentation/providers/news_provider.dart';

class AppSession {
  final bool pollingEnabled;
  final bool bootstrapEnabled;

  late final HttpClient httpClient;
  late final PollingManager pollingManager;
  late final LocationProvider locationProvider;
  late final AlertsProvider alertsProvider;
  late final NewsProvider newsProvider;
  late final ConnectivityProvider connectivityProvider;

  late final OrefDistrictsService _districtsService;

  AppSession({
    http.Client? client,
    ConnectivityProvider? connectivityProvider,
    this.pollingEnabled = true,
    this.bootstrapEnabled = true,
  }) {
    httpClient = HttpClient(client: client);
    final alertsService = OrefAlertsService(httpClient);
    final historyService = OrefHistoryService(httpClient);
    final newsService = RssNewsService(httpClient);
    _districtsService = OrefDistrictsService(httpClient);

    pollingManager = PollingManager(
      alertsService: alertsService,
      historyService: historyService,
      newsService: newsService,
    );

    locationProvider = LocationProvider();
    alertsProvider = AlertsProvider();
    newsProvider = NewsProvider();
    this.connectivityProvider = connectivityProvider ?? ConnectivityProvider();

    _wirePollingCallbacks();
    locationProvider.addListener(_onLocationChange);
  }

  void start() {
    if (!bootstrapEnabled) return;

    locationProvider.loadLocations();
    locationProvider.loadAvailableLocations(_districtsService);
    connectivityProvider.initialize();
    if (pollingEnabled) {
      pollingManager.start();
    }
  }

  void handleLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (bootstrapEnabled && pollingEnabled) {
          alertsProvider.setResuming(true);
          pollingManager.start();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        pollingManager.stop();
        break;
    }
  }

  void dispose() {
    locationProvider.removeListener(_onLocationChange);
    pollingManager.dispose();
    httpClient.dispose();
  }

  void _wirePollingCallbacks() {
    pollingManager.onAlertData = (currentAlerts, alertHistory) {
      connectivityProvider.reportHttpSuccess();
      alertsProvider.onAlertData(currentAlerts, alertHistory);
    };
    pollingManager.onNewsData = (newsItems) {
      connectivityProvider.reportHttpSuccess();
      newsProvider.onNewsData(newsItems);
    };
    pollingManager.onAlertError = (error) {
      connectivityProvider.reportHttpFailure();
      alertsProvider.onError(error);
    };
    pollingManager.onAlertHistoryError = (error) {
      alertsProvider.onHistoryError(error);
    };
    pollingManager.onNewsError = (error) {
      connectivityProvider.reportHttpFailure();
      newsProvider.onError(error);
    };
  }

  void _onLocationChange() {
    final primary = locationProvider.primaryLocation;
    alertsProvider.setPrimaryLocation(primary?.orefName);
  }
}
