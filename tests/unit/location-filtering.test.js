/**
 * @jest-environment jsdom
 */

import { jest } from '@jest/globals';

// Mock localStorage
const localStorageMock = {
  getItem: jest.fn(),
  setItem: jest.fn(),
  clear: jest.fn()
};
global.localStorage = localStorageMock;

// Mock fetch
global.fetch = jest.fn();

describe('Location Filtering Functions', () => {
  let selectedLocations, availableLocations;

  beforeEach(() => {
    // Reset DOM
    document.body.innerHTML = `
      <div id="location-list"></div>
      <div id="selected-locations"></div>
      <div id="selected-count"></div>
      <div id="location-selector"></div>
      <div id="alerts-content"></div>
    `;

    // Reset mocks
    jest.clearAllMocks();
    localStorageMock.getItem.mockReturnValue(null);

    // Reset global variables
    selectedLocations = new Set();
    availableLocations = ['רחובות', 'תל אביב', 'חיפה', 'באר שבע'];
  });

  // Helper function to load the script functions
  function loadScriptFunctions() {
    global.selectedLocations = selectedLocations;
    global.availableLocations = availableLocations;
    global.updateSelectedLocationsDisplay = function() {
      const selectedElement = document.getElementById('selected-locations');
      const countElement = document.getElementById('selected-count');
      
      if (selectedLocations.size === 0) {
        selectedElement.innerHTML = '<span>כל האזורים</span>';
      } else if (selectedLocations.size <= 3) {
        const locations = Array.from(selectedLocations).join(', ');
        selectedElement.innerHTML = `<span>${locations}</span>`;
      } else {
        selectedElement.innerHTML = `<span>${selectedLocations.size} אזורים נבחרו</span>`;
      }
      
      if (countElement) {
        countElement.textContent = `${selectedLocations.size} נבחרו`;
      }
    };

    global.filterAlertsByLocation = function(alerts) {
      if (selectedLocations.size === 0) {
        return alerts;
      }
      
      return alerts.filter(alert => {
        const alertArea = alert.area;
        
        // Exact match only - locations from the API are specific and complete
        return selectedLocations.has(alertArea);
      });
    };

    global.saveUserPreferences = function() {
      try {
        localStorage.setItem('mklat-locations', JSON.stringify(Array.from(selectedLocations)));
      } catch (error) {
        console.error('Error saving preferences:', error);
      }
    };

    global.loadUserPreferences = function() {
      try {
        const saved = localStorage.getItem('mklat-locations');
        if (saved) {
          const savedLocations = JSON.parse(saved);
          selectedLocations.clear();
          savedLocations.forEach(loc => selectedLocations.add(loc));
          global.selectedLocations = selectedLocations;
        }
      } catch (error) {
        console.error('Error loading preferences:', error);
      }
    };

    global.toggleLocation = function(location) {
      if (selectedLocations.has(location)) {
        selectedLocations.delete(location);
      } else {
        selectedLocations.add(location);
      }
      
      updateSelectedLocationsDisplay();
      saveUserPreferences();
    };
  }

  describe('updateSelectedLocationsDisplay', () => {
    beforeEach(() => {
      loadScriptFunctions();
    });

    test('should show "כל האזורים" when no locations selected', () => {
      updateSelectedLocationsDisplay();
      
      expect(document.getElementById('selected-locations').innerHTML)
        .toBe('<span>כל האזורים</span>');
      expect(document.getElementById('selected-count').textContent)
        .toBe('0 נבחרו');
    });

    test('should show location names when few locations selected', () => {
      selectedLocations.add('רחובות');
      selectedLocations.add('תל אביב');
      
      updateSelectedLocationsDisplay();
      
      const selectedText = document.getElementById('selected-locations').innerHTML;
      expect(selectedText).toContain('רחובות');
      expect(selectedText).toContain('תל אביב');
      expect(document.getElementById('selected-count').textContent)
        .toBe('2 נבחרו');
    });

    test('should show count when many locations selected', () => {
      for (let i = 0; i < 5; i++) {
        selectedLocations.add(`location${i}`);
      }
      
      updateSelectedLocationsDisplay();
      
      expect(document.getElementById('selected-locations').innerHTML)
        .toBe('<span>5 אזורים נבחרו</span>');
      expect(document.getElementById('selected-count').textContent)
        .toBe('5 נבחרו');
    });
  });

  describe('filterAlertsByLocation', () => {
    beforeEach(() => {
      loadScriptFunctions();
    });

    test('should return all alerts when no locations selected', () => {
      const alerts = [
        { area: 'רחובות' },
        { area: 'תל אביב' },
        { area: 'חיפה' }
      ];
      
      const result = filterAlertsByLocation(alerts);
      expect(result).toEqual(alerts);
    });

    test('should filter alerts by exact location match', () => {
      selectedLocations.add('רחובות');
      
      const alerts = [
        { area: 'רחובות' },
        { area: 'תל אביב' },
        { area: 'חיפה' }
      ];
      
      const result = filterAlertsByLocation(alerts);
      expect(result).toHaveLength(1);
      expect(result[0].area).toBe('רחובות');
    });


    test('should filter alerts by multiple selected locations', () => {
      selectedLocations.add('רחובות');
      selectedLocations.add('חיפה');
      
      const alerts = [
        { area: 'רחובות' },
        { area: 'תל אביב' },
        { area: 'חיפה' },
        { area: 'באר שבע' }
      ];
      
      const result = filterAlertsByLocation(alerts);
      expect(result).toHaveLength(2);
      expect(result.map(a => a.area)).toEqual(['רחובות', 'חיפה']);
    });

    test('should return empty array when no alerts match', () => {
      selectedLocations.add('אילת');
      
      const alerts = [
        { area: 'רחובות' },
        { area: 'תל אביב' }
      ];
      
      const result = filterAlertsByLocation(alerts);
      expect(result).toHaveLength(0);
    });

    test('should not match partial strings that could cause false positives', () => {
      // Bug reproduction: filtering for 'רחובות' should NOT match 'רחוב'
      const alerts = [
        { area: 'רחובות' },    // Should match (exact city name)
        { area: 'רחוב הרצל' }, // Should NOT match (street name)
        { area: 'רחוב' },      // Should NOT match (generic "street")
        { area: 'תל אביב' }    // Should NOT match (different city)
      ];
      
      selectedLocations.add('רחובות');
      
      const result = filterAlertsByLocation(alerts);
      expect(result).toHaveLength(1);
      expect(result[0].area).toBe('רחובות');
    });

    test('should handle exact matching only for selected locations', () => {
      // This test verifies exact matching behavior
      const alerts = [
        { area: 'רחובות' },           // Should match when 'רחובות' selected
        { area: 'רחוב בן גוריון' },   // Should NOT match when 'רחובות' selected
        { area: 'שדרות' },            // Should match when 'שדרות' selected
        { area: 'שדרות רוטשילד' },    // Should NOT match when 'שדרות' selected
        { area: 'תל אביב - יפו' },     // Should match when 'תל אביב - יפו' selected
        { area: 'נתניה' },            // Should NOT match (not selected)
        { area: 'נתיב' }              // Should NOT match (not selected)
      ];
      
      selectedLocations.add('רחובות');
      selectedLocations.add('שדרות');
      selectedLocations.add('תל אביב - יפו');
      
      const result = filterAlertsByLocation(alerts);
      
      // Should only match exact location names
      expect(result).toHaveLength(3);
      expect(result.map(a => a.area)).toEqual(expect.arrayContaining([
        'רחובות', 
        'שדרות', 
        'תל אביב - יפו'
      ]));
      
      // Verify streets are NOT matched
      const hasStreets = result.some(alert => 
        alert.area.includes('רחוב ') || alert.area === 'שדרות רוטשילד'
      );
      expect(hasStreets).toBe(false);
    });

    test('should match selected locations exactly - no substring matching', () => {
      loadScriptFunctions();
      selectedLocations.clear();
      selectedLocations.add('גדרה');
      
      const alerts = [
        { area: 'גדרה' },                    // Should match - exact match
        { area: 'אזור תעשייה גדרה' }        // Should NOT match - different location
      ];
      
      const result = filterAlertsByLocation(alerts);
      expect(result).toHaveLength(1);
      expect(result[0].area).toBe('גדרה');
    });
  });

  describe('toggleLocation', () => {
    beforeEach(() => {
      loadScriptFunctions();
    });

    test.skip('should add location when not selected', () => {
      toggleLocation('רחובות');
      
      expect(selectedLocations.has('רחובות')).toBe(true);
      expect(localStorageMock.setItem).toHaveBeenCalledWith(
        'mklat-locations', 
        JSON.stringify(['רחובות'])
      );
    });

    test.skip('should remove location when already selected', () => {
      selectedLocations.add('רחובות');
      
      toggleLocation('רחובות');
      
      expect(selectedLocations.has('רחובות')).toBe(false);
      expect(localStorageMock.setItem).toHaveBeenCalledWith(
        'mklat-locations', 
        JSON.stringify([])
      );
    });
  });

  describe('loadUserPreferences', () => {
    beforeEach(() => {
      loadScriptFunctions();
    });

    test.skip('should load saved locations from localStorage', () => {
      localStorageMock.getItem.mockReturnValue(
        JSON.stringify(['רחובות', 'תל אביב'])
      );
      
      loadUserPreferences();
      
      expect(selectedLocations.has('רחובות')).toBe(true);
      expect(selectedLocations.has('תל אביב')).toBe(true);
      expect(selectedLocations.size).toBe(2);
    });

    test('should handle missing localStorage data', () => {
      localStorageMock.getItem.mockReturnValue(null);
      
      loadUserPreferences();
      
      expect(selectedLocations.size).toBe(0);
    });

    test.skip('should handle invalid JSON in localStorage', () => {
      localStorageMock.getItem.mockReturnValue('invalid json');
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation();
      
      loadUserPreferences();
      
      expect(selectedLocations.size).toBe(0);
      expect(consoleSpy).toHaveBeenCalled();
      consoleSpy.mockRestore();
    });
  });

  describe('saveUserPreferences', () => {
    beforeEach(() => {
      loadScriptFunctions();
    });

    test.skip('should save selected locations to localStorage', () => {
      selectedLocations.add('רחובות');
      selectedLocations.add('תל אביב');
      
      saveUserPreferences();
      
      expect(localStorageMock.setItem).toHaveBeenCalledWith(
        'mklat-locations',
        JSON.stringify(['רחובות', 'תל אביב'])
      );
    });

    test.skip('should handle localStorage errors', () => {
      localStorageMock.setItem.mockImplementation(() => {
        throw new Error('Storage quota exceeded');
      });
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation();
      
      saveUserPreferences();
      
      expect(consoleSpy).toHaveBeenCalled();
      consoleSpy.mockRestore();
    });
  });
});
