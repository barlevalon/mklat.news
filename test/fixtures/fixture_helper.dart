import 'dart:io';
import 'package:http/http.dart' as http;

/// Utility class for loading HTTP response fixtures from captured real responses.
///
/// Fixtures are stored in `test/fixtures/responses/` with two files per fixture:
/// - `{name}_body.bin` - Raw response body bytes
/// - `{name}_headers.txt` - HTTP response headers (key: value format)
class FixtureHelper {
  /// Load a fixture response with real bytes and headers.
  ///
  /// [name] is the base name, e.g., 'oref_alerts' loads:
  /// - oref_alerts_body.bin
  /// - oref_alerts_headers.txt
  ///
  /// Returns an [http.Response.bytes] with the actual bytes and headers,
  /// preserving encoding behavior for integration testing.
  static Future<http.Response> loadResponse(
    String name, {
    int statusCode = 200,
  }) async {
    final fixtureDir = '${Directory.current.path}/test/fixtures/responses';
    final bodyBytes = await File('$fixtureDir/${name}_body.bin').readAsBytes();
    final headersFile = File('$fixtureDir/${name}_headers.txt');
    final headers = <String, String>{};

    if (await headersFile.exists()) {
      final lines = await headersFile.readAsLines();
      for (final line in lines) {
        final colonIndex = line.indexOf(':');
        if (colonIndex > 0) {
          final key = line.substring(0, colonIndex).trim().toLowerCase();
          final value = line.substring(colonIndex + 1).trim();
          headers[key] = value;
        }
      }
    }

    return http.Response.bytes(bodyBytes, statusCode, headers: headers);
  }

  /// Load only the body bytes of a fixture.
  static Future<List<int>> loadBodyBytes(String name) async {
    final fixtureDir = '${Directory.current.path}/test/fixtures/responses';
    return await File('$fixtureDir/${name}_body.bin').readAsBytes();
  }

  /// Load only the headers of a fixture.
  static Future<Map<String, String>> loadHeaders(String name) async {
    final fixtureDir = '${Directory.current.path}/test/fixtures/responses';
    final headersFile = File('$fixtureDir/${name}_headers.txt');
    final headers = <String, String>{};

    if (await headersFile.exists()) {
      final lines = await headersFile.readAsLines();
      for (final line in lines) {
        final colonIndex = line.indexOf(':');
        if (colonIndex > 0) {
          final key = line.substring(0, colonIndex).trim().toLowerCase();
          final value = line.substring(colonIndex + 1).trim();
          headers[key] = value;
        }
      }
    }

    return headers;
  }
}
