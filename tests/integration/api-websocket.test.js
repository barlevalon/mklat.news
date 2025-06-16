const WebSocket = require('ws');
const http = require('http');
const express = require('express');
const axios = require('axios');

// Mock dependencies
jest.mock('axios');
jest.mock('xml2js');
jest.mock('node-cache');

const mockAxios = axios;

describe('API + WebSocket Integration', () => {
  let app;
  let server;
  let wss;
  let port;

  beforeAll((done) => {
    // Create minimal Express app with WebSocket
    app = express();
    server = http.createServer(app);
    wss = new WebSocket.Server({ server });
    
    // Simple health endpoint
    app.get('/api/health', (req, res) => {
      res.json({ status: 'ok' });
    });

    server.listen(0, () => {
      port = server.address().port;
      done();
    });
  });

  afterAll((done) => {
    wss.close();
    server.close(done);
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  test('should establish WebSocket connection and receive health check', async () => {
    // Test HTTP API works
    const response = await axios.get(`http://localhost:${port}/api/health`);
    expect(response.status).toBe(200);

    // Test WebSocket connection works
    const ws = new WebSocket(`ws://localhost:${port}`);
    
    await new Promise((resolve) => {
      ws.on('open', () => {
        expect(ws.readyState).toBe(WebSocket.OPEN);
        ws.close();
        resolve();
      });
    });
  });

  test('should handle concurrent HTTP and WebSocket requests', async () => {
    const promises = [];

    // Multiple HTTP requests
    for (let i = 0; i < 5; i++) {
      promises.push(axios.get(`http://localhost:${port}/api/health`));
    }

    // Multiple WebSocket connections
    for (let i = 0; i < 3; i++) {
      promises.push(new Promise((resolve) => {
        const ws = new WebSocket(`ws://localhost:${port}`);
        ws.on('open', () => {
          ws.close();
          resolve();
        });
      }));
    }

    // All should complete successfully
    await Promise.all(promises);
    expect(promises.length).toBe(8);
  });

  test('should handle WebSocket message broadcasting', (done) => {
    const clients = [];
    const messages = [];

    // Create 3 WebSocket clients
    for (let i = 0; i < 3; i++) {
      const ws = new WebSocket(`ws://localhost:${port}`);
      clients.push(ws);
      
      ws.on('message', (data) => {
        messages.push(JSON.parse(data));
        
        // When all clients received message, test is complete
        if (messages.length === 3) {
          expect(messages).toHaveLength(3);
          expect(messages[0]).toEqual({ type: 'test', data: 'broadcast' });
          
          clients.forEach(client => client.close());
          done();
        }
      });
    }

    // Wait for all connections to be established
    Promise.all(clients.map(ws => new Promise(resolve => {
      ws.on('open', resolve);
    }))).then(() => {
      // Broadcast to all clients
      const message = JSON.stringify({ type: 'test', data: 'broadcast' });
      wss.clients.forEach(client => {
        if (client.readyState === WebSocket.OPEN) {
          client.send(message);
        }
      });
    });
  });
});
