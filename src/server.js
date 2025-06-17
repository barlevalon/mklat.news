const express = require('express');
const cors = require('cors');
const path = require('path');
const WebSocket = require('ws');
const http = require('http');

const apiRoutes = require('./routes/api.routes');
const { handleWebSocketConnection, startBackgroundPolling } = require('./websocket/websocket.handler');
const { POLLING_INTERVAL_MS } = require('./config/constants');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.static('public'));

// API routes
app.use('/api', apiRoutes);

// Serve main page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '..', 'public', 'index.html'));
});

// Create HTTP server and WebSocket server
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Handle WebSocket connections
handleWebSocketConnection(wss);

// Start background polling
startBackgroundPolling();

server.listen(port, () => {
  console.log(`War Room server running at http://localhost:${port}`);
  console.log(`WebSocket server running at ws://localhost:${port}`);
  console.log(`Background polling started (${POLLING_INTERVAL_MS}ms intervals)`);
});
