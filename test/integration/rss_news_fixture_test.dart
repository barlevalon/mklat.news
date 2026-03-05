import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mklat/data/models/news_item.dart';
import 'package:mklat/data/services/http_client.dart';
import 'package:mklat/data/services/rss_news_service.dart';
import '../fixtures/fixture_helper.dart';

import 'rss_news_fixture_test.mocks.dart';

const emptyRss = '<?xml version="1.0"?><rss><channel></channel></rss>';

@GenerateMocks([http.Client])
void main() {
  group('RSS News Fixture Tests', () {
    late MockClient mockClient;
    late HttpClient httpClient;
    late RssNewsService newsService;

    setUp(() {
      mockClient = MockClient();
      httpClient = HttpClient(client: mockClient);
      newsService = RssNewsService(httpClient);

      // Default: stub all 4 feeds with empty RSS so per-feed tests don't fail
      // on unstubbed URLs. Each per-feed test overrides the URL it cares about.
      when(
        mockClient.get(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response(emptyRss, 200));
    });

    tearDown(() {
      httpClient.dispose();
    });

    group('Ynet RSS', () {
      test('returns non-empty list from ynet fixture', () async {
        final fixture = await FixtureHelper.loadResponse('rss_ynet');

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('ynet'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final news = await newsService.fetchAllNews();

        expect(news, isNotEmpty);
      });

      test('titles contain Hebrew text', () async {
        final fixture = await FixtureHelper.loadResponse('rss_ynet');

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('ynet'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final news = await newsService.fetchAllNews();

        for (final item in news) {
          final hasHebrew = RegExp(r'[\u0590-\u05FF]').hasMatch(item.title);
          expect(
            hasHebrew,
            isTrue,
            reason: 'Title should have Hebrew: ${item.title}',
          );
        }
      });

      test('links are valid URLs', () async {
        final fixture = await FixtureHelper.loadResponse('rss_ynet');

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('ynet'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final news = await newsService.fetchAllNews();

        for (final item in news) {
          expect(
            item.link.startsWith('http'),
            isTrue,
            reason: 'Link should be valid URL: ${item.link}',
          );
        }
      });

      test('no mojibake in titles', () async {
        final fixture = await FixtureHelper.loadResponse('rss_ynet');

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('ynet'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final news = await newsService.fetchAllNews();

        for (final item in news) {
          expect(
            item.title.contains('×'),
            isFalse,
            reason: 'Title has mojibake: ${item.title}',
          );
        }
      });

      test('source is set to ynet', () async {
        final fixture = await FixtureHelper.loadResponse('rss_ynet');

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('ynet'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final news = await newsService.fetchAllNews();

        for (final item in news) {
          expect(item.source, equals(NewsSource.ynet));
        }
      });
    });

    group('Maariv RSS', () {
      test('returns non-empty list from maariv fixture', () async {
        final fixture = await FixtureHelper.loadResponse('rss_maariv');

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('maariv'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final news = await newsService.fetchAllNews();

        expect(news, isNotEmpty);
      });

      test('titles contain Hebrew text', () async {
        final fixture = await FixtureHelper.loadResponse('rss_maariv');

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('maariv'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final news = await newsService.fetchAllNews();

        for (final item in news) {
          final hasHebrew = RegExp(r'[\u0590-\u05FF]').hasMatch(item.title);
          expect(
            hasHebrew,
            isTrue,
            reason: 'Title should have Hebrew: ${item.title}',
          );
        }
      });

      test('no mojibake in titles', () async {
        final fixture = await FixtureHelper.loadResponse('rss_maariv');

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('maariv'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final news = await newsService.fetchAllNews();

        for (final item in news) {
          expect(
            item.title.contains('×'),
            isFalse,
            reason: 'Title has mojibake: ${item.title}',
          );
        }
      });

      test('source is set to maariv', () async {
        final fixture = await FixtureHelper.loadResponse('rss_maariv');

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('maariv'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final news = await newsService.fetchAllNews();

        for (final item in news) {
          expect(item.source, equals(NewsSource.maariv));
        }
      });
    });

    group('Mako RSS', () {
      test('returns non-empty list from mako fixture', () async {
        final fixture = await FixtureHelper.loadResponse('rss_mako');

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('mako'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final news = await newsService.fetchAllNews();

        expect(news, isNotEmpty);
      });

      test('titles contain Hebrew text', () async {
        final fixture = await FixtureHelper.loadResponse('rss_mako');

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('mako'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final news = await newsService.fetchAllNews();

        for (final item in news) {
          final hasHebrew = RegExp(r'[\u0590-\u05FF]').hasMatch(item.title);
          expect(
            hasHebrew,
            isTrue,
            reason: 'Title should have Hebrew: ${item.title}',
          );
        }
      });

      test('no mojibake in titles', () async {
        final fixture = await FixtureHelper.loadResponse('rss_mako');

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('mako'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final news = await newsService.fetchAllNews();

        for (final item in news) {
          expect(
            item.title.contains('×'),
            isFalse,
            reason: 'Title has mojibake: ${item.title}',
          );
        }
      });

      test('source is set to mako', () async {
        final fixture = await FixtureHelper.loadResponse('rss_mako');

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('mako'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final news = await newsService.fetchAllNews();

        for (final item in news) {
          expect(item.source, equals(NewsSource.mako));
        }
      });
    });

    group('Haaretz RSS', () {
      test('returns non-empty list from haaretz fixture', () async {
        final fixture = await FixtureHelper.loadResponse('rss_haaretz');

        when(
          mockClient.get(
            argThat(
              predicate<Uri>((uri) => uri.toString().contains('haaretz')),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final news = await newsService.fetchAllNews();

        expect(news, isNotEmpty);
      });

      test('titles contain Hebrew text', () async {
        final fixture = await FixtureHelper.loadResponse('rss_haaretz');

        when(
          mockClient.get(
            argThat(
              predicate<Uri>((uri) => uri.toString().contains('haaretz')),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final news = await newsService.fetchAllNews();

        for (final item in news) {
          final hasHebrew = RegExp(r'[\u0590-\u05FF]').hasMatch(item.title);
          expect(
            hasHebrew,
            isTrue,
            reason: 'Title should have Hebrew: ${item.title}',
          );
        }
      });

      test('no mojibake in titles', () async {
        final fixture = await FixtureHelper.loadResponse('rss_haaretz');

        when(
          mockClient.get(
            argThat(
              predicate<Uri>((uri) => uri.toString().contains('haaretz')),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final news = await newsService.fetchAllNews();

        for (final item in news) {
          expect(
            item.title.contains('×'),
            isFalse,
            reason: 'Title has mojibake: ${item.title}',
          );
        }
      });

      test('source is set to haaretz', () async {
        final fixture = await FixtureHelper.loadResponse('rss_haaretz');

        when(
          mockClient.get(
            argThat(
              predicate<Uri>((uri) => uri.toString().contains('haaretz')),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final news = await newsService.fetchAllNews();

        for (final item in news) {
          expect(item.source, equals(NewsSource.haaretz));
        }
      });
    });

    group('Combined feed test', () {
      test('all 4 feeds combined with correct sources', () async {
        final ynetFixture = await FixtureHelper.loadResponse('rss_ynet');
        final maarivFixture = await FixtureHelper.loadResponse('rss_maariv');
        final makoFixture = await FixtureHelper.loadResponse('rss_mako');
        final haaretzFixture = await FixtureHelper.loadResponse('rss_haaretz');

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('ynet'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => ynetFixture);

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('maariv'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => maarivFixture);

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('mako'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => makoFixture);

        when(
          mockClient.get(
            argThat(
              predicate<Uri>((uri) => uri.toString().contains('haaretz')),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => haaretzFixture);

        final news = await newsService.fetchAllNews();

        // Should have items from all sources
        final ynetItems = news
            .where((n) => n.source == NewsSource.ynet)
            .toList();
        final maarivItems = news
            .where((n) => n.source == NewsSource.maariv)
            .toList();
        final makoItems = news
            .where((n) => n.source == NewsSource.mako)
            .toList();
        final haaretzItems = news
            .where((n) => n.source == NewsSource.haaretz)
            .toList();

        expect(ynetItems, isNotEmpty);
        expect(maarivItems, isNotEmpty);
        expect(makoItems, isNotEmpty);
        expect(haaretzItems, isNotEmpty);
      });

      test('items are sorted by pubDate descending', () async {
        final ynetFixture = await FixtureHelper.loadResponse('rss_ynet');
        final maarivFixture = await FixtureHelper.loadResponse('rss_maariv');
        final makoFixture = await FixtureHelper.loadResponse('rss_mako');
        final haaretzFixture = await FixtureHelper.loadResponse('rss_haaretz');

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('ynet'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => ynetFixture);

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('maariv'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => maarivFixture);

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('mako'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => makoFixture);

        when(
          mockClient.get(
            argThat(
              predicate<Uri>((uri) => uri.toString().contains('haaretz')),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => haaretzFixture);

        final news = await newsService.fetchAllNews();

        // Verify sorted by pubDate descending
        for (var i = 0; i < news.length - 1; i++) {
          expect(
            news[i].pubDate.isAfter(news[i + 1].pubDate) ||
                news[i].pubDate.isAtSameMomentAs(news[i + 1].pubDate),
            isTrue,
            reason: 'News should be sorted by pubDate descending',
          );
        }
      });

      test('pubDate is reasonable (not fallback DateTime.now)', () async {
        final ynetFixture = await FixtureHelper.loadResponse('rss_ynet');
        final maarivFixture = await FixtureHelper.loadResponse('rss_maariv');
        final makoFixture = await FixtureHelper.loadResponse('rss_mako');
        final haaretzFixture = await FixtureHelper.loadResponse('rss_haaretz');

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('ynet'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => ynetFixture);

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('maariv'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => maarivFixture);

        when(
          mockClient.get(
            argThat(predicate<Uri>((uri) => uri.toString().contains('mako'))),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => makoFixture);

        when(
          mockClient.get(
            argThat(
              predicate<Uri>((uri) => uri.toString().contains('haaretz')),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => haaretzFixture);

        final beforeFetch = DateTime.now();
        final news = await newsService.fetchAllNews();

        // Most items should have parsed dates from the RSS, not fallback to now
        // Allow a small tolerance for items that might fallback
        final itemsWithParsedDates = news
            .where(
              (n) => n.pubDate.isBefore(
                beforeFetch.subtract(Duration(seconds: 1)),
              ),
            )
            .length;

        // At least half the items should have real parsed dates
        expect(
          itemsWithParsedDates,
          greaterThan(news.length ~/ 2),
          reason: 'Most items should have parsed dates from RSS, not fallback',
        );
      });
    });
  });
}
