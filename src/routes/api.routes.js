import express from 'express';

export function createApiRoutes({ alertProvider, newsProvider }) {
  const router = express.Router();

  // Combined news endpoint
  router.get('/ynet', async (req, res) => {
    try {
      const news = await newsProvider.fetchNews();
      res.json(news);
    } catch (error) {
      console.error('News fetch error:', error.message);
      res.status(500).json({ error: 'Failed to fetch news' });
    }
  });

  // Combined alerts endpoint (active + history)
  router.get('/alerts', async (req, res) => {
    try {
      const [active, history] = await Promise.all([
        alertProvider.fetchActiveAlerts(),
        alertProvider.fetchHistoricalAlerts()
      ]);
      res.json({ active, history });
    } catch (error) {
      console.error('Alerts fetch error:', error.message);
      res.status(500).json({ error: 'Failed to fetch alerts' });
    }
  });
  
  // Active alerts only endpoint
  router.get('/alerts/active', async (req, res) => {
    try {
      const active = await alertProvider.fetchActiveAlerts();
      res.json(active);
    } catch (error) {
      console.error('Active alerts fetch error:', error.message);
      res.status(500).json({ error: 'Failed to fetch active alerts' });
    }
  });
  
  // Historical alerts only endpoint
  router.get('/alerts/history', async (req, res) => {
    try {
      const history = await alertProvider.fetchHistoricalAlerts();
      res.json(history);
    } catch (error) {
      console.error('Historical alerts fetch error:', error.message);
      res.status(500).json({ error: 'Failed to fetch historical alerts' });
    }
  });

  // Get all possible alert areas/locations
  router.get('/alert-areas', async (req, res) => {
    try {
      const alertAreas = await alertProvider.fetchAlertAreas();
      res.json(alertAreas);
    } catch (error) {
      console.error('Error fetching alert areas:', error.message);
      res.status(500).json({ error: 'Failed to fetch alert areas' });
    }
  });

  // Health check
  router.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
  });

  return router;
}
