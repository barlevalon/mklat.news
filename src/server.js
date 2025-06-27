import express from 'express';
import cors from 'cors';
import path from 'path';
import { WebSocketServer } from 'ws';
import http from 'http';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

import { createApiRoutes } from './routes/api.routes.js';
import { createWebSocketHandler } from './websocket/websocket.handler.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export function createServer({ alertProvider, newsProvider }) {
  const app = express();
  
  app.use(cors());
  
  // In production, serve the built files from dist
  // In development, we use Vite dev server, so this won't be hit
  app.use(express.static('dist'));

  // API routes with injected providers
  app.use('/api', createApiRoutes({ alertProvider, newsProvider }));

  // Serve JavaScript modules
  app.get('/modules/*', (req, res) => {
    const modulePath = req.params[0];
    res.type('application/javascript');
    res.sendFile(path.join(__dirname, modulePath));
  });

  // Serve main page (catch-all for client-side routing)
  app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, '..', 'dist', 'index.html'));
  });

  return app;
}

export function createHttpServer({ alertProvider, newsProvider }) {
  const app = createServer({ alertProvider, newsProvider });
  const server = http.createServer(app);
  const wss = new WebSocketServer({ server });
  
  // Create websocket handler with providers
  const { handleConnection } = createWebSocketHandler({ 
    alertProvider, 
    newsProvider 
  });
  
  // Handle WebSocket connections
  wss.on('connection', handleConnection);
  
  return { server, app, wss };
}
