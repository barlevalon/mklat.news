import { NewsProvider } from '../../../src/providers/news-provider.interface.js';

/**
 * Fake news provider for testing
 * Returns predictable, controlled data
 */
export class FakeNewsProvider extends NewsProvider {
  constructor(newsItems = []) {
    super();
    this.newsItems = newsItems.length > 0 ? newsItems : this.getDefaultNews();
  }
  
  getDefaultNews() {
    const now = new Date();
    return [
      {
        title: 'Test News Item',
        link: 'https://example.com/test',
        pubDate: now.toISOString(),
        description: 'Test news description',
        source: 'Test Source'
      }
    ];
  }

  async fetchNews() {
    return this.newsItems;
  }

  // Helper method for tests to modify news
  setNewsItems(items) {
    this.newsItems = items;
  }
}