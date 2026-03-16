import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'core/app_theme.dart';
import 'data/services/http_client.dart';
import 'data/services/oref_alerts_service.dart';
import 'data/services/oref_districts_service.dart';
import 'data/services/oref_history_service.dart';
import 'data/services/rss_news_service.dart';
import 'data/services/polling_manager.dart';
import 'presentation/providers/location_provider.dart';
import 'presentation/providers/alerts_provider.dart';
import 'presentation/providers/news_provider.dart';
import 'presentation/providers/connectivity_provider.dart';
import 'presentation/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MklatApp());
}

class MklatApp extends StatefulWidget {
  final http.Client? httpClient;
  final ConnectivityProvider? connectivityProvider;
  const MklatApp({super.key, this.httpClient, this.connectivityProvider});

  @override
  State<MklatApp> createState() => _MklatAppState();
}

class _MklatAppState extends State<MklatApp> with WidgetsBindingObserver {
  late final HttpClient _httpClient;
  late final PollingManager _pollingManager;
  late final LocationProvider _locationProvider;
  late final AlertsProvider _alertsProvider;
  late final NewsProvider _newsProvider;
  late final ConnectivityProvider _connectivityProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  void _initializeServices() {
    _httpClient = HttpClient(client: widget.httpClient);
    final alertsService = OrefAlertsService(_httpClient);
    final historyService = OrefHistoryService(_httpClient);
    final newsService = RssNewsService(_httpClient);
    final districtsService = OrefDistrictsService(_httpClient);

    _pollingManager = PollingManager(
      alertsService: alertsService,
      historyService: historyService,
      newsService: newsService,
    );

    _locationProvider = LocationProvider();
    _alertsProvider = AlertsProvider();
    _newsProvider = NewsProvider();
    _connectivityProvider =
        widget.connectivityProvider ?? ConnectivityProvider();

    // Wire polling callbacks to providers
    _pollingManager.onAlertData = (currentAlerts, alertHistory) {
      _connectivityProvider.reportHttpSuccess();
      _alertsProvider.onAlertData(currentAlerts, alertHistory);
    };
    _pollingManager.onNewsData = (newsItems) {
      _connectivityProvider.reportHttpSuccess();
      _newsProvider.onNewsData(newsItems);
    };
    _pollingManager.onError = (source, error) {
      _connectivityProvider.reportHttpFailure();
      _alertsProvider.onError(source, error);
      _newsProvider.onError(source, error);
    };

    // Listen for location changes to update state machine
    _locationProvider.addListener(_onLocationChange);

    // Initialize
    _locationProvider.loadLocations();
    _locationProvider.loadAvailableLocations(districtsService);
    _connectivityProvider.initialize();
    _pollingManager.start();
  }

  void _onLocationChange() {
    final primary = _locationProvider.primaryLocation;
    _alertsProvider.setPrimaryLocation(primary?.orefName);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _alertsProvider.setResuming(true);
        _pollingManager.start();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _pollingManager.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationProvider.removeListener(_onLocationChange);
    _pollingManager.dispose();
    _httpClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _locationProvider),
        ChangeNotifierProvider.value(value: _alertsProvider),
        ChangeNotifierProvider.value(value: _newsProvider),
        ChangeNotifierProvider.value(value: _connectivityProvider),
      ],
      child: MaterialApp(
        title: 'mklat.news',
        debugShowCheckedModeBanner: false,
        locale: const Locale('he', 'IL'),
        supportedLocales: const [Locale('he', 'IL')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: AppShell(),
        ),
      ),
    );
  }
}
