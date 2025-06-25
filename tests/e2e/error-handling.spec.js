import { test, expect } from '@playwright/test';
import { NetworkMocker, AlertsPage, WebSocketSimulator } from './helpers/test-helpers.js';
import { TestControl } from './helpers/test-control.js';

test.describe('Error Handling', () => {
  let mocker;
  let alertsPage;
  let testControl;

  test.beforeEach(async ({ page }) => {
    mocker = new NetworkMocker(page);
    alertsPage = new AlertsPage(page);
    testControl = new TestControl(page);

    // Set up default test data
    await testControl.clearAllAlerts();
    await testControl.setNews([
      {
        title: 'Test News from Ynet',
        link: 'https://ynet.co.il/test',
        pubDate: new Date().toISOString(),
        description: 'Test description',
        source: 'Ynet'
      },
      {
        title: 'Test News from Maariv',
        link: 'https://maariv.co.il/test',
        pubDate: new Date().toISOString(),
        description: 'Test description',
        source: 'Maariv'
      }
    ]);
  });


  test('should show connection error when WebSocket disconnects', async ({ page }) => {
    await mocker.mockOrefActiveAlerts([]);
    await mocker.mockOrefHistoricalAlerts('');
    
    await alertsPage.goto();
    
    const wsSimulator = new WebSocketSimulator(page);
    await wsSimulator.waitForConnection();

    // Initially, connection status should be hidden (connected)
    await expect(page.locator('#connection-status')).toBeHidden();

    // Simulate disconnection
    await wsSimulator.simulateDisconnection();

    // Should show connection error
    await expect(page.locator('#connection-status')).toBeVisible();
    await expect(page.locator('#connection-status')).toContainText('אין חיבור לשרת');
  });

  test('should handle timeout errors gracefully', async ({ page }) => {
    // Mock slow response that will timeout
    await page.route('**/oref.org.il/**', async route => {
      await new Promise(resolve => setTimeout(resolve, 20000)); // 20 second delay
      route.fulfill({ json: [] });
    });

    // But provide fast historical data
    await mocker.mockOrefHistoricalAlerts('');
    
    await alertsPage.goto();
    
    // Page should load despite OREF timeout
    await expect(page.locator('#news-content')).toBeVisible();
    
    // Should not show loading forever
    await expect(page.locator('#alerts-content')).not.toContainText('טוען התרעות...');
  });

  test('should handle location API failure', async ({ page }) => {
    // Mock districts endpoint to fail
    await mocker.mockNetworkError('**/GetDistricts.aspx*');
    
    // Mock other endpoints normally
    await mocker.mockOrefActiveAlerts([]);
    await mocker.mockOrefHistoricalAlerts('');
    
    await alertsPage.goto();
    
    // Try to open location selector
    await page.locator('#primary-location-name').click();
    await expect(page.locator('#location-selector')).toHaveClass(/show/);
    
    // Should show fallback locations or error message
    const locationList = page.locator('#location-list');
    await expect(locationList).toBeVisible();
    
    // Should have some locations (fallback)
    const locations = await page.locator('.location-item').count();
    expect(locations).toBeGreaterThan(0);
  });

  test('should continue updating when one news source fails', async ({ page }) => {
    // Start with all sources working
    await alertsPage.goto();
    await alertsPage.waitForWebSocketConnection();
    
    // Verify initial news loads
    let newsItems = await alertsPage.getNewsItems();
    const initialCount = newsItems.length;
    expect(initialCount).toBe(2); // Ynet and Maariv
    
    // Now simulate one source failing by updating to only show Maariv
    await testControl.setNews([
      {
        title: 'Test News from Maariv',
        link: 'https://maariv.co.il/test',
        pubDate: new Date().toISOString(),
        description: 'Test description',
        source: 'Maariv'
      }
    ]);
    
    // Force a refresh to get new data
    await page.reload();
    await alertsPage.waitForWebSocketConnection();
    
    // Should still have news from other sources
    newsItems = await alertsPage.getNewsItems();
    expect(newsItems.length).toBe(1);
    
    // Should only have Maariv now
    const sources = newsItems.map(item => item.source);
    expect(sources).not.toContain('Ynet');
    expect(sources).toContain('Maariv');
  });

});