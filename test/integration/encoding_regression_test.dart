import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mklat/data/services/http_client.dart';

import 'encoding_regression_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('Encoding Regression Tests', () {
    late MockClient mockClient;
    late HttpClient httpClient;

    setUp(() {
      mockClient = MockClient();
      httpClient = HttpClient(client: mockClient);
    });

    tearDown(() {
      httpClient.dispose();
    });

    group('UTF-8 without charset (the original bug)', () {
      test(
        'Hebrew text is correctly decoded when Content-Type omits charset',
        () async {
          // This is the exact bug scenario: UTF-8 bytes with no charset in Content-Type
          // The http package defaults to Latin-1, which would mangle Hebrew
          final hebrewText = 'חדירת כלי טיס עוין';
          final utf8Bytes = utf8.encode(hebrewText);

          final response = http.Response.bytes(
            utf8Bytes,
            200,
            headers: {'content-type': 'application/json'}, // No charset!
          );

          when(
            mockClient.get(any, headers: anyNamed('headers')),
          ).thenAnswer((_) async => response);

          final result = await httpClient.get('https://example.com/api');

          // Verify Hebrew is intact (not mojibake)
          expect(result, hebrewText);
          expect(result.contains('×'), isFalse); // No Latin-1 artifacts
          expect(
            RegExp(r'[\u0590-\u05FF]').hasMatch(result),
            isTrue,
          ); // Has Hebrew
        },
      );

      test('RSS-style XML with Hebrew and no charset', () async {
        final xmlWithHebrew = '''<?xml version="1.0"?>
<rss>
  <channel>
    <title>מבזקים</title>
    <item>
      <title>עדכון חשוב</title>
    </item>
  </channel>
</rss>'''; // Hebrew text
        final utf8Bytes = utf8.encode(xmlWithHebrew);

        final response = http.Response.bytes(
          utf8Bytes,
          200,
          headers: {'content-type': 'application/xml'}, // No charset!
        );

        when(
          mockClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => response);

        final result = await httpClient.get('https://example.com/rss.xml');

        // Verify Hebrew is intact
        expect(result.contains('מבזקים'), isTrue);
        expect(result.contains('עדכון חשוב'), isTrue);
        expect(result.contains('×'), isFalse); // No mojibake
      });
    });

    group('BOM handling', () {
      test('UTF-8 BOM is stripped from response', () async {
        final bodyText = '{"data": "test"}';
        final bomBytes = [0xEF, 0xBB, 0xBF]; // UTF-8 BOM
        final bodyBytes = utf8.encode(bodyText);
        final fullBytes = [...bomBytes, ...bodyBytes];

        final response = http.Response.bytes(
          fullBytes,
          200,
          headers: {'content-type': 'application/json'},
        );

        when(
          mockClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => response);

        final result = await httpClient.get('https://example.com/api');

        // BOM should be stripped
        expect(result.startsWith('\uFEFF'), isFalse);
        expect(result, bodyText);
      });

      test('BOM + CRLF empty body is handled correctly', () async {
        // This is the real OREF alerts "no alerts" response
        final bomBytes = [0xEF, 0xBB, 0xBF]; // UTF-8 BOM
        final crlfBytes = [0x0D, 0x0A]; // CRLF
        final fullBytes = [...bomBytes, ...crlfBytes];

        final response = http.Response.bytes(
          fullBytes,
          200,
          headers: {'content-type': 'application/json'},
        );

        when(
          mockClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => response);

        final result = await httpClient.get('https://example.com/api');

        // Should return trimmed empty string
        expect(result.trim().isEmpty, isTrue);
      });
    });

    group('Non-standard charset declarations', () {
      test('charset=UTF8 (non-standard, missing dash) is handled', () async {
        final hebrewText = 'ירי רקטות וטילים';
        final utf8Bytes = utf8.encode(hebrewText);

        final response = http.Response.bytes(
          utf8Bytes,
          200,
          headers: {
            'content-type': 'application/json; charset=UTF8',
          }, // Non-standard!
        );

        when(
          mockClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => response);

        final result = await httpClient.get('https://example.com/api');

        // Our HttpClient always decodes as UTF-8 from bytes, so this works
        expect(result, hebrewText);
        expect(RegExp(r'[\u0590-\u05FF]').hasMatch(result), isTrue);
      });

      test('charset=utf-8 (standard) works correctly', () async {
        final hebrewText = 'התרעה צפויה';
        final utf8Bytes = utf8.encode(hebrewText);

        final response = http.Response.bytes(
          utf8Bytes,
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );

        when(
          mockClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => response);

        final result = await httpClient.get('https://example.com/api');

        expect(result, hebrewText);
        expect(RegExp(r'[\u0590-\u05FF]').hasMatch(result), isTrue);
      });
    });

    group('Mojibake detection', () {
      test('Latin-1 decoded Hebrew produces × characters (mojibake)', () {
        // Demonstrate what happens with wrong encoding
        final hebrewText = 'חדירת כלי טיס';
        final utf8Bytes = utf8.encode(hebrewText);

        // If decoded as Latin-1 (like http package does without charset)
        final latin1Decoded = latin1.decode(utf8Bytes);

        // This produces mojibake with × characters
        expect(latin1Decoded.contains('×'), isTrue);

        // The correct UTF-8 decode does not
        final utf8Decoded = utf8.decode(utf8Bytes);
        expect(utf8Decoded.contains('×'), isFalse);
        expect(utf8Decoded, hebrewText);
      });

      test('Hebrew Unicode range detection works', () {
        final hebrewText = 'ירי רקטות';
        final hasHebrew = RegExp(r'[\u0590-\u05FF]').hasMatch(hebrewText);
        expect(hasHebrew, isTrue);

        final englishText = 'Rocket fire';
        final hasNoHebrew = !RegExp(r'[\u0590-\u05FF]').hasMatch(englishText);
        expect(hasNoHebrew, isTrue);
      });
    });
  });
}
