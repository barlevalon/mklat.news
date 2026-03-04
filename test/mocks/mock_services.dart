import 'package:mockito/annotations.dart';
import 'package:mklat/data/services/oref_alerts_service.dart';
import 'package:mklat/data/services/oref_history_service.dart';
import 'package:mklat/data/services/rss_news_service.dart';

@GenerateMocks([OrefAlertsService, OrefHistoryService, RssNewsService])
export 'mock_services.mocks.dart';
