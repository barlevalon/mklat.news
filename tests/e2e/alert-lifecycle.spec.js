import { test, expect } from '@playwright/test';
import { AlertsPage, timeHelpers } from './helpers/test-helpers.js';
import { TestControl } from './helpers/test-control.js';

test.describe('Alert Lifecycle', () => {
  let alertsPage;
  let testControl;

  test.beforeEach(async ({ page }) => {
    alertsPage = new AlertsPage(page);
    testControl = new TestControl(page);
    
    // Clear any previous test data
    await testControl.clearAllAlerts();
  });

  test('should show all-clear state when no alerts', async ({ page }) => {
    await alertsPage.goto();
    
    // Select a location
    await alertsPage.selectLocation('תל אביב - יפו');
    
    // Verify all-clear state
    const state = await alertsPage.getAlertState();
    expect(state.state).toBe('all-clear');
    expect(state.text).toContain('אין התרעות');
  });

  test('should transition to red alert when location has active alert', async ({ page }) => {
    // Start with no alerts
    await alertsPage.goto();
    await alertsPage.selectLocation('תל אביב - יפו');
    
    // Wait for state to update after location selection
    await page.waitForTimeout(500);
    
    // Verify initial all-clear state
    let state = await alertsPage.getAlertState();
    expect(state.state).toBe('all-clear');
    
    // Set active alerts on the server
    await testControl.setActiveAlerts(['תל אביב - יפו', 'רמת גן']);
    
    // Reload to get new data
    await page.reload();
    
    // Wait for page to load and alerts to be fetched
    await page.waitForLoadState('networkidle');
    
    // Check for console errors
    page.on('console', msg => console.log('Browser console:', msg.type(), msg.text()));
    page.on('pageerror', err => console.log('Page error:', err));
    
    // Wait for alerts to load (not showing "loading" message)
    await page.waitForFunction(() => {
      const alertsContent = document.getElementById('alerts-content');
      return alertsContent && !alertsContent.innerHTML.includes('טוען התרעות');
    }, { timeout: 10000 });
    
    // Debug: Check alert state in various places
    const debugInfo = await page.evaluate(() => {
      const alertsContent = document.getElementById('alerts-content');
      const stateIndicator = document.getElementById('state-indicator');
      const stateText = document.querySelector('.state-text');
      
      return {
        alertsContentHTML: alertsContent ? alertsContent.innerHTML.substring(0, 200) : 'not found',
        stateClasses: stateIndicator ? stateIndicator.className : 'not found',
        stateText: stateText ? stateText.textContent : 'not found',
        selectedLocation: document.getElementById('primary-location-text')?.textContent
      };
    });
    console.log('Debug info:', debugInfo);
    
    // Verify red alert state
    state = await alertsPage.getAlertState();
    expect(state.state).toBe('red-alert');
    expect(state.text).toContain('צבע אדום');
    
    // Verify timer is visible
    await expect(page.locator('#state-timer')).toBeVisible();
    
    // Verify instruction
    await expect(page.locator('#state-instruction')).toContainText('היכנסו למרחב המוגן');
  });

  test('should show waiting state after alert ends', async ({ page }) => {
    // Set a recent historical alert but no active alerts
    const now = new Date();
    await testControl.setHistoricalAlerts([{
      area: 'תל אביב - יפו',
      alertDate: now.toISOString(),
      description: 'ירי רקטות וטילים',
      time: now.toISOString(),
      isActive: false,
      isRecent: true
    }]);
    
    await alertsPage.goto();
    await alertsPage.selectLocation('תל אביב - יפו');
    
    // Should be in waiting state
    const state = await alertsPage.getAlertState();
    expect(state.state).toBe('waiting-clear');
    expect(state.text).toContain('המתינו במרחב המוגן');
    
    // Timer element should exist (but might be empty if no previous active alert)
    await expect(page.locator('#state-timer')).toBeAttached();
  });

  test('should return to all-clear after clearance message', async ({ page }) => {
    const { date, time } = timeHelpers.getCurrentTime();
    
    // Set historical alerts with clearance message
    const now = new Date();
    const twoMinutesAgo = new Date(now.getTime() - 2 * 60 * 1000);
    
    await testControl.setHistoricalAlerts([
      {
        area: 'תל אביב - יפו',
        alertDate: twoMinutesAgo.toISOString(),
        description: 'ירי רקטות וטילים',
        time: twoMinutesAgo.toISOString(),
        isActive: false,
        isRecent: true
      },
      {
        area: 'תל אביב - יפו',
        alertDate: now.toISOString(),
        description: 'האירוע הסתיים',
        time: now.toISOString(),
        isActive: false,
        isRecent: true
      }
    ]);
    
    await alertsPage.goto();
    await alertsPage.selectLocation('תל אביב - יפו');
    
    // Should be back to all-clear
    const state = await alertsPage.getAlertState();
    expect(state.state).toBe('just-cleared');
  });

  test('should not change state for alerts in other locations', async ({ page }) => {
    // Set alerts for other locations
    await testControl.setActiveAlerts(['חיפה', 'עכו']);
    
    await alertsPage.goto();
    await alertsPage.selectLocation('תל אביב - יפו');
    
    // Should remain in all-clear
    const state = await alertsPage.getAlertState();
    expect(state.state).toBe('all-clear');
    
    // Should show total count of active alerts
    await expect(page.locator('#incident-scale')).toContainText('2 התרעות פעילות');
  });

  test('should show incident scale for large events', async ({ page }) => {
    // Create alert for many cities
    const largeCitiesList = Array.from({ length: 52 }, (_, i) => `עיר ${i + 1}`);
    
    // Set both the alerts and the available areas
    await testControl.setAlertAreas(largeCitiesList);
    await testControl.setActiveAlerts(largeCitiesList);
    
    await alertsPage.goto();
    await alertsPage.selectLocation('עיר 1');
    
    // Should show incident scale
    await expect(page.locator('#incident-scale')).toContainText('אירוע נרחב');
    await expect(page.locator('#incident-scale')).toContainText('52 ערים');
  });

  test('should handle empty string response from OREF', async ({ page }) => {
    // Our test server handles this case - just ensure no alerts are set
    await testControl.setActiveAlerts([]);
    
    await alertsPage.goto();
    await alertsPage.selectLocation('תל אביב - יפו');
    
    // Should handle gracefully and show all-clear
    const state = await alertsPage.getAlertState();
    expect(state.state).toBe('all-clear');
  });
});