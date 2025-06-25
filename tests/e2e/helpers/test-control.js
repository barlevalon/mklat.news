/**
 * Test control helper for manipulating server state during e2e tests
 */
export class TestControl {
  constructor(page) {
    this.page = page;
    this.baseUrl = 'http://localhost:3001';
  }

  async setActiveAlerts(alerts) {
    const response = await this.page.request.post(`${this.baseUrl}/test/set-active-alerts`, {
      data: { alerts }
    });
    if (!response.ok()) {
      throw new Error(`Failed to set active alerts: ${response.status()}`);
    }
  }

  async setHistoricalAlerts(alerts) {
    const response = await this.page.request.post(`${this.baseUrl}/test/set-historical-alerts`, {
      data: { alerts }
    });
    if (!response.ok()) {
      throw new Error(`Failed to set historical alerts: ${response.status()}`);
    }
  }

  async setNews(items) {
    const response = await this.page.request.post(`${this.baseUrl}/test/set-news`, {
      data: { items }
    });
    if (!response.ok()) {
      throw new Error(`Failed to set news: ${response.status()}`);
    }
  }

  async setAlertAreas(areas) {
    const response = await this.page.request.post(`${this.baseUrl}/test/set-alert-areas`, {
      data: { areas }
    });
    if (!response.ok()) {
      throw new Error(`Failed to set alert areas: ${response.status()}`);
    }
  }

  async clearAllAlerts() {
    await this.setActiveAlerts([]);
    await this.setHistoricalAlerts([]);
    // Reset to default alert areas
    await this.setAlertAreas([
      'תל אביב - יפו',
      'ירושלים',
      'חיפה',
      'רמת גן',
      'גבעתיים',
      'גדרה',
      'אזור תעשייה גדרה'
    ]);
  }
}