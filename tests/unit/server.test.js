const request = require('supertest');
const express = require('express');
const cors = require('cors');

// Mock the dependencies
jest.mock('axios');
jest.mock('xml2js');
jest.mock('node-cache');

const axios = require('axios');
const xml2js = require('xml2js');
const NodeCache = require('node-cache');

describe('Server API Endpoints', () => {
  let app;
  let mockCache;

  beforeEach(() => {
    // Reset all mocks
    jest.clearAllMocks();
    
    // Mock NodeCache
    mockCache = {
      get: jest.fn(),
      set: jest.fn()
    };
    NodeCache.mockImplementation(() => mockCache);

    // Create test app with same routes as server
    app = express();
    app.use(cors());
    app.use(express.static('public'));

    // Health check
    app.get('/api/health', (req, res) => {
      res.json({ status: 'ok', timestamp: new Date().toISOString() });
    });

    // Alert areas endpoint
    app.get('/api/alert-areas', (req, res) => {
      const alertAreas = [...new Set([
        'רחובות', 'תל אביב', 'ירושלים', 'חיפה', 'באר שבע', 'אשדוד', 'אשקלון', 'נתניה',
        'פתח תקווה', 'ראשון לציון', 'חולון', 'בת ים', 'בני ברק', 'רמת גן', 'הרצליה'
      ])].sort();
      res.json(alertAreas);
    });

    // Add the other endpoints with mocked functionality
    setupMockedEndpoints();
  });

  function setupMockedEndpoints() {
    // Ynet endpoint
    app.get('/api/ynet', async (req, res) => {
      try {
        const cached = mockCache.get('ynet');
        if (cached) {
          return res.json(cached);
        }

        const response = await axios.get('https://www.ynet.co.il/Integration/StoryRss1854.xml');
        const parser = new xml2js.Parser();
        const result = await parser.parseStringPromise(response.data);
        
        const items = result.rss.channel[0].item || [];
        const news = items.slice(0, 10).map(item => ({
          title: item.title[0],
          link: item.link[0],
          pubDate: item.pubDate[0],
          description: item.description ? item.description[0].replace(/<[^>]*>/g, '') : ''
        }));

        mockCache.set('ynet', news);
        res.json(news);
      } catch (error) {
        res.status(500).json({ error: 'Failed to fetch Ynet news' });
      }
    });

    // Alerts endpoint
    app.get('/api/alerts', async (req, res) => {
      try {
        const cached = mockCache.get('alerts');
        if (cached) {
          return res.json(cached);
        }

        const response = await axios.get('https://www.oref.org.il/WarningMessages/alert/alerts.json', {
          timeout: 10000,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          }
        });
        const alerts = response.data || [];
        mockCache.set('alerts', alerts);
        res.json(alerts);
      } catch (error) {
        try {
          const fallbackResponse = await axios.get('https://api.tzevaadom.co.il/notifications', {
            timeout: 10000
          });
          const alerts = fallbackResponse.data || [];
          mockCache.set('alerts', alerts);
          res.json(alerts);
        } catch (fallbackError) {
          res.status(500).json({ error: 'Failed to fetch alerts' });
        }
      }
    });
  }

  describe('GET /api/health', () => {
    test('should return health status', async () => {
      const response = await request(app)
        .get('/api/health')
        .expect(200);
      
      expect(response.body).toHaveProperty('status', 'ok');
      expect(response.body).toHaveProperty('timestamp');
    });
  });

  describe('GET /api/alert-areas', () => {
    test('should return list of alert areas', async () => {
      const response = await request(app)
        .get('/api/alert-areas')
        .expect(200);
      
      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBeGreaterThan(10);
      expect(response.body).toContain('רחובות');
      expect(response.body).toContain('תל אביב');
      
      // Should not have duplicates
      const uniqueAreas = [...new Set(response.body)];
      expect(uniqueAreas.length).toBe(response.body.length);
    });

    test('should return sorted list', async () => {
      const response = await request(app)
        .get('/api/alert-areas')
        .expect(200);
      
      const sortedAreas = [...response.body].sort();
      expect(response.body).toEqual(sortedAreas);
    });
  });

  describe('GET /api/ynet', () => {
    test('should return cached news if available', async () => {
      const cachedNews = [
        {
          title: 'Test News',
          link: 'https://example.com',
          pubDate: new Date().toISOString(),
          description: 'Test description'
        }
      ];
      
      mockCache.get.mockReturnValue(cachedNews);
      
      const response = await request(app)
        .get('/api/ynet')
        .expect(200);
      
      expect(response.body).toEqual(cachedNews);
      expect(mockCache.get).toHaveBeenCalledWith('ynet');
      expect(axios.get).not.toHaveBeenCalled();
    });

    test('should fetch and parse RSS when not cached', async () => {
      mockCache.get.mockReturnValue(null);
      
      const mockRssData = `
        <rss>
          <channel>
            <item>
              <title>Test News Item</title>
              <link>https://example.com/news1</link>
              <pubDate>Mon, 16 Jun 2025 10:00:00 +0300</pubDate>
              <description>Test description</description>
            </item>
          </channel>
        </rss>
      `;
      
      axios.get.mockResolvedValue({ data: mockRssData });
      
      const mockParser = {
        parseStringPromise: jest.fn().mockResolvedValue({
          rss: {
            channel: [{
              item: [{
                title: ['Test News Item'],
                link: ['https://example.com/news1'],
                pubDate: ['Mon, 16 Jun 2025 10:00:00 +0300'],
                description: ['Test description']
              }]
            }]
          }
        })
      };
      
      xml2js.Parser.mockImplementation(() => mockParser);
      
      const response = await request(app)
        .get('/api/ynet')
        .expect(200);
      
      expect(response.body).toHaveLength(1);
      expect(response.body[0]).toMatchObject({
        title: 'Test News Item',
        link: 'https://example.com/news1',
        pubDate: 'Mon, 16 Jun 2025 10:00:00 +0300',
        description: 'Test description'
      });
      
      expect(mockCache.set).toHaveBeenCalledWith('ynet', expect.any(Array));
    });

    test('should handle RSS fetch errors', async () => {
      mockCache.get.mockReturnValue(null);
      axios.get.mockRejectedValue(new Error('Network error'));
      
      const response = await request(app)
        .get('/api/ynet')
        .expect(500);
      
      expect(response.body).toHaveProperty('error', 'Failed to fetch Ynet news');
    });
  });

  describe('GET /api/alerts', () => {
    test('should return cached alerts if available', async () => {
      const cachedAlerts = ['רחובות', 'תל אביב'];
      mockCache.get.mockReturnValue(cachedAlerts);
      
      const response = await request(app)
        .get('/api/alerts')
        .expect(200);
      
      expect(response.body).toEqual(cachedAlerts);
      expect(mockCache.get).toHaveBeenCalledWith('alerts');
    });

    test('should fetch alerts from primary API when not cached', async () => {
      mockCache.get.mockReturnValue(null);
      const mockAlerts = ['חיפה', 'באר שבע'];
      axios.get.mockResolvedValue({ data: mockAlerts });
      
      const response = await request(app)
        .get('/api/alerts')
        .expect(200);
      
      expect(response.body).toEqual(mockAlerts);
      expect(axios.get).toHaveBeenCalledWith(
        'https://www.oref.org.il/WarningMessages/alert/alerts.json',
        expect.any(Object)
      );
      expect(mockCache.set).toHaveBeenCalledWith('alerts', mockAlerts);
    });

    test('should fallback to secondary API on primary failure', async () => {
      mockCache.get.mockReturnValue(null);
      const mockAlerts = ['נתניה'];
      
      // Primary API fails
      axios.get
        .mockRejectedValueOnce(new Error('Primary API error'))
        .mockResolvedValueOnce({ data: mockAlerts });
      
      const response = await request(app)
        .get('/api/alerts')
        .expect(200);
      
      expect(response.body).toEqual(mockAlerts);
      expect(axios.get).toHaveBeenCalledTimes(2);
      expect(axios.get).toHaveBeenNthCalledWith(2, 
        'https://api.tzevaadom.co.il/notifications',
        expect.any(Object)
      );
    });

    test('should return error when both APIs fail', async () => {
      mockCache.get.mockReturnValue(null);
      axios.get
        .mockRejectedValueOnce(new Error('Primary API error'))
        .mockRejectedValueOnce(new Error('Fallback API error'));
      
      const response = await request(app)
        .get('/api/alerts')
        .expect(500);
      
      expect(response.body).toHaveProperty('error', 'Failed to fetch alerts');
    });
  });
});
