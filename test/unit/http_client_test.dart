import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/data/services/http_client.dart';
import 'package:mklat/core/app_constants.dart';

@GenerateMocks([http.Client])
import 'http_client_test.mocks.dart';

void main() {
  group('HttpClient', () {
    late MockClient mockClient;
    late HttpClient httpClient;

    setUp(() {
      mockClient = MockClient();
      httpClient = HttpClient(client: mockClient);
    });

    test('strips UTF-8 BOM from response body', () async {
      final bodyBytes = utf8.encode('\uFEFF{"data":"test"}');
      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response.bytes(
          bodyBytes,
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );

      final result = await httpClient.get('https://example.com');
      expect(result, '{"data":"test"}');
    });

    test('returns normal response as-is when no BOM', () async {
      when(
        mockClient.get(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response('{"data":"test"}', 200));

      final result = await httpClient.get('https://example.com');
      expect(result, '{"data":"test"}');
    });

    test('does NOT send OREF headers by default', () async {
      when(
        mockClient.get(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response('{}', 200));

      await httpClient.get('https://example.com');

      verify(
        mockClient.get(Uri.parse('https://example.com'), headers: {}),
      ).called(1);
    });

    test('sends OREF headers when useOrefHeaders is true', () async {
      when(
        mockClient.get(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response('{}', 200));

      await httpClient.get('https://example.com', useOrefHeaders: true);

      verify(
        mockClient.get(
          Uri.parse('https://example.com'),
          headers: AppConstants.orefHeaders,
        ),
      ).called(1);
    });

    test('merges extra headers without OREF headers by default', () async {
      when(
        mockClient.get(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response('{}', 200));

      await httpClient.get(
        'https://example.com',
        extraHeaders: {'Accept': 'application/json'},
      );

      verify(
        mockClient.get(
          Uri.parse('https://example.com'),
          headers: {'Accept': 'application/json'},
        ),
      ).called(1);
    });

    test(
      'merges extra headers with OREF headers when useOrefHeaders is true',
      () async {
        when(
          mockClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => http.Response('{}', 200));

        await httpClient.get(
          'https://example.com',
          useOrefHeaders: true,
          extraHeaders: {'Accept': 'application/json'},
        );

        final expectedHeaders = {
          ...AppConstants.orefHeaders,
          'Accept': 'application/json',
        };

        verify(
          mockClient.get(
            Uri.parse('https://example.com'),
            headers: expectedHeaders,
          ),
        ).called(1);
      },
    );

    test('throws HttpException on 404 status', () async {
      when(
        mockClient.get(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response('Not Found', 404));

      expect(
        () => httpClient.get('https://example.com'),
        throwsA(
          isA<HttpException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('throws HttpException on 500 status', () async {
      when(
        mockClient.get(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response('Server Error', 500));

      expect(
        () => httpClient.get('https://example.com'),
        throwsA(
          isA<HttpException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('HttpException message contains status code and URL', () async {
      when(
        mockClient.get(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => http.Response('Not Found', 404));

      try {
        await httpClient.get('https://example.com');
        fail('Should have thrown');
      } catch (e) {
        expect(e, isA<HttpException>());
        expect((e as HttpException).message, contains('HTTP 404'));
        expect(e.message, contains('https://example.com'));
      }
    });

    test('HttpException toString format', () {
      final exception = HttpException('Test message', statusCode: 404);
      expect(exception.toString(), 'HttpException: Test message');
    });
  });
}
