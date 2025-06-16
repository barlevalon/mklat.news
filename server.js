const express = require('express');
const cors = require('cors');
const axios = require('axios');
const xml2js = require('xml2js');
const NodeCache = require('node-cache');
const path = require('path');

const app = express();
const port = process.env.PORT || 3000;

// Cache for 5 seconds (OREF updates every 4s, Ynet every 2.5min)
const cache = new NodeCache({ stdTTL: 5 });

app.use(cors());
app.use(express.static('public'));

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

app.listen(port, () => {
  console.log(`War Room server running on port ${port}`);
});
