import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_endpoints.dart';
import '../../core/app_constants.dart';
import '../models/oref_location.dart';
import 'http_client.dart';

class OrefDistrictsService {
  final HttpClient _httpClient;

  OrefDistrictsService(this._httpClient);

  /// Fetch districts with fallback chain.
  /// 1. Try Districts API (has migun_time)
  /// 2. Fallback to cities_heb.json (no migun_time)
  /// 3. Return empty list as last resort (hardcoded fallback deferred)
  Future<List<OrefLocation>> fetchDistricts() async {
    // Try cache first
    final cached = await _loadFromCache();
    if (cached != null && cached.isNotEmpty) return cached;

    // Try primary: GetDistricts.aspx
    try {
      final body = await _httpClient.get(
        ApiEndpoints.orefDistricts,
        useOrefHeaders: true,
      );
      final locations = _parseDistrictsResponse(body);
      if (locations.isNotEmpty) {
        await _saveToCache(locations);
        return locations;
      }
    } catch (e) {
      // Fall through to fallback
    }

    // Fallback: cities_heb.json
    try {
      final body = await _httpClient.get(
        ApiEndpoints.orefCitiesFallback,
        useOrefHeaders: true,
      );
      final locations = _parseCitiesFallbackResponse(body);
      if (locations.isNotEmpty) {
        await _saveToCache(locations);
        return locations;
      }
    } catch (e) {
      // Fall through
    }

    // Ultimate fallback: empty list (hardcoded list is deferred)
    return [];
  }

  List<OrefLocation> _parseDistrictsResponse(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return [];
    try {
      final json = jsonDecode(trimmed);
      if (json is! List) return [];
      return json
          .whereType<Map<String, dynamic>>()
          .map((entry) => OrefLocation.fromDistricts(entry))
          .toList();
    } catch (e) {
      return [];
    }
  }

  List<OrefLocation> _parseCitiesFallbackResponse(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return [];
    try {
      final json = jsonDecode(trimmed);
      if (json is! List) return [];
      return json
          .whereType<Map<String, dynamic>>()
          .map((entry) => OrefLocation.fromCitiesFallback(entry))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Load cached districts from SharedPreferences.
  Future<List<OrefLocation>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(
        AppConstants.districtsCacheTimestampKey,
      );
      if (timestampStr == null) return null;

      final timestamp = DateTime.parse(timestampStr);
      final age = DateTime.now().difference(timestamp);
      if (age.inHours >= AppConstants.districtsCacheDurationHours) return null;

      final jsonStr = prefs.getString(AppConstants.districtsCacheKey);
      if (jsonStr == null) return null;

      final list = jsonDecode(jsonStr) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map((e) => OrefLocation.fromJson(e))
          .toList();
    } catch (e) {
      return null;
    }
  }

  /// Save districts to SharedPreferences cache.
  Future<void> _saveToCache(List<OrefLocation> locations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(locations.map((l) => l.toJson()).toList());
      await prefs.setString(AppConstants.districtsCacheKey, jsonStr);
      await prefs.setString(
        AppConstants.districtsCacheTimestampKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      // Cache failure is non-fatal
    }
  }
}
