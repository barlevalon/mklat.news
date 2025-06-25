import { jest } from '@jest/globals';

// Mock external dependencies BEFORE importing services
jest.unstable_mockModule('axios', () => ({
  default: {
    get: jest.fn()
  }
}));

// Mock the background polling to prevent it from running during tests
jest.unstable_mockModule('../../src/websocket/websocket.handler.js', () => ({
  handleWebSocketConnection: jest.fn(),
  startBackgroundPolling: jest.fn()
}));

const mockAxios = (await import('axios')).default;

const { fetchHistoricalAlerts } = await import('../../src/services/oref.service.js');
const { parseHistoricalAlertsHTML } = await import('../../src/utils/html-parser.util.js');

describe('Alert Filtering Logic', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Historical Alert Truncation Bug', () => {
    test('should demonstrate the 50-alert limit bug in current implementation', async () => {
      // Create mock HTML with Tel Aviv alerts appearing after position 50
      const mockHistoricalHTML = `
        <!-- First 50 alerts are from different areas -->
        ${Array.from({ length: 50 }, (_, i) => `<div class="alertInfo" area_name="Other Area ${i}">
          <div class="info">
            <div class="date"><span>17.06.2025</span><span>10:${String(i).padStart(2, '0')}</span></div>
            <div class="area">התרעה Other Area ${i}</div>
          </div>
        </div>`).join('')}
        
        <!-- Tel Aviv alerts appear at position 51+ (currently truncated) -->
        <div class="alertInfo" area_name="תל אביב">
          <div class="info">
            <div class="date"><span>17.06.2025</span><span>09:30</span></div>
            <div class="area">התרעה תל אביב</div>
          </div>
        </div>
        
        <div class="alertInfo" area_name="תל אביב">
          <div class="info">
            <div class="date"><span>17.06.2025</span><span>09:15</span></div>
            <div class="area">התרעה תל אביב</div>
          </div>
        </div>
      `;

      // Mock axios to return our test HTML
      mockAxios.get.mockResolvedValue({ data: mockHistoricalHTML });

      // Test current implementation
      const result = await fetchHistoricalAlerts();

      // Parse all alerts to see what we should get
      const allParsedAlerts = parseHistoricalAlertsHTML(mockHistoricalHTML);
      const telAvivInFullData = allParsedAlerts.filter(alert => 
        alert.area && alert.area.includes('תל אביב')
      );

      // After fix: we should find 2 Tel Aviv alerts in the full data
      expect(telAvivInFullData).toHaveLength(2);
      
      // And the service should return all alerts (not truncated to 50)
      const telAvivInServiceData = result.filter(alert => 
        alert.area && alert.area.includes('תל אביב')
      );
      
      // The fix should make Tel Aviv alerts visible
      expect(telAvivInServiceData).toHaveLength(2);
      
      // The result should contain all 52 alerts (50 + 2 Tel Aviv)
      expect(result).toHaveLength(52);
      
      // And some of them should be Tel Aviv alerts
      expect(result.some(alert => alert.area.includes('תל אביב'))).toBe(true);
    });

  });
});
