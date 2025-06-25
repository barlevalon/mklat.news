import { expect } from '@playwright/test';

/**
 * Test data generators for consistent mock data
 */
export const mockData = {
  // OREF Active alerts
  activeAlerts: {
    none: [],
    single: ['תל אביב - יפו'],
    multiple: ['תל אביב - יפו', 'רמת גן', 'גבעתיים'],
    large: Array.from({ length: 52 }, (_, i) => `עיר ${i + 1}`),
    emptyString: '\r\n'
  },

  // Historical alert HTML generator
  historicalAlert: ({ area, date, time, description, isEnded = false }) => {
    const desc = isEnded ? `האירוע הסתיים ${area}` : `${description} ${area}`;
    return `<div class="alertInfo" area_name="${area}">
      <div class="info">
        <div class="date"><span>${date}</span><span>${time}</span></div>
        <div class="area">${desc}</div>
      </div>
    </div>`;
  },

  // RSS feed generator
  rssFeed: (items) => {
    const itemsXml = items.map(item => `
      <item>
        <title>${item.title}</title>
        <link>${item.link}</link>
        <pubDate>${item.pubDate}</pubDate>
        <description><![CDATA[${item.description}]]></description>
      </item>
    `).join('');

    return `<?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0">
      <channel>
        <title>News Feed</title>
        ${itemsXml}
      </channel>
    </rss>`;
  },

  // Location areas (matching real OREF data)
  locations: {
    districts: [
      { label: 'תל אביב - יפו', value: 'תל אביב - יפו' },
      { label: 'ירושלים', value: 'ירושלים' },
      { label: 'חיפה', value: 'חיפה' },
      { label: 'רמת גן', value: 'רמת גן' },
      { label: 'גבעתיים', value: 'גבעתיים' },
      { label: 'גדרה', value: 'גדרה' },
      { label: 'אזור תעשייה גדרה', value: 'אזור תעשייה גדרה' }
    ]
  }
};

/**
 * Network mocking utilities
 */
export class NetworkMocker {
  constructor(page) {
    this.page = page;
  }

  async mockOrefActiveAlerts(alerts) {
    await this.page.route('**/oref.org.il/warningMessages/alert/Alerts.json', route => {
      route.fulfill({ 
        json: alerts,
        headers: { 'content-type': 'application/json' }
      });
    });
  }

  async mockOrefHistoricalAlerts(alertsHtml) {
    await this.page.route('**/alerts-history.oref.org.il/Shared/Ajax/GetAlerts.aspx*', route => {
      route.fulfill({ 
        body: alertsHtml,
        headers: { 'content-type': 'text/html; charset=utf-8' }
      });
    });
  }

  async mockOrefDistricts(districts = mockData.locations.districts) {
    await this.page.route('**/alerts-history.oref.org.il/Shared/Ajax/GetDistricts.aspx*', route => {
      route.fulfill({ 
        json: districts,
        headers: { 'content-type': 'application/json' }
      });
    });
  }

  async mockNewsFeed(source, items) {
    const urls = {
      ynet: '**/ynet.co.il/Integration/StoryRss1854.xml',
      maariv: '**/maariv.co.il/Rss/RssFeedsMivzakiChadashot',
      walla: '**/rss.walla.co.il/feed/22',
      haaretz: '**/haaretz.co.il/srv/rss---feedly'
    };

    await this.page.route(urls[source], route => {
      route.fulfill({
        body: mockData.rssFeed(items),
        headers: { 'content-type': 'application/rss+xml; charset=utf-8' }
      });
    });
  }

  async mockAllNewsFeeds(newsItems = {}) {
    const defaultItem = {
      title: 'חדשות מבזק',
      link: 'https://example.com/news/1',
      pubDate: new Date().toUTCString(),
      description: 'תיאור החדשות'
    };

    await this.mockNewsFeed('ynet', newsItems.ynet || [defaultItem]);
    await this.mockNewsFeed('maariv', newsItems.maariv || [defaultItem]);
    await this.mockNewsFeed('walla', newsItems.walla || [defaultItem]);
    await this.mockNewsFeed('haaretz', newsItems.haaretz || [defaultItem]);
  }

  async mockNetworkError(urlPattern) {
    await this.page.route(urlPattern, route => {
      route.abort('failed');
    });
  }
}

/**
 * Page interaction helpers
 */
export class AlertsPage {
  constructor(page) {
    this.page = page;
  }

  async goto() {
    await this.page.goto('http://localhost:3000');
    await this.page.waitForLoadState('networkidle');
    
    // Wait for the app to initialize (locations to load)
    await this.page.waitForFunction(() => {
      const locationList = document.getElementById('location-list');
      return locationList && !locationList.innerHTML.includes('טוען רשימת אזורים');
    }, { timeout: 10000 });
  }

  async selectLocation(locationName) {
    // Click the location selector button
    await this.page.locator('#primary-location-name').click();
    
    // Wait for the selector to be visible
    const selector = this.page.locator('#location-selector.show');
    await selector.waitFor({ state: 'visible' });
    
    await this.page.locator('#location-search').fill(locationName);
    await this.page.waitForTimeout(300); // Debounce
    
    const locationItem = this.page.locator('.location-item').filter({ hasText: locationName }).first();
    await locationItem.click();
    
    await this.page.locator('.ok-btn').click();
    
    // Wait for selector to close
    await expect(this.page.locator('#location-selector')).not.toHaveClass(/show/);
    
    // Wait for state update
    await this.page.waitForTimeout(100);
  }

  async getAlertState() {
    const stateIndicator = this.page.locator('#state-indicator');
    const isVisible = await stateIndicator.isVisible();
    
    if (!isVisible) {
      return { state: 'no-location', text: null };
    }

    const classes = await stateIndicator.getAttribute('class');
    const stateText = await this.page.locator('.state-text').textContent();
    
    if (classes.includes('all-clear')) return { state: 'all-clear', text: stateText };
    if (classes.includes('red-alert')) return { state: 'red-alert', text: stateText };
    if (classes.includes('alert-imminent')) return { state: 'alert-imminent', text: stateText };
    if (classes.includes('waiting-clear')) return { state: 'waiting-clear', text: stateText };
    if (classes.includes('just-cleared')) return { state: 'just-cleared', text: stateText };
    
    return { state: 'unknown', text: stateText };
  }

  async getActiveAlerts() {
    // First check if there's a status message showing active alerts count
    const statusElement = await this.page.locator('.active-alerts-status').first();
    const hasActiveAlerts = await statusElement.count() > 0;
    
    if (!hasActiveAlerts) {
      // If no active alerts visible, return empty array
      return [];
    }
    
    const alerts = await this.page.locator('.alert-item.active').all();
    return Promise.all(alerts.map(async alert => {
      // The HTML uses h3 tag for active alerts
      const h3 = await alert.locator('h3').textContent();
      // Remove emoji and trim - using individual replacements to avoid regex issues
      return h3.replace('🚨', '').replace('⚠️', '').replace('📍', '').trim();
    }));
  }

  async getNewsItems() {
    const items = await this.page.locator('.news-item').all();
    return Promise.all(items.map(async item => {
      const title = await item.locator('h3').textContent();
      const source = await item.locator('.news-source').textContent();
      return { title: title.trim(), source: source.trim() };
    }));
  }

  async waitForWebSocketConnection() {
    // Wait for the WebSocket to connect by checking for initial data load
    await expect(this.page.locator('#news-content')).not.toContainText('טוען חדשות...');
  }
}

/**
 * Time manipulation helpers
 */
export const timeHelpers = {
  getCurrentTime() {
    const now = new Date();
    const date = `${now.getDate().toString().padStart(2, '0')}.${(now.getMonth() + 1).toString().padStart(2, '0')}.${now.getFullYear()}`;
    const time = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
    return { date, time };
  },

  getTimeMinutesAgo(minutes) {
    const past = new Date(Date.now() - minutes * 60 * 1000);
    const date = `${past.getDate().toString().padStart(2, '0')}.${(past.getMonth() + 1).toString().padStart(2, '0')}.${past.getFullYear()}`;
    const time = `${past.getHours().toString().padStart(2, '0')}:${past.getMinutes().toString().padStart(2, '0')}`;
    return { date, time };
  }
};

/**
 * WebSocket event simulation
 */
export class WebSocketSimulator {
  constructor(page) {
    this.page = page;
  }

  async waitForConnection() {
    // Wait for WebSocket to be established
    await this.page.waitForFunction(() => {
      return window.ws && window.ws.readyState === 1; // OPEN state
    }, { timeout: 10000 });
  }

  async simulateUpdate(data) {
    await this.page.evaluate((messageData) => {
      if (window.ws && window.ws.onmessage) {
        const event = new MessageEvent('message', {
          data: JSON.stringify(messageData)
        });
        window.ws.onmessage(event);
      }
    }, data);
  }

  async simulateDisconnection() {
    await this.page.evaluate(() => {
      if (window.ws) {
        window.ws.close();
      }
    });
  }
}