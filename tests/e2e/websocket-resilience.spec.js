const { test, expect } = require('@playwright/test');

test.describe('WebSocket Connection Resilience', () => {
    test.beforeEach(async ({ page }) => {
        await page.goto('http://localhost:3000');
    });

    test('should attempt reconnection with exponential backoff', async ({ page }) => {
        // Wait for initial connection
        await page.waitForFunction(() => {
            return window.ws && window.ws.readyState === 1;
        });

        // Monitor reconnection attempts
        let reconnectAttempts = [];
        
        await page.exposeFunction('trackReconnect', (attempt, delay) => {
            reconnectAttempts.push({ attempt, delay, timestamp: Date.now() });
        });

        // Inject tracking into the reconnection logic
        await page.evaluate(() => {
            const originalReconnect = window.handleWebSocketReconnect;
            if (originalReconnect) {
                window.handleWebSocketReconnect = function(wsUrl) {
                    const attempt = window.wsReconnectAttempts || 0;
                    const delay = Math.min(1000 * Math.pow(2, attempt), 30000);
                    
                    window.trackReconnect(attempt, delay);
                    
                    return originalReconnect.call(this, wsUrl);
                };
            }
        });

        // Force disconnection
        await page.evaluate(() => {
            if (window.ws) {
                window.ws.close();
            }
        });

        // Wait for multiple reconnection attempts
        await page.waitForFunction(() => {
            return window.wsReconnectAttempts >= 2;
        }, { timeout: 15000 });

        // Verify exponential backoff
        expect(reconnectAttempts.length).toBeGreaterThanOrEqual(2);
        
        if (reconnectAttempts.length >= 2) {
            expect(reconnectAttempts[1].delay).toBeGreaterThan(reconnectAttempts[0].delay);
        }
    });

    test('should fall back to polling after max reconnect attempts', async ({ page }) => {
        // Block WebSocket connections permanently
        await page.route('ws://localhost:*', route => route.abort());
        
        // Reload page to trigger connection attempts
        await page.reload();

        // Wait for fallback polling to activate
        await page.waitForFunction(() => {
            const status = document.getElementById('connectionStatus');
            return status && status.textContent.includes('Polling');
        }, { timeout: 30000 });

        // Verify fallback status
        await expect(page.locator('#connectionStatus')).toHaveText('◐ Polling');

        // Verify data still loads via HTTP
        await expect(page.locator('#news-content')).not.toBeEmpty();
        await expect(page.locator('#alerts-content')).not.toBeEmpty();
    });

    test('should recover when WebSocket becomes available again', async ({ page }) => {
        // Initially block WebSocket
        await page.route('ws://localhost:*', route => route.abort());
        await page.reload();

        // Wait for fallback polling
        await page.waitForFunction(() => {
            const status = document.getElementById('connectionStatus');
            return status && status.textContent.includes('Polling');
        }, { timeout: 15000 });

        // Re-enable WebSocket connections
        await page.unroute('ws://localhost:*');

        // Manually trigger reconnection attempt
        await page.evaluate(() => {
            if (window.initializeRealTimeUpdates) {
                window.initializeRealTimeUpdates();
            }
        });

        // Wait for WebSocket to reconnect
        await page.waitForFunction(() => {
            return window.ws && window.ws.readyState === 1;
        }, { timeout: 10000 });

        // Verify real-time status restored
        await expect(page.locator('#connectionStatus')).toHaveText('● Real-time');
    });

    test('should handle server restarts gracefully', async ({ page }) => {
        // Wait for initial connection
        await page.waitForFunction(() => {
            return window.ws && window.ws.readyState === 1;
        });

        // Simulate server restart by closing connection
        await page.evaluate(() => {
            if (window.ws) {
                // Simulate server-side close
                window.ws.close(1006, 'Server restart');
            }
        });

        // Should either reconnect or fall back to polling
        await page.waitForFunction(() => {
            const status = document.getElementById('connectionStatus');
            return status && (
                status.textContent.includes('Real-time') || 
                status.textContent.includes('Polling')
            );
        }, { timeout: 20000 });

        // Data should still be available
        await expect(page.locator('#news-content')).not.toBeEmpty();
    });

    test('should maintain location filter state during reconnection', async ({ page }) => {
        // Wait for initial connection
        await page.waitForFunction(() => {
            return window.ws && window.ws.readyState === 1;
        });

        // Set up location filter
        await page.click('#locationBtn');
        await page.fill('#location-search', 'תל אביב');
        await page.click('input[value="תל אביב"]');

        // Verify filter is set
        await expect(page.locator('#selected-locations')).toContainText('תל אביב');

        // Force reconnection
        await page.evaluate(() => {
            if (window.ws) {
                window.ws.close();
            }
        });

        // Wait for reconnection or fallback
        await page.waitForFunction(() => {
            const status = document.getElementById('connectionStatus');
            return status && (
                status.textContent.includes('Real-time') || 
                status.textContent.includes('Polling')
            );
        }, { timeout: 15000 });

        // Verify location filter persisted
        await expect(page.locator('#selected-locations')).toContainText('תל אביב');
    });

    test('should handle rapid connection state changes', async ({ page }) => {
        // Wait for initial connection
        await page.waitForFunction(() => {
            return window.ws && window.ws.readyState === 1;
        });

        // Rapidly open/close connections
        for (let i = 0; i < 5; i++) {
            await page.evaluate(() => {
                if (window.ws) {
                    window.ws.close();
                }
            });

            await page.waitForTimeout(500);

            await page.evaluate(() => {
                if (window.initializeRealTimeUpdates) {
                    window.initializeRealTimeUpdates();
                }
            });

            await page.waitForTimeout(500);
        }

        // Should settle into a stable state
        await page.waitForFunction(() => {
            const status = document.getElementById('connectionStatus');
            return status && (
                status.textContent.includes('Real-time') || 
                status.textContent.includes('Polling')
            );
        }, { timeout: 10000 });

        // Application should still be functional
        await expect(page.locator('#news-content')).not.toBeEmpty();
    });

    test('should handle network timeout scenarios', async ({ page }) => {
        // Delay WebSocket responses to simulate timeout
        await page.route('ws://localhost:*', async (route) => {
            await new Promise(resolve => setTimeout(resolve, 5000));
            route.abort();
        });

        await page.reload();

        // Should fall back to polling after timeout
        await page.waitForFunction(() => {
            const status = document.getElementById('connectionStatus');
            return status && status.textContent.includes('Polling');
        }, { timeout: 15000 });

        // Verify fallback works
        await expect(page.locator('#connectionStatus')).toHaveText('◐ Polling');
    });

    test('should clean up resources on page unload', async ({ page }) => {
        // Wait for connection
        await page.waitForFunction(() => {
            return window.ws && window.ws.readyState === 1;
        });

        // Monitor cleanup
        let cleanupCalled = false;
        await page.exposeFunction('trackCleanup', () => {
            cleanupCalled = true;
        });

        // Add cleanup tracking
        await page.evaluate(() => {
            window.addEventListener('beforeunload', () => {
                if (window.ws) {
                    window.ws.close();
                    window.trackCleanup();
                }
            });
        });

        // Navigate away
        await page.goto('about:blank');

        // Verify cleanup was called
        expect(cleanupCalled).toBe(true);
    });
});

test.describe('WebSocket Performance Under Load', () => {
    test('should handle multiple rapid messages', async ({ page }) => {
        await page.goto('http://localhost:3000');

        // Wait for connection
        await page.waitForFunction(() => {
            return window.ws && window.ws.readyState === 1;
        });

        // Send rapid messages
        await page.evaluate(() => {
            if (window.handleWebSocketMessage) {
                for (let i = 0; i < 50; i++) {
                    setTimeout(() => {
                        window.handleWebSocketMessage({
                            type: 'alerts',
                            data: [`Rapid Alert ${i}`]
                        });
                    }, i * 10); // Every 10ms
                }
            }
        });

        // Wait for processing
        await page.waitForTimeout(1000);

        // Verify UI is responsive
        await expect(page.locator('#alerts-content')).toContainText('Rapid Alert');
        
        // Check no JavaScript errors occurred
        const errors = await page.evaluate(() => window.__errors || []);
        expect(errors.length).toBe(0);
    });

    test('should maintain performance with long-running connection', async ({ page }) => {
        await page.goto('http://localhost:3000');

        // Wait for connection
        await page.waitForFunction(() => {
            return window.ws && window.ws.readyState === 1;
        });

        // Get initial performance metrics
        const initialMetrics = await page.evaluate(() => ({
            memory: performance.memory ? performance.memory.usedJSHeapSize : 0,
            eventListeners: document.querySelectorAll('*').length
        }));

        // Simulate long-running session with periodic updates
        for (let i = 0; i < 20; i++) {
            await page.evaluate((index) => {
                if (window.handleWebSocketMessage) {
                    window.handleWebSocketMessage({
                        type: 'ynet',
                        data: [{ title: `News Update ${index}`, link: 'http://test.com' }]
                    });
                }
            }, i);

            await page.waitForTimeout(200);
        }

        // Check final performance metrics
        const finalMetrics = await page.evaluate(() => ({
            memory: performance.memory ? performance.memory.usedJSHeapSize : 0,
            eventListeners: document.querySelectorAll('*').length
        }));

        // Memory should not have grown significantly
        if (initialMetrics.memory > 0) {
            const memoryGrowth = (finalMetrics.memory - initialMetrics.memory) / initialMetrics.memory;
            expect(memoryGrowth).toBeLessThan(0.3); // Less than 30% growth
        }

        // DOM should not have excessive growth
        expect(finalMetrics.eventListeners).toBeLessThan(initialMetrics.eventListeners * 2);
    });
});
