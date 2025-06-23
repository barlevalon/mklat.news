const { test, expect, devices } = require('@playwright/test');

test.describe('Mobile Location Picker Bug Reproduction', () => {
  test('should reproduce z-index layering bug when selecting location', async ({ browser, browserName }) => {
    // Skip mobile device emulation on Firefox (not supported)
    if (browserName === 'firefox') {
      test.skip('Mobile device emulation not supported in Firefox');
      return;
    }
    
    // Create iPhone context
    const context = await browser.newContext(devices['iPhone 12']);
    const page = await context.newPage();
    
    console.log('🔍 Testing location selector z-index layering bug...');
    
    await page.goto('http://localhost:3000');
    await page.waitForTimeout(3000);
    
    // STEP 1: Take initial screenshot
    // Screenshot removed - bug is fixed
    
    // STEP 2: Open location selector
    const locationBtn = page.locator('#primary-location-name');
    await locationBtn.tap();
    await page.waitForTimeout(500);
    
    // STEP 3: Verify selector opens properly
    const locationSelector = page.locator('#location-selector');
    await expect(locationSelector).toHaveClass(/show/);
    // Screenshot removed - bug is fixed
    
    // STEP 4: Check z-index values before interaction
    const selectorZIndex = await locationSelector.evaluate(el => window.getComputedStyle(el).zIndex);
    const newsPanel = page.locator('#news-panel');
    const newsPanelZIndex = await newsPanel.evaluate(el => window.getComputedStyle(el).zIndex);
    const alertsPanel = page.locator('#alerts-panel');
    const alertsPanelZIndex = await alertsPanel.evaluate(el => window.getComputedStyle(el).zIndex);
    
    console.log('🔍 Z-index values:');
    console.log('  Location selector:', selectorZIndex);
    console.log('  News panel:', newsPanelZIndex);
    console.log('  Alerts panel:', alertsPanelZIndex);
    
    // STEP 5: Try to interact with a location in the list
    const locationItems = page.locator('.location-item');
    const firstLocation = locationItems.first();
    
    // Wait for locations to load
    await page.waitForTimeout(2000);
    
    if (await firstLocation.isVisible()) {
      console.log('📍 Clicking first location item...');
      await firstLocation.tap();
      await page.waitForTimeout(500);
      
      // STEP 6: Check if selector is still properly visible
      // Screenshot removed - bug is fixed
      
      // STEP 7: Check if selector is behind news panel
      const selectorBounds = await locationSelector.boundingBox();
      const newsBounds = await newsPanel.boundingBox();
      
      console.log('📐 Bounds after selection:');
      console.log('  Selector:', selectorBounds);
      console.log('  News panel:', newsBounds);
      
      // Check for overlap
      if (selectorBounds && newsBounds) {
        const overlapsX = !(selectorBounds.x + selectorBounds.width < newsBounds.x || 
                           newsBounds.x + newsBounds.width < selectorBounds.x);
        const overlapsY = !(selectorBounds.y + selectorBounds.height < newsBounds.y || 
                           newsBounds.y + newsBounds.height < selectorBounds.y);
        
        if (overlapsX && overlapsY) {
          console.log('❌ BUG DETECTED: Location selector overlaps with news panel!');
          
          // Test if news panel is clickable when it should be blocked
          const newsItemClickable = await newsPanel.locator('.news-item').first().isVisible();
          if (newsItemClickable) {
            console.log('❌ BUG CONFIRMED: News items are clickable through location selector!');
          }
        }
      }
    }
    
    // STEP 8: Try to close selector with OK button
    const okButton = page.locator('.ok-btn');
    if (await okButton.isVisible()) {
      console.log('✅ Clicking OK button...');
      await okButton.tap();
      await page.waitForTimeout(500);
      // Screenshot removed - bug is fixed
    }
    
    console.log('✅ Z-index layering bug test completed');
    await context.close();
  });

  test('should check CSS stacking context', async ({ page }) => {
    await page.goto('http://localhost:3000');
    await page.waitForTimeout(2000);
    
    // Analyze the CSS stacking context
    const stackingInfo = await page.evaluate(() => {
      const selector = document.getElementById('location-selector');
      const alertsPanel = document.getElementById('alerts-panel');
      const newsPanel = document.getElementById('news-panel');
      
      const getComputedStyles = (el) => {
        const styles = window.getComputedStyle(el);
        return {
          position: styles.position,
          zIndex: styles.zIndex,
          transform: styles.transform,
          opacity: styles.opacity
        };
      };
      
      return {
        selector: getComputedStyles(selector),
        alertsPanel: getComputedStyles(alertsPanel),
        newsPanel: getComputedStyles(newsPanel),
        selectorParent: selector.parentElement.className || selector.parentElement.tagName
      };
    });
    
    console.log('🎨 CSS Stacking Context Analysis (After Fix):');
    console.log('Location selector styles:', stackingInfo.selector);
    console.log('Alerts panel styles:', stackingInfo.alertsPanel);
    console.log('News panel styles:', stackingInfo.newsPanel);
    console.log('Selector parent element:', stackingInfo.selectorParent);
    
    // Check if the fix worked
    if (stackingInfo.selectorParent === 'container' && 
        stackingInfo.selector.position === 'fixed') {
      console.log('✅ BUG FIXED: Location selector is now a true overlay!');
      console.log('   Selector is now child of container with fixed positioning');
    }
    
    // Verify z-index is now global
    if (stackingInfo.selector.zIndex === '9999') {
      console.log('✅ Z-INDEX FIXED: Using global z-index 9999');
    }
  });
});
