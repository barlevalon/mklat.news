import { createHttpServer } from './server.js';
import { OrefAlertProvider } from './providers/oref-alert-provider.js';
import { CombinedNewsProvider } from './providers/combined-news-provider.js';
import { POLLING_INTERVAL_MS } from './config/constants.js';

// Create production providers
const alertProvider = new OrefAlertProvider();
const newsProvider = new CombinedNewsProvider();

// Create and start server
const port = process.env.PORT || 3001;
const { server } = createHttpServer({ alertProvider, newsProvider });

server.listen(port, () => {
  console.log(`War Room server running at http://localhost:${port}`);
  console.log(`WebSocket server running at ws://localhost:${port}`);
  console.log(`Background polling started (${POLLING_INTERVAL_MS}ms intervals)`);
});