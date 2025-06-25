import { LIMITS } from '../config/constants.js';

// Utility for efficient data comparison
function hasDataChanged(newData, oldData) {
  return JSON.stringify(newData) !== JSON.stringify(oldData);
}

// Common data processing utilities
function processAlertAreasData(data) {
  return [...new Set(
    data
      .filter(item => item && item.label && item.label.trim())
      .map(item => item.label.trim())
  )].sort();
}

function processYnetItems(items) {
  return items.slice(0, LIMITS.YNET_ITEMS).map(item => ({
    title: item.title[0],
    link: item.link[0],
    pubDate: item.pubDate[0],
    description: item.description ? item.description[0].replace(/<[^>]*>/g, '') : ''
  }));
}

export {
  hasDataChanged,
  processAlertAreasData,
  processYnetItems
};
