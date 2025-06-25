import axios from 'axios';
import { withCache } from './cache.service.js';
import { createAxiosConfig } from '../utils/axios.util.js';
import { processAlertAreasData } from '../utils/data.util.js';
import { parseHistoricalAlertsHTML } from '../utils/html-parser.util.js';
import { API_ENDPOINTS, CACHE_TTL, FALLBACK_ALERT_AREAS } from '../config/constants.js';

// Helper function to normalize OREF API response
function normalizeAlertsResponse(data) {
  let alerts = data || [];
  
  // Handle different response formats from OREF API
  if (typeof alerts === 'string') {
    alerts = alerts.trim();
    if (alerts === '' || alerts === '\r\n' || alerts === '\n') {
      alerts = []; // No alerts
    } else {
      try {
        alerts = JSON.parse(alerts);
      } catch (e) {
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
    const response = await axios.get(API_ENDPOINTS.OREF_CURRENT_ALERTS, 
      createAxiosConfig(15000, {
        'X-Requested-With': 'XMLHttpRequest',
        'Referer': 'https://www.oref.org.il/'
      }));
    
    const normalized = normalizeAlertsResponse(response.data);
    return normalized;
  } catch (error) {
    console.error('Primary alerts API failed:', error.message);
    try {
      const fallbackResponse = await axios.get(API_ENDPOINTS.TZEVA_ADOM_FALLBACK, 
        createAxiosConfig(15000));
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
    const response = await axios.get(API_ENDPOINTS.OREF_HISTORICAL_ALERTS, createAxiosConfig(30000));
    const html = response.data;
    const parsed = parseHistoricalAlertsHTML(html);
    return parsed;
  } catch (error) {
    console.error('Error fetching historical alerts:', error.message);
    return [];
  }
});

// Alert areas fetching
const fetchAlertAreas = withCache('alert-areas', CACHE_TTL.LONG, async () => {
  try {
    const response = await axios.get(API_ENDPOINTS.OREF_DISTRICTS, createAxiosConfig());
    
    const data = response.data || [];
    const alertAreas = processAlertAreasData(data);
    return alertAreas;
  } catch (error) {
    console.error('Error in fetchAlertAreas:', error.message);
    
    // Try backup API from oref.org.il
    try {
      const backupResponse = await axios.get(API_ENDPOINTS.OREF_CITIES_BACKUP, createAxiosConfig());

      const backupData = backupResponse.data || [];
      const backupAreas = processAlertAreasData(backupData);

      if (backupAreas.length > 0) {
        return backupAreas;
      }
    } catch (backupError) {
      console.error('Backup API also failed:', backupError.message);
    }
    
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

export {
  fetchActiveAlerts,
  fetchHistoricalAlerts,
  fetchAlertAreas,
  fetchAlertsData
};
