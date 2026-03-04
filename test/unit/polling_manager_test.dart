import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/data/models/alert.dart';
import 'package:mklat/data/models/news_item.dart';
import 'package:mklat/data/services/polling_manager.dart';
import 'package:mockito/mockito.dart';

import '../mocks/mock_services.dart';

void main() {
  group('PollingManager', () {
    late MockOrefAlertsService mockAlertsService;
    late MockOrefHistoryService mockHistoryService;
    late MockRssNewsService mockNewsService;
    late PollingManager manager;

    final testAlert = Alert(
      id: 'test_1',
      location: 'תל אביב',
      title: 'ירי רקטות וטילים',
      time: DateTime.now(),
      category: 1,
    );

    final testNewsItem = NewsItem(
      id: 'news_1',
      title: 'Test News',
      link: 'https://example.com',
      pubDate: DateTime.now(),
      source: NewsSource.ynet,
    );

    setUp(() {
      mockAlertsService = MockOrefAlertsService();
      mockHistoryService = MockOrefHistoryService();
      mockNewsService = MockRssNewsService();

      manager = PollingManager(
        alertsService: mockAlertsService,
        historyService: mockHistoryService,
        newsService: mockNewsService,
      );
    });

    tearDown(() {
      manager.dispose();
    });

    group('start()', () {
      test('triggers immediate fetch for both alerts and news', () async {
        when(
          mockAlertsService.fetchCurrentAlerts(),
        ).thenAnswer((_) async => [testAlert]);
        when(
          mockHistoryService.fetchAlertHistory(),
        ).thenAnswer((_) async => [testAlert]);
        when(
          mockNewsService.fetchAllNews(),
        ).thenAnswer((_) async => [testNewsItem]);

        List<Alert>? receivedCurrentAlerts;
        List<Alert>? receivedHistory;
        List<NewsItem>? receivedNews;

        manager.onAlertData = (current, history) {
          receivedCurrentAlerts = current;
          receivedHistory = history;
        };
        manager.onNewsData = (news) {
          receivedNews = news;
        };

        manager.start();

        // Wait for the immediate async operations to complete
        await Future.delayed(Duration.zero);

        expect(receivedCurrentAlerts, isNotNull);
        expect(receivedCurrentAlerts, hasLength(1));
        expect(receivedHistory, isNotNull);
        expect(receivedHistory, hasLength(1));
        expect(receivedNews, isNotNull);
        expect(receivedNews, hasLength(1));

        verify(mockAlertsService.fetchCurrentAlerts()).called(1);
        verify(mockHistoryService.fetchAlertHistory()).called(1);
        verify(mockNewsService.fetchAllNews()).called(1);
      });

      test(
        'is idempotent - calling start twice does not create duplicate timers',
        () async {
          when(
            mockAlertsService.fetchCurrentAlerts(),
          ).thenAnswer((_) async => [testAlert]);
          when(
            mockHistoryService.fetchAlertHistory(),
          ).thenAnswer((_) async => [testAlert]);
          when(
            mockNewsService.fetchAllNews(),
          ).thenAnswer((_) async => [testNewsItem]);

          manager.start();
          manager.start(); // Second call should be ignored

          // Wait for async operations
          await Future.delayed(Duration.zero);

          // Should only be called once for initial fetch
          verify(mockAlertsService.fetchCurrentAlerts()).called(1);
          verify(mockNewsService.fetchAllNews()).called(1);

          manager.stop();
        },
      );

      test('sets isPolling to true when started', () {
        when(
          mockAlertsService.fetchCurrentAlerts(),
        ).thenAnswer((_) async => []);
        when(
          mockHistoryService.fetchAlertHistory(),
        ).thenAnswer((_) async => []);
        when(mockNewsService.fetchAllNews()).thenAnswer((_) async => []);

        expect(manager.isPolling, isFalse);
        manager.start();
        expect(manager.isPolling, isTrue);

        manager.stop();
      });
    });

    group('stop()', () {
      test('cancels timers and stops callbacks', () async {
        when(
          mockAlertsService.fetchCurrentAlerts(),
        ).thenAnswer((_) async => [testAlert]);
        when(
          mockHistoryService.fetchAlertHistory(),
        ).thenAnswer((_) async => [testAlert]);
        when(
          mockNewsService.fetchAllNews(),
        ).thenAnswer((_) async => [testNewsItem]);

        manager.start();
        await Future.delayed(Duration.zero);

        // Clear verification counts after initial fetch
        clearInteractions(mockAlertsService);
        clearInteractions(mockNewsService);

        // Stop polling
        manager.stop();

        // Wait a bit - no additional callbacks should fire
        await Future.delayed(Duration(milliseconds: 100));

        verifyNever(mockAlertsService.fetchCurrentAlerts());
        verifyNever(mockNewsService.fetchAllNews());
      });

      test('sets isPolling to false', () {
        when(
          mockAlertsService.fetchCurrentAlerts(),
        ).thenAnswer((_) async => []);
        when(
          mockHistoryService.fetchAlertHistory(),
        ).thenAnswer((_) async => []);
        when(mockNewsService.fetchAllNews()).thenAnswer((_) async => []);

        manager.start();
        expect(manager.isPolling, isTrue);

        manager.stop();
        expect(manager.isPolling, isFalse);
      });
    });

    group('alert poll', () {
      test('fetches current alerts and history in parallel', () async {
        when(
          mockAlertsService.fetchCurrentAlerts(),
        ).thenAnswer((_) async => [testAlert]);
        when(
          mockHistoryService.fetchAlertHistory(),
        ).thenAnswer((_) async => [testAlert]);
        when(
          mockNewsService.fetchAllNews(),
        ).thenAnswer((_) async => [testNewsItem]);

        List<Alert>? receivedCurrentAlerts;
        List<Alert>? receivedHistory;

        manager.onAlertData = (current, history) {
          receivedCurrentAlerts = current;
          receivedHistory = history;
        };

        manager.start();
        await Future.delayed(Duration.zero);

        expect(receivedCurrentAlerts, [testAlert]);
        expect(receivedHistory, [testAlert]);

        verify(mockAlertsService.fetchCurrentAlerts()).called(1);
        verify(mockHistoryService.fetchAlertHistory()).called(1);

        manager.stop();
      });
    });

    group('news poll', () {
      test('fetches RSS news on each tick', () async {
        when(
          mockAlertsService.fetchCurrentAlerts(),
        ).thenAnswer((_) async => []);
        when(
          mockHistoryService.fetchAlertHistory(),
        ).thenAnswer((_) async => []);
        when(
          mockNewsService.fetchAllNews(),
        ).thenAnswer((_) async => [testNewsItem]);

        List<NewsItem>? receivedNews;

        manager.onNewsData = (news) {
          receivedNews = news;
        };

        manager.start();
        await Future.delayed(Duration.zero);

        expect(receivedNews, [testNewsItem]);
        verify(mockNewsService.fetchAllNews()).called(1);

        manager.stop();
      });
    });

    group('refresh()', () {
      test('triggers immediate poll for both alerts and news', () async {
        when(
          mockAlertsService.fetchCurrentAlerts(),
        ).thenAnswer((_) async => [testAlert]);
        when(
          mockHistoryService.fetchAlertHistory(),
        ).thenAnswer((_) async => [testAlert]);
        when(
          mockNewsService.fetchAllNews(),
        ).thenAnswer((_) async => [testNewsItem]);

        List<Alert>? receivedCurrentAlerts;
        List<Alert>? receivedHistory;
        List<NewsItem>? receivedNews;

        manager.onAlertData = (current, history) {
          receivedCurrentAlerts = current;
          receivedHistory = history;
        };
        manager.onNewsData = (news) {
          receivedNews = news;
        };

        await manager.refresh();

        expect(receivedCurrentAlerts, [testAlert]);
        expect(receivedHistory, [testAlert]);
        expect(receivedNews, [testNewsItem]);

        verify(mockAlertsService.fetchCurrentAlerts()).called(1);
        verify(mockHistoryService.fetchAlertHistory()).called(1);
        verify(mockNewsService.fetchAllNews()).called(1);
      });
    });

    group('error handling', () {
      test(
        'error in alerts service calls onError but does not crash',
        () async {
          final error = Exception('Network error');
          when(mockAlertsService.fetchCurrentAlerts()).thenThrow(error);
          when(
            mockHistoryService.fetchAlertHistory(),
          ).thenAnswer((_) async => []);
          when(
            mockNewsService.fetchAllNews(),
          ).thenAnswer((_) async => [testNewsItem]);

          String? errorSource;
          Object? receivedError;
          List<NewsItem>? receivedNews;

          manager.onError = (source, err) {
            errorSource = source;
            receivedError = err;
          };
          manager.onNewsData = (news) {
            receivedNews = news;
          };

          manager.start();
          await Future.delayed(Duration.zero);

          expect(errorSource, 'alerts');
          expect(receivedError, error);
          // News should still be delivered
          expect(receivedNews, [testNewsItem]);

          manager.stop();
        },
      );

      test('error in news service calls onError', () async {
        final error = Exception('RSS error');
        when(
          mockAlertsService.fetchCurrentAlerts(),
        ).thenAnswer((_) async => []);
        when(
          mockHistoryService.fetchAlertHistory(),
        ).thenAnswer((_) async => []);
        when(mockNewsService.fetchAllNews()).thenThrow(error);

        String? errorSource;
        Object? receivedError;

        manager.onError = (source, err) {
          errorSource = source;
          receivedError = err;
        };

        manager.start();
        await Future.delayed(Duration.zero);

        expect(errorSource, 'news');
        expect(receivedError, error);

        manager.stop();
      });
    });

    group('dispose()', () {
      test('stops polling', () {
        when(
          mockAlertsService.fetchCurrentAlerts(),
        ).thenAnswer((_) async => []);
        when(
          mockHistoryService.fetchAlertHistory(),
        ).thenAnswer((_) async => []);
        when(mockNewsService.fetchAllNews()).thenAnswer((_) async => []);

        manager.start();
        expect(manager.isPolling, isTrue);

        manager.dispose();
        expect(manager.isPolling, isFalse);
      });
    });
  });
}
