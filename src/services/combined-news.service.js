const axios = require('axios');
const xml2js = require('xml2js');
const { withCache } = require('./cache.service');
const { createAxiosConfig } = require('../utils/axios.util');
const { API_ENDPOINTS, CACHE_TTL, LIMITS } = require('../config/constants');

// Track when we first see each item
const seenItems = new Map();

// Fetch and parse a single RSS feed
async function fetchSingleFeed(url, source) {
  const response = await axios.get(url, createAxiosConfig());
  const parser = new xml2js.Parser();
  const result = await parser.parseStringPromise(response.data);
  
  const items = result.rss.channel[0].item || [];
  return items.slice(0, LIMITS.YNET_ITEMS).map(item => {
    let pubDate = item.pubDate[0];
    
    // Fix Walla's timezone issue - they provide GMT times that should be interpreted as local Israel time
    if (source === 'Walla' && pubDate.includes('GMT')) {
      // Remove GMT and parse as local time
      const dateStr = pubDate.replace(' GMT', '');
      const localDate = new Date(dateStr + ' GMT+0300');
      pubDate = localDate.toISOString();
    }
    
    return {
      title: item.title[0].replace(/<!\[CDATA\[(.*?)\]\]>/g, '$1'),
      link: item.link[0],
      pubDate: pubDate,
      description: item.description ? 
        item.description[0].replace(/<!\[CDATA\[(.*?)\]\]>/g, '$1').replace(/<[^>]*>/g, '') : '',
      source: source
    };
  });
}

// Combined news data fetching from all sources
const fetchCombinedNewsData = withCache('combined-news', CACHE_TTL.SHORT, async () => {
  try {
    // Fetch from all four sources in parallel
    const [ynetItems, maarivItems, wallaItems, haaretzItems] = await Promise.all([
      fetchSingleFeed(API_ENDPOINTS.YNET_RSS, 'Ynet'),
      fetchSingleFeed(API_ENDPOINTS.MAARIV_RSS, 'Maariv'),
      fetchSingleFeed(API_ENDPOINTS.WALLA_RSS, 'Walla'),
      fetchSingleFeed(API_ENDPOINTS.HAARETZ_RSS, 'Haaretz')
    ]);
    
    // Combine all items with source balance (take max 3 from each source for better diversity)
    const balancedItems = [
      ...ynetItems.slice(0, 3),
      ...maarivItems.slice(0, 3), 
      ...wallaItems.slice(0, 3),
      ...haaretzItems.slice(0, 3)
    ];
    
    // Sort by publication date (newest first)
    balancedItems.sort((a, b) => new Date(b.pubDate) - new Date(a.pubDate));
    
    // Take top items (limit total)
    const processedItems = balancedItems.slice(0, LIMITS.YNET_ITEMS);
    
    if (processedItems.length > 0) {
      const latestItem = processedItems[0];
      const itemKey = latestItem.link;
      const now = new Date();
      
      // Check if this is a new item we haven't seen before
      if (!seenItems.has(itemKey)) {
        seenItems.set(itemKey, now);
        console.log(`New item: [${latestItem.source}] ${latestItem.title}`);
      }
    }
    
    return processedItems;
  } catch (error) {
    console.error('Error fetching combined news:', error.message);
    
    // Fallback to individual sources if combined fetch fails
    try {
      return await fetchSingleFeed(API_ENDPOINTS.YNET_RSS, 'Ynet');
    } catch (fallbackError) {
      console.error('Ynet fallback also failed:', fallbackError.message);
      return [];
    }
  }
});

module.exports = {
  fetchCombinedNewsData
};
