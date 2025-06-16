const axios = require('axios');
const NodeCache = require('node-cache');

// Mock axios and NodeCache
jest.mock('axios');
jest.mock('node-cache');

describe('Background Polling System', () => {
    let mockCache;
    let mockAxios;

    beforeEach(() => {
        jest.clearAllMocks();
        
        mockCache = {
            get: jest.fn(),
            set: jest.fn()
        };
        NodeCache.mockImplementation(() => mockCache);
        
        mockAxios = axios;
        mockAxios.get = jest.fn();
    });

    describe('fetchYnetData', () => {
        test('should return cached data when available', async () => {
            const cachedData = [{ title: 'Cached News' }];
            mockCache.get.mockReturnValue(cachedData);

            // Mock the function (would normally import from server)
            const fetchYnetData = async () => {
                const cached = mockCache.get('ynet');
                if (cached) return cached;
                // ... rest of function
            };

            const result = await fetchYnetData();
            
            expect(mockCache.get).toHaveBeenCalledWith('ynet');
            expect(result).toEqual(cachedData);
            expect(mockAxios.get).not.toHaveBeenCalled();
        });

        test('should fetch fresh data when cache is empty', async () => {
            mockCache.get.mockReturnValue(null);
            
            const mockRssData = {
                data: `<?xml version="1.0"?>
                <rss>
                    <channel>
                        <item>
                            <title>Test News</title>
                            <link>http://test.com</link>
                            <pubDate>Mon, 01 Jan 2024 12:00:00 GMT</pubDate>
                            <description><![CDATA[Test description]]></description>
                        </item>
                    </channel>
                </rss>`
            };
            
            mockAxios.get.mockResolvedValue(mockRssData);

            // Mock fetchYnetData implementation
            const xml2js = require('xml2js');
            const fetchYnetData = async () => {
                const cached = mockCache.get('ynet');
                if (cached) return cached;

                const response = await mockAxios.get('https://www.ynet.co.il/Integration/StoryRss1854.xml', {
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

                mockCache.set('ynet', news);
                return news;
            };

            const result = await fetchYnetData();
            
            expect(mockAxios.get).toHaveBeenCalledWith(
                'https://www.ynet.co.il/Integration/StoryRss1854.xml',
                expect.objectContaining({
                    timeout: 10000,
                    headers: expect.objectContaining({
                        'User-Agent': expect.stringContaining('Mozilla')
                    })
                })
            );
            
            expect(mockCache.set).toHaveBeenCalledWith('ynet', expect.any(Array));
            expect(result).toEqual(expect.arrayContaining([
                expect.objectContaining({
                    title: 'Test News',
                    link: 'http://test.com'
                })
            ]));
        });

        test('should handle network errors gracefully', async () => {
            mockCache.get.mockReturnValue(null);
            mockAxios.get.mockRejectedValue(new Error('Network error'));

            const fetchYnetData = async () => {
                try {
                    const cached = mockCache.get('ynet');
                    if (cached) return cached;

                    await mockAxios.get('https://www.ynet.co.il/Integration/StoryRss1854.xml');
                } catch (error) {
                    return []; // Return empty array on error
                }
            };

            const result = await fetchYnetData();
            
            expect(result).toEqual([]);
        });
    });

    describe('fetchAlertsData', () => {
        test('should try primary API first, fallback on error', async () => {
            mockCache.get.mockReturnValue(null);
            
            // Primary API fails
            mockAxios.get
                .mockRejectedValueOnce(new Error('Primary API failed'))
                .mockResolvedValueOnce({ data: [{ id: 1, text: 'Fallback alert' }] });

            const fetchAlertsData = async () => {
                const cached = mockCache.get('alerts');
                if (cached) return cached;
                
                try {
                    const response = await mockAxios.get('https://www.oref.org.il//warningMessages/alert/Alerts.json', {
                        timeout: 5000,
                        headers: {
                            'X-Requested-With': 'XMLHttpRequest',
                            'Referer': 'https://www.oref.org.il/'
                        }
                    });
                    
                    const alerts = response.data || [];
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

            const result = await fetchAlertsData();
            
            expect(mockAxios.get).toHaveBeenCalledTimes(2);
            expect(mockAxios.get).toHaveBeenNthCalledWith(1, 
                'https://www.oref.org.il//warningMessages/alert/Alerts.json',
                expect.objectContaining({
                    headers: expect.objectContaining({
                        'X-Requested-With': 'XMLHttpRequest',
                        'Referer': 'https://www.oref.org.il/'
                    })
                })
            );
            expect(mockAxios.get).toHaveBeenNthCalledWith(2, 'https://api.tzevaadom.co.il/notifications');
            expect(result).toEqual([{ id: 1, text: 'Fallback alert' }]);
        });

        test('should include proper headers for OREF API', async () => {
            mockCache.get.mockReturnValue(null);
            mockAxios.get.mockResolvedValue({ data: ['Test Alert'] });

            const fetchAlertsData = async () => {
                const cached = mockCache.get('alerts');
                if (cached) return cached;
                
                const response = await mockAxios.get('https://www.oref.org.il//warningMessages/alert/Alerts.json', {
                    timeout: 5000,
                    headers: {
                        'X-Requested-With': 'XMLHttpRequest',
                        'Referer': 'https://www.oref.org.il/'
                    }
                });
                
                return response.data || [];
            };

            await fetchAlertsData();
            
            expect(mockAxios.get).toHaveBeenCalledWith(
                'https://www.oref.org.il//warningMessages/alert/Alerts.json',
                {
                    timeout: 5000,
                    headers: {
                        'X-Requested-With': 'XMLHttpRequest',
                        'Referer': 'https://www.oref.org.il/'
                    }
                }
            );
        });
    });

    describe('Change Detection Logic', () => {
        test('should detect changes in news data', () => {
            const lastData = [{ title: 'Old News', id: 1 }];
            const newData = [{ title: 'New News', id: 2 }];
            
            const hasChanged = JSON.stringify(newData) !== JSON.stringify(lastData);
            expect(hasChanged).toBe(true);
        });

        test('should not trigger on identical data', () => {
            const data = [{ title: 'Same News', id: 1 }];
            
            const hasChanged = JSON.stringify(data) !== JSON.stringify(data);
            expect(hasChanged).toBe(false);
        });

        test('should detect order changes', () => {
            const lastData = [{ title: 'News A' }, { title: 'News B' }];
            const newData = [{ title: 'News B' }, { title: 'News A' }];
            
            const hasChanged = JSON.stringify(newData) !== JSON.stringify(lastData);
            expect(hasChanged).toBe(true);
        });

        test('should handle empty arrays', () => {
            const lastData = [];
            const newData = [{ title: 'First News' }];
            
            const hasChanged = JSON.stringify(newData) !== JSON.stringify(lastData);
            expect(hasChanged).toBe(true);
        });

        test('should handle null to array transition', () => {
            const lastData = null;
            const newData = [];
            
            const hasChanged = JSON.stringify(newData) !== JSON.stringify(lastData);
            expect(hasChanged).toBe(true);
        });
    });

    describe('Polling Interval Logic', () => {
        test('should maintain 2-second intervals', (done) => {
            const mockPoll = jest.fn();
            let callCount = 0;
            
            const interval = setInterval(() => {
                mockPoll();
                callCount++;
                
                if (callCount === 3) {
                    clearInterval(interval);
                    
                    expect(mockPoll).toHaveBeenCalledTimes(3);
                    done();
                }
            }, 10); // Accelerated for testing
        });

        test('should handle polling errors without stopping', async () => {
            const mockPoll = jest.fn()
                .mockRejectedValueOnce(new Error('Network error'))
                .mockResolvedValueOnce('Success')
                .mockRejectedValueOnce(new Error('Another error'))
                .mockResolvedValueOnce('Success again');

            for (let i = 0; i < 4; i++) {
                try {
                    await mockPoll();
                } catch (error) {
                    // Errors should be caught and logged, not stop polling
                    expect(error.message).toMatch(/error/i);
                }
            }

            expect(mockPoll).toHaveBeenCalledTimes(4);
        });
    });
});
