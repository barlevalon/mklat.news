import { test, expect } from '@playwright/test';

test.describe('Basic Smoke Tests', () => {
  test('should load the application', async ({ page }) => {
    await page.goto('http://localhost:3000');
    
    // Check title
    await expect(page).toHaveTitle(/חדר מלחמה/);
    
    // Check main elements exist
    await expect(page.locator('#primary-location-name')).toBeVisible();
    await expect(page.locator('#news-panel')).toBeVisible();
    await expect(page.locator('#alerts-panel')).toBeVisible();
  });

  test('should toggle location selector', async ({ page }) => {
    await page.goto('http://localhost:3000');
    
    // Wait for page to fully load
    await page.waitForLoadState('networkidle');
    
    // Initially hidden
    const selector = page.locator('#location-selector');
    await expect(selector).not.toHaveClass(/show/);
    
    // Click to open
    await page.locator('#primary-location-name').click();
    
    // Should have show class
    await expect(selector).toHaveClass(/show/);
    
    // Click close button
    const closeBtn = page.locator('#location-selector .close-btn');
    await closeBtn.click();
    
    // Should not have show class
    await expect(selector).not.toHaveClass(/show/);
  });
});