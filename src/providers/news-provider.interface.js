/**
 * Interface for news providers
 * Implementations should provide methods to fetch news from various sources
 */
export class NewsProvider {
  /**
   * Fetch news items
   * @returns {Promise<Array>} Array of news items
   */
  async fetchNews() {
    throw new Error('fetchNews must be implemented');
  }
}