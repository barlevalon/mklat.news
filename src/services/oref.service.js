const axios = require('axios');
const { withCache } = require('./cache.service');
const { createAxiosConfig } = require('../utils/axios.util');
const { processAlertAreasData } = require('../utils/data.util');
const { parseHistoricalAlertsHTML } = require('../utils/html-parser.util');
const { API_ENDPOINTS, CACHE_TTL, FALLBACK_ALERT_AREAS } = require('../config/constants');

// Helper function to normalize OREF API response
function normalizeAlertsResponse(data) {
  let alerts = data || [];
  console.log('OREF Active Alerts response:', JSON.stringify(alerts).substring(0, 200));
  
  // Handle different response formats from OREF API
  if (typeof alerts === 'string') {
    alerts = alerts.trim();
    if (alerts === '' || alerts === '\r\n' || alerts === '\n') {
      alerts = []; // No alerts
    } else {
      try {
        alerts = JSON.parse(alerts);
      } catch (e) {
        console.log('Failed to parse alerts string, treating as empty:', alerts);
        alerts = [];
      }
    }
  }
  
  if (!Array.isArray(alerts)) {
    alerts = [];
  }
  
  return alerts;
}

// Active alerts fetching
const fetchActiveAlerts = withCache('active-alerts', CACHE_TTL.SHORT, async () => {
  try {
    console.log('Fetching active alerts from:', API_ENDPOINTS.OREF_CURRENT_ALERTS);
    const response = await axios.get(API_ENDPOINTS.OREF_CURRENT_ALERTS, 
      createAxiosConfig(15000, {
        'X-Requested-With': 'XMLHttpRequest',
        'Referer': 'https://www.oref.org.il/'
      }));
    
    const normalized = normalizeAlertsResponse(response.data);
    console.log('Active alerts normalized count:', normalized.length);
    return normalized;
  } catch (error) {
    console.error('Primary alerts API failed:', error.message);
    try {
      console.log('Trying fallback API:', API_ENDPOINTS.TZEVA_ADOM_FALLBACK);
      const fallbackResponse = await axios.get(API_ENDPOINTS.TZEVA_ADOM_FALLBACK, 
        createAxiosConfig(15000));
      console.log('Fallback API response received');
      return fallbackResponse.data || [];
    } catch (fallbackError) {
      console.error('Fallback API also failed:', fallbackError.message);
      return [];
    }
  }
});

// Historical alerts fetching
const fetchHistoricalAlerts = withCache('historical-alerts', CACHE_TTL.MEDIUM, async () => {
  try {
    console.log('Fetching historical alerts from:', API_ENDPOINTS.OREF_HISTORICAL_ALERTS);
    const response = await axios.get(API_ENDPOINTS.OREF_HISTORICAL_ALERTS, createAxiosConfig(30000));
    
    console.log('Historical alerts response received, length:', response.data?.length || 0);
    const html = response.data;
    const parsed = parseHistoricalAlertsHTML(html);
    console.log('Parsed historical alerts count:', parsed.length);
    return parsed;
  } catch (error) {
    console.error('Error fetching historical alerts:', error.message);
    console.error('Request details:', {
      url: API_ENDPOINTS.OREF_HISTORICAL_ALERTS,
      timeout: 30000,
      code: error.code
    });
    return [];
  }
});

// Alert areas fetching
const fetchAlertAreas = withCache('alert-areas', CACHE_TTL.LONG, async () => {
  try {
    const response = await axios.get(API_ENDPOINTS.OREF_DISTRICTS, createAxiosConfig());
    
    const data = response.data || [];
    const alertAreas = processAlertAreasData(data);
    
    console.log(`Fetched ${alertAreas.length} areas from official oref.org.il API`);
    return alertAreas;
  } catch (error) {
    console.error('Error in fetchAlertAreas:', error.message);
    
    // Try backup API from oref.org.il
    try {
      const backupResponse = await axios.get(API_ENDPOINTS.OREF_CITIES_BACKUP, createAxiosConfig());

      const backupData = backupResponse.data || [];
      const backupAreas = processAlertAreasData(backupData);

      if (backupAreas.length > 0) {
        console.log(`Fetched ${backupAreas.length} areas from backup oref.org.il API`);
        return backupAreas;
      }
    } catch (backupError) {
      console.error('Backup API also failed:', backupError.message);
    }
    
    console.log('Using fallback areas list');
    return FALLBACK_ALERT_AREAS;
  }
});

// Combined alerts data
async function fetchAlertsData() {
  // Get both active alerts and historical alerts
  const [activeAlerts, historicalAlerts] = await Promise.all([
    fetchActiveAlerts(),
    fetchHistoricalAlerts()
  ]);
  
  return {
    active: activeAlerts,
    history: historicalAlerts
  };
}

module.exports = {
  fetchActiveAlerts,
  fetchHistoricalAlerts,
  fetchAlertAreas,
  fetchAlertsData
};
