import { LIMITS } from '../config/constants.js';

// Historical alerts parsing utilities
const ALERT_REGEX = /<div[^>]*class="alertInfo"[^>]*area_name="([^"]*)"[^>]*>[\s\S]*?<div class="date"><span>([^<]*)<\/span><span>([^<]*)<\/span><\/div>[\s\S]*?<div class="area">([^<]*)<\/div>/g;
const ALERT_END_MARKER = 'האירוע הסתיים';

function parseAlertDateTime(dateStr, timeStr) {
  const [day, month, year] = dateStr.split('.');
  return new Date(`${year}-${month}-${day}T${timeStr}:00`);
}

function cleanAlertDescription(description, locationName) {
  let cleanDescription = description.trim();
  
  // Remove location name from end of description if it's duplicated
  if (cleanDescription.endsWith(locationName)) {
    cleanDescription = cleanDescription.slice(0, -locationName.length).trim();
  }
  
  return cleanDescription;
}

function isRecentAlert(alertDateTime) {
  const thresholdMs = LIMITS.RECENT_ALERT_MINUTES * 60 * 1000;
  return (new Date() - alertDateTime) < thresholdMs;
}

function createAlertObject(areaName, date, time, description) {
  const locationName = areaName.trim();
  const alertDateTime = parseAlertDateTime(date, time);
  const cleanDescription = cleanAlertDescription(description, locationName);
  
  return {
    area: locationName,
    description: cleanDescription,
    alertDate: alertDateTime.toISOString(),
    time: alertDateTime.toISOString(),
    isActive: !description.includes(ALERT_END_MARKER),
    isRecent: isRecentAlert(alertDateTime)
  };
}

function parseHistoricalAlertsHTML(html) {
  const alerts = [];
  
  let match;
  while ((match = ALERT_REGEX.exec(html)) !== null) {
    const [, areaName, date, time, description] = match;
    alerts.push(createAlertObject(areaName, date, time, description));
  }
  
  // Sort by date (most recent first)
  alerts.sort((a, b) => new Date(b.alertDate) - new Date(a.alertDate));
  
  return alerts; // Return all alerts, let the caller decide how to limit/filter
}

export {
  parseHistoricalAlertsHTML
};
