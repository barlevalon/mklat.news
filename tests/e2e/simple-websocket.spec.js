const { test, expect } = require('@playwright/test');

test.describe('Critical User Journey (E2E)', () => {
    test('should complete full user journey successfully', async ({ page }) => {
        // STEP 1: Load the application
        await page.goto('http://localhost:3000');
        
        // STEP 2: Verify page loads with correct title
        await expect(page).toHaveTitle(/חדר מלחמה/);
        
        // STEP 3: Wait for WebSocket connection and data loading
        await page.waitForTimeout(5000);
        
        // STEP 4: Verify connection status is hidden (only shows on error)
        const statusElement = page.locator('#connection-status');
        await expect(statusElement).toBeHidden();
        
        // STEP 5: Verify news content loads
        const newsContent = page.locator('#news-content');
        await expect(newsContent).toBeVisible();
        const newsText = await newsContent.textContent();
        expect(newsText.length).toBeGreaterThan(50); // Should have meaningful content
        
        // STEP 6: Verify alerts content loads (even if "no alerts")
        const alertsContent = page.locator('#alerts-content');
        await expect(alertsContent).toBeVisible();
        const alertsText = await alertsContent.textContent();
        expect(alertsText.length).toBeGreaterThan(0); // Should show something
        
        // STEP 7: Test location filtering functionality
        const locationBtn = page.locator('#primary-location-name');
        await expect(locationBtn).toBeVisible();
        await locationBtn.click();
        
        // STEP 8: Verify location selector opens and works
        const locationSelector = page.locator('#location-selector');
        await expect(locationSelector).toHaveClass(/show/);
        
        const searchInput = page.locator('#location-search');
        await expect(searchInput).toBeVisible();
        await searchInput.fill('תל אביב');
        
        // STEP 9: Close location selector
        const closeBtn = page.locator('.close-btn');
        await closeBtn.scrollIntoViewIfNeeded();
        await closeBtn.click({ force: true });
        await expect(locationSelector).not.toHaveClass(/show/);
        
        console.log('✅ Critical user journey test passed');
        console.log('Connection status: Hidden (working normally)');
        console.log('News content length:', newsText.length);
        console.log('Alerts content:', alertsText.trim());
    });
});
