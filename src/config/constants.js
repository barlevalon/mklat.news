// Common configurations
const DEFAULT_USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';
const DEFAULT_TIMEOUT = 25000; // Slightly reduced timeout for testing

// Cache TTL constants (in seconds)
const CACHE_TTL = {
  SHORT: 2,        // For frequently changing data (alerts, news)
  MEDIUM: 120,     // For moderately changing data (historical alerts)
  LONG: 3600       // For rarely changing data (alert areas)
};

// Application constants
const LIMITS = {
  YNET_ITEMS: 10,
  HISTORICAL_ALERTS: 50,
  RECENT_ALERT_MINUTES: 30
};

const POLLING_INTERVAL_MS = 2000;

// API endpoints
const API_ENDPOINTS = {
  YNET_RSS: 'https://www.ynet.co.il/Integration/StoryRss1854.xml',
  MAARIV_RSS: 'https://www.maariv.co.il/Rss/RssFeedsMivzakiChadashot',
  WALLA_RSS: 'https://rss.walla.co.il/feed/22',
  HAARETZ_RSS: 'https://www.haaretz.co.il/srv/rss---feedly',
  OREF_CURRENT_ALERTS: 'https://www.oref.org.il/warningMessages/alert/Alerts.json',
  OREF_HISTORICAL_ALERTS: 'https://alerts-history.oref.org.il/Shared/Ajax/GetAlerts.aspx?lang=he',
  OREF_DISTRICTS: 'https://alerts-history.oref.org.il/Shared/Ajax/GetDistricts.aspx?lang=he',
  OREF_CITIES_BACKUP: 'https://www.oref.org.il/districts/cities_heb.json',
  TZEVA_ADOM_FALLBACK: 'https://api.tzevaadom.co.il/notifications'
};

// Fallback areas constant
const FALLBACK_ALERT_AREAS = [
  'תל אביב', 'ירושלים', 'חיפה', 'באר שבע', 'אשדוד', 'אשקלון', 'נתניה',
  'פתח תקווה', 'ראשון לציון', 'רחובות', 'חולון', 'בת ים', 'בני ברק', 
  'רמת גן', 'הרצליה', 'כפר סבא', 'רעננה', 'הוד השרון', 'נס ציונה',
  'מודיעין', 'לוד', 'רמלה', 'קרית גת', 'קרית מלאכי', 'יבנה', 'גדרה',
  'אלוני הבשן', 'מטולה', 'קרית שמונה', 'שדרות', 'עומר', 'אילת'
].sort();

module.exports = {
  DEFAULT_USER_AGENT,
  DEFAULT_TIMEOUT,
  CACHE_TTL,
  LIMITS,
  POLLING_INTERVAL_MS,
  API_ENDPOINTS,
  FALLBACK_ALERT_AREAS
};
