import express from 'express';
import { createHttpServer } from '../../src/server.js';
import { FakeAlertProvider } from '../mocks/providers/fake-alert-provider.js';
import { FakeNewsProvider } from '../mocks/providers/fake-news-provider.js';

/**
 * Create a test server with fake providers
 * This allows e2e tests to control the data returned by the server
 */
export function createTestServer(config = {}) {
  const alertProvider = new FakeAlertProvider(config.alerts || {});
  const newsProvider = new FakeNewsProvider(config.news || []);
  
  const { server, app, wss } = createHttpServer({ alertProvider, newsProvider });
  
  // Add test control endpoints
  app.post('/test/set-active-alerts', express.json(), (req, res) => {
    alertProvider.setActiveAlerts(req.body.alerts || []);
    res.json({ success: true });
  });
  
  app.post('/test/set-historical-alerts', express.json(), (req, res) => {
    alertProvider.setHistoricalAlerts(req.body.alerts || []);
    res.json({ success: true });
  });
  
  app.post('/test/set-news', express.json(), (req, res) => {
    newsProvider.setNewsItems(req.body.items || []);
    res.json({ success: true });
  });
  
  app.post('/test/set-alert-areas', express.json(), (req, res) => {
    alertProvider.setAlertAreas(req.body.areas || []);
    res.json({ success: true });
  });
  
  // Trigger immediate WebSocket update
  app.post('/test/trigger-update', express.json(), async (req, res) => {
    // This would need access to the WebSocket handler
    // For now, tests can just wait for polling or reload
    res.json({ success: true, message: 'Updates will be sent on next poll' });
  });
  
  // Expose providers for test manipulation
  server.testProviders = {
    alert: alertProvider,
    news: newsProvider
  };
  
  return server;
}