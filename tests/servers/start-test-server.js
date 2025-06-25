import { createTestServer } from './test-server.js';
import { POLLING_INTERVAL_MS } from '../../src/config/constants.js';

// Start test server with controllable fake data
const port = process.env.PORT || 3001;
const server = createTestServer({
  alerts: {
    activeAlerts: [],
    historicalAlerts: [],
    alertAreas: [
      'תל אביב - יפו',
      'ירושלים', 
      'חיפה',
      'רמת גן',
      'גבעתיים',
      'גדרה',
      'אזור תעשייה גדרה'
    ]
  },
  news: [{
    title: 'Test News Item',
    link: 'https://example.com/test',
    pubDate: new Date().toISOString(),
    description: 'Test news description',
    source: 'Test Source'
  }]
});

server.listen(port, () => {
  console.log(`Test server running at http://localhost:${port}`);
  console.log(`WebSocket server running at ws://localhost:${port}`);
  console.log(`Background polling started (${POLLING_INTERVAL_MS}ms intervals)`);
  console.log('Using FAKE providers for testing');
});