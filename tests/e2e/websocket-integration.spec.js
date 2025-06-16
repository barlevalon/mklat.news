const { test, expect } = require('@playwright/test');

test.describe('WebSocket Real-time Integration', () => {
    const serverPort = 3000; // Use existing server

    test('should connect to WebSocket and receive initial data', async ({ page }) => {
        // Navigate to the page
        await page.goto(`http://localhost:${serverPort}`);

        // Wait for WebSocket connection
        await page.waitForFunction(() => {
            return window.ws && window.ws.readyState === 1; // 1 = 1
        }, { timeout: 10000 });

        // Check for connection status indicator
        await expect(page.locator('#connectionStatus')).toHaveText('● Real-time');

        // Verify initial data is loaded
        await expect(page.locator('#news-content')).not.toBeEmpty();
        await expect(page.locator('#alerts-content')).not.toBeEmpty();
    });

    test('should show fallback polling when WebSocket fails', async ({ page }) => {
        // Block WebSocket connections
        await page.route('ws://localhost:*', route => route.abort());
        
        await page.goto(`http://localhost:${serverPort}`);

        // Wait for fallback polling to activate
        await page.waitForFunction(() => {
            const status = document.getElementById('connectionStatus');
            return status && status.textContent.includes('Polling');
        }, { timeout: 15000 });

        // Verify fallback status
        await expect(page.locator('#connectionStatus')).toHaveText('◐ Polling');

        // Verify data still loads via HTTP polling
        await expect(page.locator('#news-content')).not.toBeEmpty();
    });

    test('should reconnect WebSocket after disconnection', async ({ page }) => {
        await page.goto(`http://localhost:${serverPort}`);

        // Wait for initial connection
        await page.waitForFunction(() => {
            return window.ws && window.ws.readyState === 1; // 1 = 1
        });

        // Verify real-time status
        await expect(page.locator('#connectionStatus')).toHaveText('● Real-time');

        // Simulate disconnection
        await page.evaluate(() => {
            if (window.ws) {
                window.ws.close();
            }
        });

        // Wait for reconnection attempt
        await page.waitForFunction(() => {
            const status = document.getElementById('connectionStatus');
            return status && (
                status.textContent.includes('Polling') || 
                status.textContent.includes('Real-time')
            );
        }, { timeout: 15000 });

        // Should either reconnect or fall back to polling
        const statusText = await page.locator('#connectionStatus').textContent();
        expect(['● Real-time', '◐ Polling']).toContain(statusText);
    });

    test('should update content in real-time via WebSocket', async ({ page }) => {
        await page.goto(`http://localhost:${serverPort}`);

        // Wait for WebSocket connection
        await page.waitForFunction(() => {
            return window.ws && window.ws.readyState === 1;
        });

        // Inject mock WebSocket message
        await page.evaluate(() => {
            if (window.ws && window.ws.readyState === 1) {
                // Simulate receiving a new alert
                const mockMessage = {
                    type: 'alerts',
                    data: ['דוגמה לאזעקה חדשה - ' + Date.now()]
                };
                
                // Trigger the message handler directly
                if (window.handleWebSocketMessage) {
                    window.handleWebSocketMessage(mockMessage);
                }
            }
        });

        // Verify content updated
        await expect(page.locator('#alerts-content')).toContainText('דוגמה לאזעקה חדשה');
    });

    test('should handle location filtering in real-time', async ({ page }) => {
        await page.goto(`http://localhost:${serverPort}`);

        // Wait for WebSocket connection and data load
        await page.waitForFunction(() => {
            return window.ws && window.ws.readyState === 1;
        });

        // Open location selector
        await page.click('#locationBtn');
        await expect(page.locator('#location-selector')).toHaveClass(/show/);

        // Select a location
        await page.fill('#location-search', 'תל אביב');
        await page.click('input[value="תל אביב"]');

        // Verify location is selected
        await expect(page.locator('#selected-locations')).toContainText('תל אביב');

        // Simulate new alert for Tel Aviv
        await page.evaluate(() => {
            if (window.ws && window.ws.readyState === 1) {
                const mockMessage = {
                    type: 'alerts',
                    data: ['תל אביב']
                };
                
                if (window.handleWebSocketMessage) {
                    window.handleWebSocketMessage(mockMessage);
                }
            }
        });

        // Verify alert is shown (not filtered out)
        await expect(page.locator('#alerts-content')).toContainText('תל אביב');
    });

    test('should maintain connection across page visibility changes', async ({ page }) => {
        await page.goto(`http://localhost:${serverPort}`);

        // Wait for connection
        await page.waitForFunction(() => {
            return window.ws && window.ws.readyState === 1;
        });

        // Simulate page becoming hidden
        await page.evaluate(() => {
            Object.defineProperty(document, 'hidden', { value: true, configurable: true });
            document.dispatchEvent(new Event('visibilitychange'));
        });

        // Wait a moment
        await page.waitForTimeout(1000);

        // Simulate page becoming visible again
        await page.evaluate(() => {
            Object.defineProperty(document, 'hidden', { value: false, configurable: true });
            document.dispatchEvent(new Event('visibilitychange'));
        });

        // Connection should still be active
        await expect(page.locator('#connectionStatus')).toHaveText('● Real-time');
    });
});

test.describe('WebSocket Performance Tests', () => {
    test('should handle rapid message updates', async ({ page }) => {
        await page.goto('http://localhost:3000');

        // Wait for connection
        await page.waitForFunction(() => {
            return window.ws && window.ws.readyState === 1;
        });

        // Send multiple rapid updates
        await page.evaluate(() => {
            if (window.ws && window.handleWebSocketMessage) {
                for (let i = 0; i < 10; i++) {
                    setTimeout(() => {
                        window.handleWebSocketMessage({
                            type: 'alerts',
                            data: [`Test Alert ${i}`]
                        });
                    }, i * 100);
                }
            }
        });

        // Wait for updates to process
        await page.waitForTimeout(1500);

        // Verify latest update is shown
        await expect(page.locator('#alerts-content')).toContainText('Test Alert 9');
    });

    test('should not memory leak with frequent connections', async ({ page }) => {
        await page.goto('http://localhost:3000');

        // Get initial memory usage
        const initialMemory = await page.evaluate(() => {
            return performance.memory ? performance.memory.usedJSHeapSize : 0;
        });

        // Simulate multiple connection cycles
        for (let i = 0; i < 5; i++) {
            await page.evaluate(() => {
                if (window.ws) {
                    window.ws.close();
                }
            });

            await page.waitForTimeout(1000);

            await page.evaluate(() => {
                if (window.initializeRealTimeUpdates) {
                    window.initializeRealTimeUpdates();
                }
            });

            await page.waitForTimeout(1000);
        }

        // Check memory hasn't grown excessively
        const finalMemory = await page.evaluate(() => {
            return performance.memory ? performance.memory.usedJSHeapSize : 0;
        });

        if (initialMemory > 0) {
            const memoryGrowth = (finalMemory - initialMemory) / initialMemory;
            expect(memoryGrowth).toBeLessThan(0.5); // Less than 50% growth
        }
    });
});
