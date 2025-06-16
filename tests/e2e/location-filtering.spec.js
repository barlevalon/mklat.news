const { test, expect } = require('@playwright/test');

test.describe('Location Filtering', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    // Wait for the page to load
    await page.waitForSelector('#alerts-panel');
  });

  test('should display location selector when pin button is clicked', async ({ page }) => {
    const locationButton = page.locator('.location-filter');
    const locationSelector = page.locator('#location-selector');
    
    // Initially selector should be hidden
    await expect(locationSelector).not.toBeVisible();
    
    // Click the location filter button
    await locationButton.click();
    
    // Selector should now be visible
    await expect(locationSelector).toBeVisible();
    
    // Should show the header
    await expect(page.locator('text=בחירת אזורים לאזעקות')).toBeVisible();
  });

  test('should load and display location list', async ({ page }) => {
    // Click location filter to open selector
    await page.locator('.location-filter').click();
    
    // Wait for locations to load
    await page.waitForSelector('.location-item', { timeout: 10000 });
    
    // Should have multiple location items  
    const locationItems = page.locator('.location-item');
    const count = await locationItems.count();
    expect(count).toBeGreaterThan(1000); // We have 1400+ locations from oref.org.il
    
    // Should include Rehovot (רחובות)
    await expect(page.locator('text=רחובות')).toBeVisible();
    
    // Should include Tel Aviv districts (תל אביב)
    await expect(page.locator('text=תל אביב - מרכז העיר')).toBeVisible();
  });

  test('should search and filter locations', async ({ page }) => {
    // Open location selector
    await page.locator('.location-filter').click();
    
    // Wait for locations to load
    await page.waitForSelector('.location-item');
    
    // Search for "רחובות"
    const searchInput = page.locator('#location-search');
    await searchInput.fill('רחובות');
    
    // Should only show matching locations
    const visibleItems = page.locator('.location-item:visible');
    const visibleCount = await visibleItems.count();
    expect(visibleCount).toBe(1); // Should show only רחובות
    await expect(page.locator('text=רחובות')).toBeVisible();
  });

  test('should select and unselect locations', async ({ page }) => {
    // Open location selector
    await page.locator('.location-filter').click();
    
    // Wait for locations to load
    await page.waitForSelector('.location-item');
    
    // Find and click Rehovot checkbox (use first match since there should be only one)
    const rehovotCheckbox = page.locator('input[value="רחובות"]').first();
    await rehovotCheckbox.check();
    
    // Selected count should update
    await expect(page.locator('#selected-count')).toContainText('1 נבחרו');
    
    // Selected locations display should update
    await expect(page.locator('#selected-locations')).toContainText('רחובות');
    
    // Uncheck the location
    await rehovotCheckbox.uncheck();
    
    // Should go back to "כל האזורים"
    await expect(page.locator('#selected-locations')).toContainText('כל האזורים');
    await expect(page.locator('#selected-count')).toContainText('0 נבחרו');
  });

  test('should select multiple locations', async ({ page }) => {
    // Open location selector
    await page.locator('.location-filter').click();
    
    // Wait for locations to load
    await page.waitForSelector('.location-item');
    
    // Select Rehovot
    await page.locator('input[value="רחובות"]').first().check();
    
    // Select Tel Aviv
    await page.locator('input[value="תל אביב - מרכז העיר"]').first().check();
    
    // Should show 2 selected
    await expect(page.locator('#selected-count')).toContainText('2 נבחרו');
    
    // Should show both locations or count
    const selectedText = await page.locator('#selected-locations').textContent();
    expect(selectedText).toMatch(/(רחובות.*תל אביב|תל אביב.*רחובות|2 אזורים נבחרו)/);
  });

  test('should persist selections in localStorage', async ({ page }) => {
    // Open location selector and select Rehovot
    await page.locator('.location-filter').click();
    await page.waitForSelector('.location-item');
    await page.locator('input[value="רחובות"]').first().check();
    
    // Close selector
    await page.locator('.close-btn').click();
    
    // Refresh the page
    await page.reload();
    await page.waitForSelector('#alerts-panel');
    
    // Open selector again
    await page.locator('.location-filter').click();
    await page.waitForSelector('.location-item');
    
    // Rehovot should still be selected
    await expect(page.locator('input[value="רחובות"]').first()).toBeChecked();
    await expect(page.locator('#selected-count')).toContainText('1 נבחרו');
  });

  test('should use select all and clear all buttons', async ({ page }) => {
    // Open location selector
    await page.locator('.location-filter').click();
    await page.waitForSelector('.location-item');
    
    // Click "Select All"
    await page.locator('text=בחר הכל').click();
    
    // Should have many selections
    const selectedCountText = await page.locator('#selected-count').textContent();
    const selectedCount = parseInt(selectedCountText.match(/\d+/)[0]);
    expect(selectedCount).toBeGreaterThan(1000); // We have 1400+ locations
    
    // Click "Clear All"
    await page.locator('text=נקה הכל').click();
    
    // Should be back to 0
    await expect(page.locator('#selected-count')).toContainText('0 נבחרו');
    await expect(page.locator('#selected-locations')).toContainText('כל האזורים');
  });

  test('should close selector with close button', async ({ page }) => {
    // Open location selector
    await page.locator('.location-filter').click();
    await expect(page.locator('#location-selector')).toBeVisible();
    
    // Click close button
    await page.locator('.close-btn').click();
    
    // Should be hidden
    await expect(page.locator('#location-selector')).not.toBeVisible();
  });
});

test.describe('Alert Filtering Integration', () => {
  test('should filter alerts based on selected locations', async ({ page }) => {
    // Mock alerts API to return test data
    await page.route('/api/alerts', async route => {
      const alerts = [
        'רחובות',
        'תל אביב - מרכז העיר', 
        'חיפה',
        'באר שבע',
        'נתניה'
      ];
      await route.fulfill({ json: alerts });
    });

    await page.goto('/');
    await page.waitForSelector('#alerts-panel');
    
    // STEP 1: Verify initial state shows ALL alerts (no filtering)
    await page.waitForSelector('.alert-item', { timeout: 10000 });
    await expect(page.locator('.alert-item')).toHaveCount(5);
    await expect(page.locator('text=🚨 רחובות')).toBeVisible();
    await expect(page.locator('text=🚨 תל אביב - מרכז העיר')).toBeVisible();
    await expect(page.locator('text=🚨 חיפה')).toBeVisible();
    await expect(page.locator('text=🚨 באר שבע')).toBeVisible();
    await expect(page.locator('text=🚨 נתניה')).toBeVisible();
    
    // STEP 2: Apply single location filter (Rehovot only)
    await page.locator('.location-filter').click();
    await page.waitForSelector('.location-item');
    await page.locator('input[value="רחובות"]').first().check();
    await page.locator('.close-btn').click();
    
    // Should now only show Rehovot alert
    await expect(page.locator('.alert-item')).toHaveCount(1);
    await expect(page.locator('text=🚨 רחובות')).toBeVisible();
    await expect(page.locator('text=🚨 תל אביב - מרכז העיר')).not.toBeVisible();
    
    // STEP 3: Add second location (Tel Aviv) - should show 2 alerts
    await page.locator('.location-filter').click();
    await page.waitForSelector('.location-item');
    await page.locator('input[value="תל אביב - מרכז העיר"]').first().check();
    await page.locator('.close-btn').click();
    
    // Should now show both Rehovot and Tel Aviv alerts
    await expect(page.locator('.alert-item')).toHaveCount(2);
    await expect(page.locator('text=🚨 רחובות')).toBeVisible();
    await expect(page.locator('text=🚨 תל אביב - מרכז העיר')).toBeVisible();
    await expect(page.locator('text=🚨 חיפה')).not.toBeVisible();
    
    // STEP 4: Clear all filters - should show ALL alerts again
    await page.locator('.location-filter').click();
    await page.waitForSelector('.location-item');
    await page.locator('text=נקה הכל').click();
    await page.locator('.close-btn').click();
    
    // Should show all 5 alerts again
    await expect(page.locator('.alert-item')).toHaveCount(5);
    await expect(page.locator('text=🚨 רחובות')).toBeVisible();
    await expect(page.locator('text=🚨 תל אביב - מרכז העיר')).toBeVisible();
    await expect(page.locator('text=🚨 חיפה')).toBeVisible();
  });

  test('should show "no alerts" message when no matching alerts', async ({ page }) => {
    // Mock alerts API to return alerts for different locations
    await page.route('/api/alerts', async route => {
      const alerts = ['חיפה', 'באר שבע']; // No Rehovot
      await route.fulfill({ json: alerts });
    });

    await page.goto('/');
    await page.waitForSelector('#alerts-panel');
    
    // Select Rehovot only
    await page.locator('.location-filter').click();
    await page.waitForSelector('.location-item');
    await page.locator('input[value="רחובות"]').first().check();
    await page.locator('.close-btn').click();
    
    // Should show no alerts message
    await expect(page.locator('text=אין אזעקות באזורים הנבחרים')).toBeVisible();
  });

  test('should handle partial location matches in filtering', async ({ page }) => {
    // Mock alerts API with complex location names
    await page.route('/api/alerts', async route => {
      const alerts = [
        'תל אביב - מרכז העיר וגן העיר',
        'תל אביב - יפו ובת ים', 
        'רחובות מזרח',
        'חיפה - כרמל ונווה שאנן'
      ];
      await route.fulfill({ json: alerts });
    });

    await page.goto('/');
    await page.waitForSelector('#alerts-panel');
    
    // Should show all 4 alerts initially
    await page.waitForSelector('.alert-item', { timeout: 10000 });
    await expect(page.locator('.alert-item')).toHaveCount(4);
    
    // Select "רחובות" - should match "רחובות מזרח" (partial match)
    await page.locator('.location-filter').click();
    await page.waitForSelector('.location-item');
    await page.locator('input[value="רחובות"]').first().check();
    await page.locator('.close-btn').click();
    
    // Should show the Rehovot alert (partial match works)
    await expect(page.locator('.alert-item')).toHaveCount(1);
    await expect(page.locator('text=🚨 רחובות מזרח')).toBeVisible();
    await expect(page.locator('text=🚨 תל אביב')).not.toBeVisible();
    await expect(page.locator('text=🚨 חיפה')).not.toBeVisible();
  });

  test('should show correct message when filtering results in no alerts', async ({ page }) => {
    // Mock API with no alerts
    await page.route('/api/alerts', async route => {
      await route.fulfill({ json: [] });
    });

    await page.goto('/');
    await page.waitForSelector('#alerts-panel');
    
    // Should show "no active alerts" message when no alerts at all
    await expect(page.locator('text=✅ אין אזעקות פעילות')).toBeVisible();
    
    // Even after selecting a location, should still show the same message
    await page.locator('.location-filter').click();
    await page.waitForSelector('.location-item');
    await page.locator('input[value="רחובות"]').first().check();
    await page.locator('.close-btn').click();
    
    // Should still show "no active alerts" (not "no alerts in selected areas")
    await expect(page.locator('text=✅ אין אזעקות פעילות')).toBeVisible();
  });
});
