const express = require('express');
const cors = require('cors');
const axios = require('axios');
const xml2js = require('xml2js');
const NodeCache = require('node-cache');
const path = require('path');
const WebSocket = require('ws');
const http = require('http');

const app = express();
const port = process.env.PORT || 3000;

// Cache for 2 seconds (aggressive polling like tzevaadom)
const cache = new NodeCache({ stdTTL: 2 });

// Common configurations
const DEFAULT_USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';
const DEFAULT_TIMEOUT = 10000;

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
  OREF_CURRENT_ALERTS: 'https://www.oref.org.il/warningMessages/alert/Alerts.json',
  OREF_HISTORICAL_ALERTS: 'https://alerts-history.oref.org.il/Shared/Ajax/GetAlerts.aspx?lang=he',
  OREF_DISTRICTS: 'https://alerts-history.oref.org.il/Shared/Ajax/GetDistricts.aspx?lang=he',
  OREF_CITIES_BACKUP: 'https://www.oref.org.il/districts/cities_heb.json',
  TZEVA_ADOM_FALLBACK: 'https://api.tzevaadom.co.il/notifications'
};

// Common axios config generator
function createAxiosConfig(timeout = DEFAULT_TIMEOUT, headers = {}) {
  return {
    timeout,
    headers: {
      'User-Agent': DEFAULT_USER_AGENT,
      ...headers
    }
  };
}

// Generic cache wrapper
function withCache(key, ttl, fetchFn) {
  return async function(...args) {
    const cached = cache.get(key);
    if (cached) return cached;
    
    const result = await fetchFn(...args);
    cache.set(key, result, ttl);
    return result;
  };
}

// Common data processing utilities
function processAlertAreasData(data) {
  return [...new Set(
    data
      .filter(item => item && item.label && item.label.trim())
      .map(item => item.label.trim())
  )].sort();
}

function processYnetItems(items) {
  return items.slice(0, LIMITS.YNET_ITEMS).map(item => ({
    title: item.title[0],
    link: item.link[0],
    pubDate: item.pubDate[0],
    description: item.description ? item.description[0].replace(/<[^>]*>/g, '') : ''
  }));
}

// Utility for efficient data comparison
function hasDataChanged(newData, oldData) {
  return JSON.stringify(newData) !== JSON.stringify(oldData);
}

app.use(cors());
app.use(express.static('public'));

// Create HTTP server and WebSocket server
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Store WebSocket clients
const clients = new Set();

// WebSocket connection handler
wss.on('connection', (ws) => {
  clients.add(ws);
  console.log('WebSocket client connected. Total clients:', clients.size);
  
  // Send initial data
  sendInitialData(ws);
  
  ws.on('close', () => {
    clients.delete(ws);
    console.log('WebSocket client disconnected. Total clients:', clients.size);
  });
  
  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
    clients.delete(ws);
  });
});

// Serve main page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Ynet breaking news endpoint
app.get('/api/ynet', async (req, res) => {
  try {
    const news = await fetchYnetData();
    res.json(news);
  } catch (error) {
    console.error('Ynet fetch error:', error.message);
    res.status(500).json({ error: 'Failed to fetch Ynet news' });
  }
});

// Homefront Command alerts endpoint
app.get('/api/alerts', async (req, res) => {
  try {
    const alertsData = await fetchAlertsData();
    res.json(alertsData);
  } catch (error) {
    console.error('Alerts fetch error:', error.message);
    res.status(500).json({ error: 'Failed to fetch alerts' });
  }
});

// Get all possible alert areas/locations
app.get('/api/alert-areas', async (req, res) => {
  try {
    const alertAreas = await fetchAlertAreas();
    res.json(alertAreas);
  } catch (error) {
    console.error('Error fetching alert areas:', error.message);
    res.status(500).json({ error: 'Failed to fetch alert areas' });
  }
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Send initial data to new WebSocket clients
async function sendInitialData(ws) {
  try {
    const [ynetData, alertsData, locationsData] = await Promise.all([
      fetchYnetData(),
      fetchAlertsData(),
      fetchAlertAreas()
    ]);
    
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({
        type: 'initial',
        data: {
          ynet: ynetData,
          alerts: alertsData,
          locations: locationsData
        }
      }));
    }
  } catch (error) {
    console.error('Error sending initial data:', error);
  }
}

// Broadcast data to all connected WebSocket clients
function broadcastToClients(type, data) {
  const message = JSON.stringify({ type, data });
  const deadClients = new Set();
  
  clients.forEach(ws => {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(message);
    } else {
      deadClients.add(ws);
    }
  });
  
  // Clean up dead connections
  deadClients.forEach(ws => clients.delete(ws));
}

// Extract data fetching logic into reusable functions
const fetchYnetData = withCache('ynet', CACHE_TTL.SHORT, async () => {
  const response = await axios.get(API_ENDPOINTS.YNET_RSS, createAxiosConfig());

  const parser = new xml2js.Parser();
  const result = await parser.parseStringPromise(response.data);
  
  const items = result.rss.channel[0].item || [];
  return processYnetItems(items);
});

async function fetchAlertsData() {
  // Get both active alerts and historical alerts
  const [activeAlerts, historicalAlerts] = await Promise.all([
    fetchActiveAlerts(),
    fetchHistoricalAlerts()
  ]);
  
  return {
    active: activeAlerts,
    history: historicalAlerts
  };
}

const fetchActiveAlerts = withCache('active-alerts', CACHE_TTL.SHORT, async () => {
  try {
    const response = await axios.get(API_ENDPOINTS.OREF_CURRENT_ALERTS, 
      createAxiosConfig(5000, {
        'X-Requested-With': 'XMLHttpRequest',
        'Referer': 'https://www.oref.org.il/'
      }));
    
    return normalizeAlertsResponse(response.data);
  } catch (error) {
    // Fallback API
    const fallbackResponse = await axios.get(API_ENDPOINTS.TZEVA_ADOM_FALLBACK, 
      createAxiosConfig(5000));
    return fallbackResponse.data || [];
  }
});

// Helper function to normalize OREF API response
function normalizeAlertsResponse(data) {
  let alerts = data || [];
  console.log('OREF Active Alerts response:', JSON.stringify(alerts).substring(0, 200));
  
  // Handle different response formats from OREF API
  if (typeof alerts === 'string') {
    alerts = alerts.trim();
    if (alerts === '' || alerts === '\r\n' || alerts === '\n') {
      alerts = []; // No alerts
    } else {
      try {
        alerts = JSON.parse(alerts);
      } catch (e) {
        console.log('Failed to parse alerts string, treating as empty:', alerts);
        alerts = [];
      }
    }
  }
  
  if (!Array.isArray(alerts)) {
    alerts = [];
  }
  
  return alerts;
}

const fetchHistoricalAlerts = withCache('historical-alerts', CACHE_TTL.MEDIUM, async () => {
  try {
    const response = await axios.get(API_ENDPOINTS.OREF_HISTORICAL_ALERTS, createAxiosConfig());
    
    const html = response.data;
    return parseHistoricalAlertsHTML(html);
  } catch (error) {
    console.error('Error fetching historical alerts:', error.message);
    return [];
  }
});

// Historical alerts parsing utilities
const ALERT_REGEX = /<div[^>]*class="alertInfo"[^>]*area_name="([^"]*)"[^>]*>[\s\S]*?<div class="date"><span>([^<]*)<\/span><span>([^<]*)<\/span><\/div>[\s\S]*?<div class="area">([^<]*)<\/div>/g;
const ALERT_END_MARKER = 'האירוע הסתיים';

function parseAlertDateTime(dateStr, timeStr) {
  const [day, month, year] = dateStr.split('.');
  return new Date(`${year}-${month}-${day}T${timeStr}:00`);
}

function cleanAlertDescription(description, locationName) {
  let cleanDescription = description.trim();
  
  // Remove location name from end of description if it's duplicated
  if (cleanDescription.endsWith(locationName)) {
    cleanDescription = cleanDescription.slice(0, -locationName.length).trim();
  }
  
  return cleanDescription;
}

function isRecentAlert(alertDateTime) {
  const thresholdMs = LIMITS.RECENT_ALERT_MINUTES * 60 * 1000;
  return (new Date() - alertDateTime) < thresholdMs;
}

function createAlertObject(areaName, date, time, description) {
  const locationName = areaName.trim();
  const alertDateTime = parseAlertDateTime(date, time);
  const cleanDescription = cleanAlertDescription(description, locationName);
  
  return {
    area: locationName,
    description: cleanDescription,
    alertDate: alertDateTime.toISOString(),
    time: alertDateTime.toISOString(),
    isActive: !description.includes(ALERT_END_MARKER),
    isRecent: isRecentAlert(alertDateTime)
  };
}

function parseHistoricalAlertsHTML(html) {
  const alerts = [];
  
  let match;
  while ((match = ALERT_REGEX.exec(html)) !== null) {
    const [, areaName, date, time, description] = match;
    alerts.push(createAlertObject(areaName, date, time, description));
  }
  
  // Sort by date (most recent first)
  alerts.sort((a, b) => new Date(b.alertDate) - new Date(a.alertDate));
  
  return alerts.slice(0, LIMITS.HISTORICAL_ALERTS);
}

// Fallback areas constant
const FALLBACK_ALERT_AREAS = [
  'תל אביב', 'ירושלים', 'חיפה', 'באר שבע', 'אשדוד', 'אשקלון', 'נתניה',
  'פתח תקווה', 'ראשון לציון', 'רחובות', 'חולון', 'בת ים', 'בני ברק', 
  'רמת גן', 'הרצליה', 'כפר סבא', 'רעננה', 'הוד השרון', 'נס ציונה',
  'מודיעין', 'לוד', 'רמלה', 'קרית גת', 'קרית מלאכי', 'יבנה', 'גדרה',
  'אלוני הבשן', 'מטולה', 'קרית שמונה', 'שדרות', 'עומר', 'אילת'
].sort();

const fetchAlertAreas = withCache('alert-areas', CACHE_TTL.LONG, async () => {
  try {
    const response = await axios.get(API_ENDPOINTS.OREF_DISTRICTS, createAxiosConfig());
    
    const data = response.data || [];
    const alertAreas = processAlertAreasData(data);
    
    console.log(`Fetched ${alertAreas.length} areas from official oref.org.il API`);
    return alertAreas;
  } catch (error) {
    console.error('Error in fetchAlertAreas:', error.message);
    
    // Try backup API from oref.org.il
    try {
      const backupResponse = await axios.get(API_ENDPOINTS.OREF_CITIES_BACKUP, createAxiosConfig());

      const backupData = backupResponse.data || [];
      const backupAreas = processAlertAreasData(backupData);

      if (backupAreas.length > 0) {
        console.log(`Fetched ${backupAreas.length} areas from backup oref.org.il API`);
        return backupAreas;
      }
    } catch (backupError) {
      console.error('Backup API also failed:', backupError.message);
    }
    
    console.log('Using fallback areas list');
    return FALLBACK_ALERT_AREAS;
  }
});

// Background polling system
let lastYnetData = null;
let lastAlertsData = null;

async function backgroundPoll() {
  try {
    // Fetch new data
    const [ynetData, alertsData] = await Promise.all([
      fetchYnetData(),
      fetchAlertsData()
    ]);
    
    // Check for changes and broadcast
    if (hasDataChanged(ynetData, lastYnetData)) {
      lastYnetData = ynetData;
      broadcastToClients('ynet', ynetData);
    }
    
    if (hasDataChanged(alertsData, lastAlertsData)) {
      lastAlertsData = alertsData;
      broadcastToClients('alerts', alertsData);
    }
  } catch (error) {
    console.error('Background polling error:', error);
  }
}

// Start background polling
setInterval(backgroundPoll, POLLING_INTERVAL_MS);

server.listen(port, () => {
  console.log(`War Room server running at http://localhost:${port}`);
  console.log(`WebSocket server running at ws://localhost:${port}`);
  console.log(`Background polling started (${POLLING_INTERVAL_MS}ms intervals)`);
});
