const axios = require('axios');
const xml2js = require('xml2js');
const { withCache } = require('./cache.service');
const { createAxiosConfig } = require('../utils/axios.util');
const { processYnetItems } = require('../utils/data.util');
const { API_ENDPOINTS, CACHE_TTL } = require('../config/constants');

// Ynet data fetching
const fetchYnetData = withCache('ynet', CACHE_TTL.SHORT, async () => {
  const response = await axios.get(API_ENDPOINTS.YNET_RSS, createAxiosConfig());

  const parser = new xml2js.Parser();
  const result = await parser.parseStringPromise(response.data);
  
  const items = result.rss.channel[0].item || [];
  return processYnetItems(items);
});

module.exports = {
  fetchYnetData
};
