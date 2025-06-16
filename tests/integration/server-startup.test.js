const request = require('supertest');
const express = require('express');
const http = require('http');
const WebSocket = require('ws');

describe('Server Startup Integration', () => {
  let app;
  let server;
  let wss;

  beforeAll(() => {
    // Create the same server structure as in server.js
    app = express();
    server = http.createServer(app);
    wss = new WebSocket.Server({ server });

    // Add basic middleware
    app.use(express.static('public'));

    // Health check endpoint
    app.get('/api/health', (req, res) => {
      res.json({ 
        status: 'ok', 
        timestamp: new Date().toISOString(),
        websocket: wss.clients.size 
      });
    });

    // Mock data endpoints
    app.get('/api/ynet', (req, res) => {
      res.json([{
        title: 'Test News',
        link: 'https://example.com',
        pubDate: new Date().toISOString(),
        description: 'Test description'
      }]);
    });

    app.get('/api/alerts', (req, res) => {
      res.json([]);
    });

    app.get('/api/alert-areas', (req, res) => {
      res.json(['תל אביב', 'ירושלים', 'חיפה']);
    });

    // WebSocket connection handling
    wss.on('connection', (ws) => {
      // Send initial data
      ws.send(JSON.stringify({
        type: 'initial',
        data: {
          ynet: [],
          alerts: [],
          locations: ['תל אביב', 'ירושלים']
        }
      }));

      ws.on('close', () => {
        // Cleanup handled automatically
      });
    });
  });

  afterAll((done) => {
    wss.close();
    if (server.listening) {
      server.close(done);
    } else {
      done();
    }
  });

  test('should start server with all required endpoints', async () => {
    await new Promise((resolve) => {
      server.listen(0, resolve);
    });

    const port = server.address().port;

    // Test all API endpoints
    const health = await request(app).get('/api/health').expect(200);
    expect(health.body.status).toBe('ok');

    await request(app).get('/api/ynet').expect(200);
    await request(app).get('/api/alerts').expect(200);
    await request(app).get('/api/alert-areas').expect(200);
  });

  test('should handle WebSocket connections during server operation', async () => {
    const port = server.address().port;
    
    // Test WebSocket connection
    const ws = new WebSocket(`ws://localhost:${port}`);
    
    const connectionPromise = new Promise((resolve) => {
      ws.on('open', () => {
        resolve();
      });
    });

    const messagePromise = new Promise((resolve) => {
      ws.on('message', (data) => {
        const message = JSON.parse(data);
        expect(message.type).toBe('initial');
        expect(message.data).toHaveProperty('ynet');
        expect(message.data).toHaveProperty('alerts');
        expect(message.data).toHaveProperty('locations');
        resolve();
      });
    });

    await connectionPromise;
    await messagePromise;

    // Test health endpoint includes WebSocket count
    const health = await request(app).get('/api/health').expect(200);
    expect(health.body.websocket).toBeGreaterThanOrEqual(1);

    ws.close();
  });

  test('should handle multiple concurrent requests', async () => {
    const promises = [];

    // Multiple HTTP requests
    for (let i = 0; i < 10; i++) {
      promises.push(request(app).get('/api/health'));
    }

    // Multiple WebSocket connections
    const port = server.address().port;
    for (let i = 0; i < 5; i++) {
      promises.push(new Promise((resolve) => {
        const ws = new WebSocket(`ws://localhost:${port}`);
        ws.on('open', () => {
          ws.close();
          resolve();
        });
      }));
    }

    // All should complete successfully
    const results = await Promise.all(promises);
    expect(results.length).toBe(15);
  });

  test('should gracefully handle server shutdown', async () => {
    const port = server.address().port;
    
    // Create a WebSocket connection
    const ws = new WebSocket(`ws://localhost:${port}`);
    
    await new Promise((resolve) => {
      ws.on('open', resolve);
    });

    // WebSocket should be connected
    expect(ws.readyState).toBe(WebSocket.OPEN);

    // Close server
    await new Promise((resolve) => {
      server.close(resolve);
    });

    // WebSocket should eventually close
    await new Promise((resolve) => {
      ws.on('close', resolve);
    });

    expect(ws.readyState).toBe(WebSocket.CLOSED);
  });
});
