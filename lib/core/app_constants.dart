/// App-wide constants
class AppConstants {
  // Polling Intervals
  static const int alertsPollingIntervalMs = 2000; // 2 seconds
  static const int newsPollingIntervalMs = 30000; // 30 seconds

  // HTTP Timeouts
  static const int httpTimeoutSeconds = 10;

  // UI Timing
  static const int justClearedDurationMinutes = 10;
  static const int timerUpdateIntervalMs = 1000; // 1 second for countdowns

  // Pagination
  static const int alertsPageSize = 20;

  // Storage Keys
  static const String savedLocationsKey = 'mklat_saved_locations';
  static const String districtsCacheKey = 'mklat_districts_cache';
  static const String districtsCacheTimestampKey = 'mklat_districts_cache_time';
  static const int districtsCacheDurationHours = 24;

  // Deep Linking
  static const String deepLinkScheme = 'mklat';
  static const String deepLinkLocationPath = 'location';

  // OREF Headers
  static const Map<String, String> orefHeaders = {
    'X-Requested-With': 'XMLHttpRequest',
    'Referer': 'https://www.oref.org.il/',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
  };

  // RSS Feed Sources
  static const Map<String, String> rssSourceNames = {
    'ynet.co.il': 'Ynet',
    'maariv.co.il': 'Maariv',
    'walla.co.il': 'Walla',
    'haaretz.co.il': 'Haaretz',
  };
}
