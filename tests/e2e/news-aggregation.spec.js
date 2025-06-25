import { test, expect } from '@playwright/test';
import { NetworkMocker, AlertsPage } from './helpers/test-helpers.js';
import { TestControl } from './helpers/test-control.js';

test.describe('News Aggregation', () => {
  let mocker;
  let alertsPage;
  let testControl;

  test.beforeEach(async ({ page }) => {
    mocker = new NetworkMocker(page);
    alertsPage = new AlertsPage(page);
    testControl = new TestControl(page);

    // Clear test data
    await testControl.clearAllAlerts();
    await testControl.setNews([]);
  });

  test('should aggregate news from all sources', async ({ page: _page }) => {
    // Set news items using test control API
    const now = new Date();
    await testControl.setNews([
      {
        title: 'חדשות מ-Ynet',
        link: 'https://ynet.co.il/news/1',
        pubDate: now.toISOString(),
        description: 'תיאור מ-Ynet',
        source: 'Ynet'
      },
      {
        title: 'חדשות מ-Maariv',
        link: 'https://maariv.co.il/news/1',
        pubDate: new Date(Date.now() - 60000).toISOString(), // 1 minute ago
        description: 'תיאור מ-Maariv',
        source: 'Maariv'
      },
      {
        title: 'חדשות מ-Walla',
        link: 'https://walla.co.il/news/1',
        pubDate: new Date(Date.now() - 120000).toISOString(), // 2 minutes ago
        description: 'תיאור מ-Walla',
        source: 'Walla'
      },
      {
        title: 'חדשות מ-Haaretz',
        link: 'https://haaretz.co.il/news/1',
        pubDate: new Date(Date.now() - 180000).toISOString(), // 3 minutes ago
        description: 'תיאור מ-Haaretz',
        source: 'Haaretz'
      }
    ]);

    await alertsPage.goto();
    await alertsPage.waitForWebSocketConnection();

    // Get all news items
    const newsItems = await alertsPage.getNewsItems();

    // Should have news from all 4 sources
    expect(newsItems).toHaveLength(4);
    
    // Should be sorted by date (newest first)
    expect(newsItems[0].title).toContain('Ynet');
    expect(newsItems[1].title).toContain('Maariv');
    expect(newsItems[2].title).toContain('Walla');
    expect(newsItems[3].title).toContain('Haaretz');

    // Each should show its source
    expect(newsItems[0].source).toBe('Ynet');
    expect(newsItems[1].source).toBe('Maariv');
    expect(newsItems[2].source).toBe('Walla');
    expect(newsItems[3].source).toBe('Haaretz');
  });

  test('should handle RSS feed errors gracefully', async ({ page: _page }) => {
    // Set only some news sources (simulating others failed)
    await testControl.setNews([
      {
        title: 'חדשות מ-Ynet',
        link: 'https://ynet.co.il/news/1',
        pubDate: new Date().toISOString(),
        description: 'תיאור',
        source: 'Ynet'
      },
      {
        title: 'חדשות מ-Maariv',
        link: 'https://maariv.co.il/news/1',
        pubDate: new Date().toISOString(),
        description: 'תיאור',
        source: 'Maariv'
      }
    ]);

    await alertsPage.goto();
    await alertsPage.waitForWebSocketConnection();

    // Should still show news from working sources
    const newsItems = await alertsPage.getNewsItems();
    expect(newsItems.length).toBeGreaterThanOrEqual(2);
    
    // Should have Ynet and Maariv
    const sources = newsItems.map(item => item.source);
    expect(sources).toContain('Ynet');
    expect(sources).toContain('Maariv');
  });

  test('should limit news items per source', async ({ page: _page }) => {
    // Mock many items from one source
    const manyItems = Array.from({ length: 20 }, (_, i) => ({
      title: `חדשות ${i + 1}`,
      link: `https://ynet.co.il/news/${i + 1}`,
      pubDate: new Date(Date.now() - i * 60000).toUTCString(),
      description: `תיאור ${i + 1}`
    }));

    await mocker.mockNewsFeed('ynet', manyItems);
    await mocker.mockNewsFeed('maariv', manyItems);
    await mocker.mockNewsFeed('walla', []);
    await mocker.mockNewsFeed('haaretz', []);

    await alertsPage.goto();
    await alertsPage.waitForWebSocketConnection();

    // Should limit items (check implementation for exact limit)
    const newsItems = await alertsPage.getNewsItems();
    const ynetItems = newsItems.filter(item => item.source === 'Ynet');
    
    // Typically limited to 3-5 items per source for balance
    expect(ynetItems.length).toBeLessThanOrEqual(5);
  });

  test('should display Hebrew content correctly', async ({ page: _page }) => {
    await testControl.setNews([{
      title: 'דיווח: צה"ל תקף במרחב רפיח',
      link: 'https://ynet.co.il/news/1',
      pubDate: new Date().toISOString(),
      description: 'כוחות צה"ל פעלו הלילה במרחב רפיח שבדרום רצועת עזה',
      source: 'Ynet'
    }]);

    await alertsPage.goto();
    await alertsPage.waitForWebSocketConnection();

    // Verify Hebrew renders correctly
    const newsItems = await alertsPage.getNewsItems();
    const hebrewItem = newsItems.find(item => item.source === 'Ynet');
    
    expect(hebrewItem).toBeDefined();
    expect(hebrewItem.title).toContain('צה"ל');
    expect(hebrewItem.title).toContain('רפיח');
  });
});