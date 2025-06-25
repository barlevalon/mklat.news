/**
 * Interface for alert providers
 * Implementations should provide methods to fetch alert data from various sources
 */
export class AlertProvider {
  /**
   * Fetch currently active alerts
   * @returns {Promise<string[]>} Array of location names with active alerts
   */
  async fetchActiveAlerts() {
    throw new Error('fetchActiveAlerts must be implemented');
  }

  /**
   * Fetch historical alerts
   * @returns {Promise<Array>} Array of historical alert objects
   */
  async fetchHistoricalAlerts() {
    throw new Error('fetchHistoricalAlerts must be implemented');
  }

  /**
   * Fetch available alert areas/locations
   * @returns {Promise<string[]>} Array of location names
   */
  async fetchAlertAreas() {
    throw new Error('fetchAlertAreas must be implemented');
  }
}