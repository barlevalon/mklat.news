import 'dart:convert';
import '../../core/api_endpoints.dart';
import '../models/alert.dart';
import 'http_client.dart';

class OrefAlertsService {
  final HttpClient _httpClient;

  OrefAlertsService(this._httpClient);

  /// Fetch current active alerts.
  /// Returns a list of Alert objects (one per location in the alert).
  /// Returns empty list if no active alerts or on error.
  Future<List<Alert>> fetchCurrentAlerts() async {
    try {
      final body = await _httpClient.get(
        ApiEndpoints.orefAlerts,
        useOrefHeaders: true,
      );
      return _parseAlertsResponse(body);
    } on HttpException {
      rethrow; // Network/HTTP errors propagate to polling manager
    } catch (e) {
      return []; // Parse errors return empty
    }
  }

  /// Parse the Alerts.json response body.
  /// The response is either:
  /// - Empty/whitespace (after BOM strip) = no alerts → return []
  /// - JSON object with {id, cat, title, desc, data: [...]} → return Alert per location
  List<Alert> _parseAlertsResponse(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return [];

    try {
      final json = jsonDecode(trimmed);
      if (json is! Map<String, dynamic>) return [];

      final data = json['data'];
      if (data is! List || data.isEmpty) return [];

      return data
          .whereType<String>()
          .map((location) => Alert.fromOrefActive(json, location))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
