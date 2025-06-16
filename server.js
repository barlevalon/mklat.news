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
    const cached = cache.get('ynet');
    if (cached) {
      return res.json(cached);
    }

    const response = await axios.get('https://www.ynet.co.il/Integration/StoryRss1854.xml', {
      timeout: 10000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    });

    const parser = new xml2js.Parser();
    const result = await parser.parseStringPromise(response.data);
    
    const items = result.rss.channel[0].item || [];
    const news = items.slice(0, 10).map(item => ({
      title: item.title[0],
      link: item.link[0],
      pubDate: item.pubDate[0],
      description: item.description ? item.description[0].replace(/<[^>]*>/g, '') : ''
    }));

    cache.set('ynet', news);
    res.json(news);
  } catch (error) {
    console.error('Ynet fetch error:', error.message);
    res.status(500).json({ error: 'Failed to fetch Ynet news' });
  }
});

// Homefront Command alerts endpoint
app.get('/api/alerts', async (req, res) => {
  try {
    const cached = cache.get('alerts');
    if (cached) {
      return res.json(cached);
    }

    const response = await axios.get('https://www.oref.org.il/warningMessages/alert/Alerts.json', {
      timeout: 10000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    });

    const alerts = response.data || [];
    cache.set('alerts', alerts);
    res.json(alerts);
  } catch (error) {
    console.error('Alerts fetch error:', error.message);
    // Try fallback API
    try {
      const fallbackResponse = await axios.get('https://api.tzevaadom.co.il/notifications', {
        timeout: 10000
      });
      const alerts = fallbackResponse.data || [];
      cache.set('alerts', alerts);
      res.json(alerts);
    } catch (fallbackError) {
      console.error('Fallback alerts fetch error:', fallbackError.message);
      res.status(500).json({ error: 'Failed to fetch alerts' });
    }
  }
});

// Get all possible alert areas/locations
app.get('/api/alert-areas', async (req, res) => {
  try {
    const cached = cache.get('alert-areas');
    if (cached) {
      return res.json(cached);
    }

    // Fetch official cities list directly from oref.org.il
    const response = await axios.get('https://alerts-history.oref.org.il/Shared/Ajax/GetDistricts.aspx?lang=he', {
      timeout: 10000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.100 Safari/537.36'
      }
    });

    const districts = response.data || [];
    
    // Extract city names from the official API response
    const alertAreas = [...new Set(
      districts
        .filter(district => district && district.label && district.label.trim())
        .map(district => district.label.trim())
    )].sort();

    console.log(`Fetched ${alertAreas.length} areas from official oref.org.il API`);

    // Cache for 1 hour (cities don't change often)
    cache.set('alert-areas', alertAreas, 3600);
    
    res.json(alertAreas);
  } catch (error) {
    console.error('Error fetching official cities list from oref.org.il:', error.message);
    
    // Try backup API from oref.org.il
    try {
      const backupResponse = await axios.get('https://www.oref.org.il/districts/cities_heb.json', {
        timeout: 10000,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.100 Safari/537.36'
        }
      });

      const backupData = backupResponse.data || [];
      const backupAreas = [...new Set(
        backupData
          .filter(item => item && item.label && item.label.trim())
          .map(item => item.label.trim())
      )].sort();

      if (backupAreas.length > 0) {
        console.log(`Fetched ${backupAreas.length} areas from backup oref.org.il API`);
        cache.set('alert-areas', backupAreas, 3600);
        return res.json(backupAreas);
      }
    } catch (backupError) {
      console.error('Backup API also failed:', backupError.message);
    }
    
    // Last resort fallback to essential cities
    const fallbackAreas = [
      'תל אביב', 'ירושלים', 'חיפה', 'באר שבע', 'אשדוד', 'אשקלון', 'נתניה',
      'פתח תקווה', 'ראשון לציון', 'רחובות', 'חולון', 'בת ים', 'בני ברק', 
      'רמת גן', 'הרצליה', 'כפר סבא', 'רעננה', 'הוד השרון', 'נס ציונה',
      'מודיעין', 'לוד', 'רמלה', 'קרית גת', 'קרית מלאכי', 'יבנה', 'גדרה',
      'אלוני הבשן', 'מטולה', 'קרית שמונה', 'שדרות', 'עומר', 'אילת'
    ].sort();
    
    console.log('Using fallback areas list');
    res.json(fallbackAreas);
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
async function fetchYnetData() {
  const cached = cache.get('ynet');
  if (cached) return cached;
  
  const response = await axios.get('https://www.ynet.co.il/Integration/StoryRss1854.xml', {
    timeout: 10000,
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }
  });

  const parser = new xml2js.Parser();
  const result = await parser.parseStringPromise(response.data);
  
  const items = result.rss.channel[0].item || [];
  const news = items.slice(0, 10).map(item => ({
    title: item.title[0],
    link: item.link[0],
    pubDate: item.pubDate[0],
    description: item.description ? item.description[0].replace(/<[^>]*>/g, '') : ''
  }));

  cache.set('ynet', news);
  return news;
}

async function fetchAlertsData() {
  const cached = cache.get('alerts');
  if (cached) return cached;
  
  try {
    const response = await axios.get('https://www.oref.org.il//warningMessages/alert/Alerts.json', {
      timeout: 5000,
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'Referer': 'https://www.oref.org.il/'
      }
    });
    
    const alerts = response.data || [];
    cache.set('alerts', alerts);
    return alerts;
  } catch (error) {
    // Fallback API
    const fallbackResponse = await axios.get('https://api.tzevaadom.co.il/notifications', {
      timeout: 5000
    });
    const alerts = fallbackResponse.data || [];
    cache.set('alerts', alerts);
    return alerts;
  }
}

async function fetchAlertAreas() {
  const cached = cache.get('alert-areas');
  if (cached) return cached;
  
  try {
    const response = await axios.get('https://alerts-history.oref.org.il//Shared/Ajax/GetDistricts.aspx?lang=he', {
      timeout: 10000
    });
    
    const data = response.data || [];
    const alertAreas = [...new Set(
      data
        .filter(district => district && district.label && district.label.trim())
        .map(district => district.label.trim())
    )].sort();
    
    cache.set('alert-areas', alertAreas, 3600);
    return alertAreas;
  } catch (error) {
    console.error('Error in fetchAlertAreas:', error.message);
    
    // Fallback to essential cities
    const fallbackAreas = [
      'תל אביב', 'ירושלים', 'חיפה', 'באר שבע', 'אשדוד', 'אשקלון', 'נתניה',
      'פתח תקווה', 'ראשון לציון', 'רחובות', 'חולון', 'בת ים', 'בני ברק', 
      'רמת גן', 'הרצליה', 'כפר סבא', 'רעננה', 'הוד השרון', 'נס ציונה',
      'מודיעין', 'לוד', 'רמלה', 'קרית גת', 'קרית מלאכי', 'יבנה', 'גדרה',
      'אלוני הבשן', 'מטולה', 'קרית שמונה', 'שדרות', 'עומר', 'אילת'
    ].sort();
    
    cache.set('alert-areas', fallbackAreas, 3600);
    return fallbackAreas;
  }
}

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
    if (JSON.stringify(ynetData) !== JSON.stringify(lastYnetData)) {
      lastYnetData = ynetData;
      broadcastToClients('ynet', ynetData);
    }
    
    if (JSON.stringify(alertsData) !== JSON.stringify(lastAlertsData)) {
      lastAlertsData = alertsData;
      broadcastToClients('alerts', alertsData);
    }
  } catch (error) {
    console.error('Background polling error:', error);
  }
}

// Start background polling every 2 seconds
setInterval(backgroundPoll, 2000);

server.listen(port, () => {
  console.log(`War Room server running at http://localhost:${port}`);
  console.log(`WebSocket server running at ws://localhost:${port}`);
  console.log('Background polling started (2-second intervals)');
});
