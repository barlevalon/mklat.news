/// OREF API endpoints and RSS feeds
class ApiEndpoints {
  // OREF Current Alerts
  static const String orefAlerts =
      'https://www.oref.org.il/warningMessages/alert/Alerts.json';

  // OREF Alert History (JSON)
  static const String orefHistory =
      'https://www.oref.org.il/WarningMessages/alert/History/AlertsHistory.json';

  // OREF Districts (Location list with shelter times)
  static const String orefDistricts =
      'https://alerts-history.oref.org.il/Shared/Ajax/GetDistricts.aspx?lang=he';

  // OREF Cities fallback (backup location list)
  static const String orefCitiesFallback =
      'https://www.oref.org.il/districts/cities_heb.json';

  // OREF Alert Translations (for future i18n)
  static const String orefTranslations =
      'https://www.oref.org.il/alerts/alertsTranslation.json';

  // RSS News Feeds
  static const String rssYnet =
      'https://www.ynet.co.il/Integration/StoryRss1854.xml';
  static const String rssMaariv =
      'https://www.maariv.co.il/Rss/RssFeedsMivzakiChadashot';
  static const String rssMako =
      'https://rcs.mako.co.il/rss/31750a2610f26110VgnVCM1000005201000aRCRD.xml';
  static const String rssHaaretz = 'https://www.haaretz.co.il/srv/rss---feedly';

  // Tzeva Adom Fallback
  static const String tzevaAdomFallback =
      'https://api.tzevaadom.co.il/notifications';

  // Favicon service for news icons
  static String faviconUrl(String domain) =>
      'https://www.google.com/s2/favicons?domain=$domain&sz=16';
}
