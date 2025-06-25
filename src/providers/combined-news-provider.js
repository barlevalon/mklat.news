import { NewsProvider } from './news-provider.interface.js';
import { fetchCombinedNewsData } from '../services/combined-news.service.js';

/**
 * Combined news provider that aggregates from multiple Israeli news sources
 */
export class CombinedNewsProvider extends NewsProvider {
  async fetchNews() {
    return fetchCombinedNewsData();
  }
}