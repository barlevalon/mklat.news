const express = require('express');
const { fetchYnetData } = require('../services/ynet.service');
const { fetchAlertsData, fetchAlertAreas } = require('../services/oref.service');

const router = express.Router();

// Ynet breaking news endpoint
router.get('/ynet', async (req, res) => {
  try {
    const news = await fetchYnetData();
    res.json(news);
  } catch (error) {
    console.error('Ynet fetch error:', error.message);
    res.status(500).json({ error: 'Failed to fetch Ynet news' });
  }
});

// Homefront Command alerts endpoint
router.get('/alerts', async (req, res) => {
  try {
    const alertsData = await fetchAlertsData();
    res.json(alertsData);
  } catch (error) {
    console.error('Alerts fetch error:', error.message);
    res.status(500).json({ error: 'Failed to fetch alerts' });
  }
});

// Get all possible alert areas/locations
router.get('/alert-areas', async (req, res) => {
  try {
    const alertAreas = await fetchAlertAreas();
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

module.exports = router;
