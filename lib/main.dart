import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'application/app_session.dart';
import 'core/app_theme.dart';
import 'presentation/providers/connectivity_provider.dart';
import 'presentation/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MklatApp());
}

class MklatApp extends StatefulWidget {
  final http.Client? httpClient;
  final ConnectivityProvider? connectivityProvider;
  final bool pollingEnabled;
  final bool bootstrapEnabled;
  const MklatApp({
    super.key,
    this.httpClient,
    this.connectivityProvider,
    this.pollingEnabled = true,
    this.bootstrapEnabled = true,
  });

  @override
  State<MklatApp> createState() => _MklatAppState();
}

class _MklatAppState extends State<MklatApp> with WidgetsBindingObserver {
  late final AppSession _session;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session = AppSession(
      client: widget.httpClient,
      connectivityProvider: widget.connectivityProvider,
      pollingEnabled: widget.pollingEnabled,
      bootstrapEnabled: widget.bootstrapEnabled,
    )..start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _session.handleLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _session.locationProvider),
        ChangeNotifierProvider.value(value: _session.alertsProvider),
        ChangeNotifierProvider.value(value: _session.newsProvider),
        ChangeNotifierProvider.value(value: _session.connectivityProvider),
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
