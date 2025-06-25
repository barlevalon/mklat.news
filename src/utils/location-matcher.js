/**
 * Location matching utilities
 * Handles exact matching of location names from the OREF API
 */

/**
 * Filters alerts by selected locations using exact matching
 * @param {Array} alerts - Array of alert objects with 'area' property
 * @param {Set} selectedLocations - Set of selected location names
 * @returns {Array} Filtered alerts that match selected locations
 */
function filterAlertsByLocation(alerts, selectedLocations) {
    if (selectedLocations.size === 0) {
        return alerts; // Show all alerts if no locations selected
    }

    return alerts.filter(alert => {
        const alertArea = alert.area;
        
        // Exact match only - locations from the API are specific and complete
        return selectedLocations.has(alertArea);
    });
}

/**
 * Checks if an alert location matches a user location
 * @param {string|Object} alertLocation - Alert location (string or object with area property)
 * @param {string} userLocation - User's selected location
 * @returns {boolean} True if locations match exactly
 */
function isLocationMatch(alertLocation, userLocation) {
    if (!alertLocation || !userLocation) return false;

    // Extract area if alertLocation is an object
    const alertArea = typeof alertLocation === 'string' ? alertLocation : alertLocation.area;
    if (!alertArea) return false;

    // Exact match only - locations are specific items from the API
    return alertArea === userLocation;
}

export {
    filterAlertsByLocation,
    isLocationMatch
};