import { AlertProvider } from '../../../src/providers/alert-provider.interface.js';

/**
 * Fake alert provider for testing
 * Returns predictable, controlled data
 */
export class FakeAlertProvider extends AlertProvider {
  constructor(config = {}) {
    super();
    this.activeAlerts = config.activeAlerts || [];
    this.historicalAlerts = config.historicalAlerts || [];
    this.alertAreas = config.alertAreas || [
      'תל אביב - יפו',
      'ירושלים',
      'חיפה',
      'רמת גן',
      'גבעתיים',
      'גדרה',
      'אזור תעשייה גדרה'
    ];
  }

  async fetchActiveAlerts() {
    return this.activeAlerts;
  }

  async fetchHistoricalAlerts() {
    return this.historicalAlerts;
  }

  async fetchAlertAreas() {
    return this.alertAreas;
  }

  // Helper methods for tests to modify state
  setActiveAlerts(alerts) {
    this.activeAlerts = alerts;
  }

  setHistoricalAlerts(alerts) {
    this.historicalAlerts = alerts;
  }

  setAlertAreas(areas) {
    this.alertAreas = areas;
  }
}