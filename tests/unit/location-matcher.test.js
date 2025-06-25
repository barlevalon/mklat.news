import { filterAlertsByLocation, isLocationMatch } from '../../src/utils/location-matcher.js';

describe('Location Matcher', () => {
  describe('filterAlertsByLocation', () => {
    test('should return all alerts when no locations selected', () => {
      const alerts = [
        { area: 'רחובות' },
        { area: 'תל אביב' },
        { area: 'חיפה' }
      ];
      const selectedLocations = new Set();
      
      const result = filterAlertsByLocation(alerts, selectedLocations);
      expect(result).toEqual(alerts);
    });

    test('should filter alerts by exact location match', () => {
      const alerts = [
        { area: 'רחובות' },
        { area: 'תל אביב' },
        { area: 'חיפה' }
      ];
      const selectedLocations = new Set(['רחובות']);
      
      const result = filterAlertsByLocation(alerts, selectedLocations);
      expect(result).toHaveLength(1);
      expect(result[0].area).toBe('רחובות');
    });

    test('should match selected locations exactly - no substring matching', () => {
      const alerts = [
        { area: 'גדרה' },
        { area: 'אזור תעשייה גדרה' }
      ];
      const selectedLocations = new Set(['גדרה']);
      
      const result = filterAlertsByLocation(alerts, selectedLocations);
      expect(result).toHaveLength(1);
      expect(result[0].area).toBe('גדרה');
    });

    test('should handle multiple selected locations', () => {
      const alerts = [
        { area: 'רחובות' },
        { area: 'תל אביב' },
        { area: 'חיפה' },
        { area: 'באר שבע' }
      ];
      const selectedLocations = new Set(['רחובות', 'חיפה']);
      
      const result = filterAlertsByLocation(alerts, selectedLocations);
      expect(result).toHaveLength(2);
      expect(result.map(a => a.area)).toEqual(['רחובות', 'חיפה']);
    });

    test('should not match partial strings', () => {
      const alerts = [
        { area: 'רחובות' },
        { area: 'רחוב הרצל' },
        { area: 'שדרות' },
        { area: 'שדרות רוטשילד' }
      ];
      const selectedLocations = new Set(['רחובות', 'שדרות']);
      
      const result = filterAlertsByLocation(alerts, selectedLocations);
      expect(result).toHaveLength(2);
      expect(result.map(a => a.area)).toEqual(['רחובות', 'שדרות']);
    });
  });

  describe('isLocationMatch', () => {
    test('should match exact locations', () => {
      expect(isLocationMatch('גדרה', 'גדרה')).toBe(true);
      expect(isLocationMatch('רחובות', 'רחובות')).toBe(true);
    });

    test('should not match different locations', () => {
      expect(isLocationMatch('גדרה', 'אזור תעשייה גדרה')).toBe(false);
      expect(isLocationMatch('אזור תעשייה גדרה', 'גדרה')).toBe(false);
    });

    test('should handle object format', () => {
      expect(isLocationMatch({ area: 'גדרה' }, 'גדרה')).toBe(true);
      expect(isLocationMatch({ area: 'אזור תעשייה גדרה' }, 'גדרה')).toBe(false);
    });

    test('should handle null and undefined', () => {
      expect(isLocationMatch(null, 'גדרה')).toBe(false);
      expect(isLocationMatch('גדרה', null)).toBe(false);
      expect(isLocationMatch(undefined, undefined)).toBe(false);
    });
  });
});