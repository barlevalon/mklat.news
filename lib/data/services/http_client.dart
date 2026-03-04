import 'package:http/http.dart' as http;
import '../../core/app_constants.dart';

class HttpClient {
  final http.Client _client;

  HttpClient({http.Client? client}) : _client = client ?? http.Client();

  /// GET request. Returns raw response body as String.
  /// Strips UTF-8 BOM if present.
  /// Throws HttpException on non-2xx status codes.
  /// Throws TimeoutException on timeout.
  ///
  /// [useOrefHeaders] - If true, adds OREF-specific headers (X-Requested-With,
  /// Referer, User-Agent). Only use for OREF API endpoints, not third-party APIs.
  Future<String> get(
    String url, {
    Map<String, String>? extraHeaders,
    bool useOrefHeaders = false,
  }) async {
    final headers = <String, String>{};
    if (useOrefHeaders) {
      headers.addAll(AppConstants.orefHeaders);
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    final response = await _client
        .get(Uri.parse(url), headers: headers)
        .timeout(Duration(seconds: AppConstants.httpTimeoutSeconds));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'HTTP ${response.statusCode} from $url',
        statusCode: response.statusCode,
      );
    }

    return _stripBom(response.body);
  }

  /// Strip UTF-8 BOM (\xEF\xBB\xBF or \uFEFF) from the start of a string.
  String _stripBom(String input) {
    if (input.startsWith('\uFEFF')) {
      return input.substring(1);
    }
    return input;
  }

  void dispose() {
    _client.close();
  }
}

class HttpException implements Exception {
  final String message;
  final int statusCode;
  HttpException(this.message, {required this.statusCode});
  @override
  String toString() => 'HttpException: $message';
}
