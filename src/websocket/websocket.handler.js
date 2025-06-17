const WebSocket = require('ws');
const { fetchYnetData } = require('../services/ynet.service');
const { fetchAlertsData, fetchAlertAreas } = require('../services/oref.service');
const { hasDataChanged } = require('../utils/data.util');
const { POLLING_INTERVAL_MS } = require('../config/constants');

// Store WebSocket clients
const clients = new Set();

// WebSocket connection handler
function handleWebSocketConnection(wss) {
  wss.on('connection', (ws) => {
    clients.add(ws);
    console.log('WebSocket client connected. Total clients:', clients.size);
    
    // Send initial data
    sendInitialData(ws);
    
    ws.on('close', () => {
      clients.delete(ws);
      console.log('WebSocket client disconnected. Total clients:', clients.size);
    });
    
    ws.on('error', (error) => {
      console.error('WebSocket error:', error);
      clients.delete(ws);
    });
  });
}

// Send initial data to new WebSocket clients
async function sendInitialData(ws) {
  try {
    const [ynetData, alertsData, locationsData] = await Promise.all([
      fetchYnetData(),
      fetchAlertsData(),
      fetchAlertAreas()
    ]);
    
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({
        type: 'initial',
        data: {
          ynet: ynetData,
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

// Background polling system
let lastYnetData = null;
let lastAlertsData = null;

async function backgroundPoll() {
  try {
    // Fetch new data
    const [ynetData, alertsData] = await Promise.all([
      fetchYnetData(),
      fetchAlertsData()
    ]);
    
    // Check for changes and broadcast
    if (hasDataChanged(ynetData, lastYnetData)) {
      lastYnetData = ynetData;
      broadcastToClients('ynet', ynetData);
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
function startBackgroundPolling() {
  setInterval(backgroundPoll, POLLING_INTERVAL_MS);
}

module.exports = {
  handleWebSocketConnection,
  startBackgroundPolling
};
