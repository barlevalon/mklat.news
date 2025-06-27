import { WebSocket } from 'ws';
import { hasDataChanged } from '../utils/data.util.js';
import { POLLING_INTERVAL_MS } from '../config/constants.js';

export function createWebSocketHandler({ alertProvider, newsProvider }) {
  // Store WebSocket clients
  const clients = new Set();
  
  // Store last known data for change detection
  let lastNewsData = null;
  let lastAlertsData = null;
  
  // Polling interval reference
  let pollingInterval = null;
  
  // WebSocket connection handler
  function handleConnection(ws) {
    clients.add(ws);
    
    // Start polling when first client connects
    if (clients.size === 1 && !pollingInterval) {
      startPolling();
    }
    
    // Send initial data
    sendInitialData(ws);
    
    ws.on('close', () => {
      clients.delete(ws);
      
      // Stop polling when last client disconnects
      if (clients.size === 0 && pollingInterval) {
        stopPolling();
      }
    });
    
    ws.on('error', (error) => {
      console.error('WebSocket error:', error);
      clients.delete(ws);
      
      // Stop polling when last client disconnects
      if (clients.size === 0 && pollingInterval) {
        stopPolling();
      }
    });
  }

  // Send initial data to new WebSocket clients
  async function sendInitialData(ws) {
    try {
      const [newsData, alertsData, locationsData] = await Promise.all([
        newsProvider.fetchNews(),
        Promise.all([
          alertProvider.fetchActiveAlerts(),
          alertProvider.fetchHistoricalAlerts()
        ]).then(([active, history]) => ({ active, history })),
        alertProvider.fetchAlertAreas()
      ]);
      
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({
          type: 'initial',
          data: {
            ynet: newsData,
            alerts: alertsData,
            locations: locationsData
          }
        }));
      }
    } catch (error) {
      console.error('Error sending initial data:', error);
    }
  }

  // Broadcast data to all connected WebSocket clients
  function broadcastToClients(type, data) {
    const message = JSON.stringify({ type, data });
    const deadClients = new Set();
    
    clients.forEach(ws => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(message);
      } else {
        deadClients.add(ws);
      }
    });
    
    // Clean up dead connections
    deadClients.forEach(ws => clients.delete(ws));
  }

  // Background polling
  async function backgroundPoll() {
    // Skip polling if no clients are connected
    if (clients.size === 0) {
      return;
    }
    
    try {
      // Fetch new data
      const [newsData, alertsData] = await Promise.all([
        newsProvider.fetchNews(),
        Promise.all([
          alertProvider.fetchActiveAlerts(),
          alertProvider.fetchHistoricalAlerts()
        ]).then(([active, history]) => ({ active, history }))
      ]);
      
      // Check for changes and broadcast
      if (hasDataChanged(newsData, lastNewsData)) {
        lastNewsData = newsData;
        broadcastToClients('ynet', newsData);
      }
      
      if (hasDataChanged(alertsData, lastAlertsData)) {
        lastAlertsData = alertsData;
        broadcastToClients('alerts', alertsData);
      }
    } catch (error) {
      console.error('Background polling error:', error);
    }
  }

  // Start background polling
  function startPolling() {
    if (!pollingInterval) {
      pollingInterval = setInterval(backgroundPoll, POLLING_INTERVAL_MS);
    }
  }
  
  // Stop background polling
  function stopPolling() {
    if (pollingInterval) {
      clearInterval(pollingInterval);
      pollingInterval = null;
    }
  }

  return {
    handleConnection,
    startPolling
  };
}
