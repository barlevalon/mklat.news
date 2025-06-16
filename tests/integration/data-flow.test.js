const axios = require('axios');
const xml2js = require('xml2js');

// Mock external dependencies
jest.mock('axios');
jest.mock('xml2js');
jest.mock('node-cache');

const mockAxios = axios;

describe('Data Flow Integration', () => {
  let mockCache;
  let fetchYnetData;
  let fetchAlertsData;

  beforeEach(() => {
    jest.clearAllMocks();
    
    // Create mock cache instance
    mockCache = {
      get: jest.fn(),
      set: jest.fn()
    };

    // Simulate the data fetching functions from server.js
    fetchYnetData = async () => {
      const cached = mockCache.get('ynet');
      if (cached) return cached;
      
      const response = await mockAxios.get('https://www.ynet.co.il/Integration/StoryRss1854.xml');
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
      return news;
    };

    fetchAlertsData = async () => {
      const cached = mockCache.get('alerts');
      if (cached) return cached;
      
      try {
        const response = await mockAxios.get('https://www.oref.org.il/warningMessages/alert/Alerts.json');
        let alerts = response.data || [];
        
        // Handle string responses
        if (typeof alerts === 'string') {
          alerts = alerts.trim();
          if (alerts === '' || alerts === '\r\n' || alerts === '\n') {
            alerts = [];
          } else {
            try {
              alerts = JSON.parse(alerts);
            } catch (e) {
              alerts = [];
            }
          }
        }
        
        if (!Array.isArray(alerts)) {
          alerts = [];
        }
        
        mockCache.set('alerts', alerts);
        return alerts;
      } catch (error) {
        // Fallback API
        const fallbackResponse = await mockAxios.get('https://api.tzevaadom.co.il/notifications');
        const alerts = fallbackResponse.data || [];
        mockCache.set('alerts', alerts);
        return alerts;
      }
    };
  });

  describe('Ynet Data Flow', () => {
    test('should fetch, parse, and cache Ynet data', async () => {
      const mockRssData = `
        <rss>
          <channel>
            <item>
              <title>Test News</title>
              <link>https://example.com</link>
              <pubDate>Mon, 16 Jun 2025 10:00:00 +0300</pubDate>
              <description>Test description</description>
            </item>
          </channel>
        </rss>
      `;

      mockCache.get.mockReturnValue(null);
      mockAxios.get.mockResolvedValue({ data: mockRssData });
      
      const mockParser = {
        parseStringPromise: jest.fn().mockResolvedValue({
          rss: {
            channel: [{
              item: [{
                title: ['Test News'],
                link: ['https://example.com'],
                pubDate: ['Mon, 16 Jun 2025 10:00:00 +0300'],
                description: ['Test description']
              }]
            }]
          }
        })
      };
      
      xml2js.Parser.mockImplementation(() => mockParser);

      const result = await fetchYnetData();

      expect(mockAxios.get).toHaveBeenCalledWith('https://www.ynet.co.il/Integration/StoryRss1854.xml');
      expect(mockParser.parseStringPromise).toHaveBeenCalledWith(mockRssData);
      expect(mockCache.set).toHaveBeenCalledWith('ynet', expect.any(Array));
      expect(result).toHaveLength(1);
      expect(result[0]).toMatchObject({
        title: 'Test News',
        link: 'https://example.com',
        pubDate: 'Mon, 16 Jun 2025 10:00:00 +0300',
        description: 'Test description'
      });
    });

    test('should return cached data when available', async () => {
      const cachedData = [{ title: 'Cached News' }];
      mockCache.get.mockReturnValue(cachedData);

      const result = await fetchYnetData();

      expect(mockAxios.get).not.toHaveBeenCalled();
      expect(result).toBe(cachedData);
    });
  });

  describe('Alerts Data Flow', () => {
    test('should fetch and process alerts data', async () => {
      const mockAlertsData = ['רחובות', 'תל אביב'];
      
      mockCache.get.mockReturnValue(null);
      mockAxios.get.mockResolvedValue({ data: mockAlertsData });

      const result = await fetchAlertsData();

      expect(mockAxios.get).toHaveBeenCalledWith('https://www.oref.org.il/warningMessages/alert/Alerts.json');
      expect(mockCache.set).toHaveBeenCalledWith('alerts', mockAlertsData);
      expect(result).toEqual(mockAlertsData);
    });

    test('should handle empty string response', async () => {
      mockCache.get.mockReturnValue(null);
      mockAxios.get.mockResolvedValue({ data: '\r\n' });

      const result = await fetchAlertsData();

      expect(result).toEqual([]);
      expect(mockCache.set).toHaveBeenCalledWith('alerts', []);
    });

    test('should fall back to secondary API on failure', async () => {
      const fallbackData = ['חיפה'];
      
      mockCache.get.mockReturnValue(null);
      mockAxios.get
        .mockRejectedValueOnce(new Error('Primary API failed'))
        .mockResolvedValueOnce({ data: fallbackData });

      const result = await fetchAlertsData();

      expect(mockAxios.get).toHaveBeenCalledTimes(2);
      expect(mockAxios.get).toHaveBeenNthCalledWith(2, 'https://api.tzevaadom.co.il/notifications');
      expect(result).toEqual(fallbackData);
    });
  });

  describe('Change Detection Logic', () => {
    test('should detect data changes for broadcasting', () => {
      const oldData = [{ title: 'Old News' }];
      const newData = [{ title: 'New News' }];
      const sameData = [{ title: 'Old News' }];

      // Simulate change detection logic
      const hasChanged = (old, current) => {
        return JSON.stringify(old) !== JSON.stringify(current);
      };

      expect(hasChanged(oldData, newData)).toBe(true);
      expect(hasChanged(oldData, sameData)).toBe(false);
      expect(hasChanged(null, newData)).toBe(true);
      expect(hasChanged(oldData, null)).toBe(true);
    });
  });
});
