import NodeCache from 'node-cache';

// Cache for 2 seconds (aggressive polling like tzevaadom)
const cache = new NodeCache({ stdTTL: 2 });

// Generic cache wrapper
function withCache(key, ttl, fetchFn) {
  return async function(...args) {
    const cached = cache.get(key);
    if (cached) return cached;
    
    const result = await fetchFn(...args);
    cache.set(key, result, ttl);
    return result;
  };
}

export {
  cache,
  withCache
};
