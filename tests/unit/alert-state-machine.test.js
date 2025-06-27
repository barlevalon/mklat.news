import { jest } from '@jest/globals';
import { AlertStateMachine, StateManager } from '../../src/utils/alert-state-machine.js';

describe('Alert State Machine', () => {
    const states = AlertStateMachine.states;

    describe('Basic State Transitions', () => {
        test('should start in ALL_CLEAR state', () => {
            const stateManager = new StateManager();
            expect(stateManager.getState()).toBe(states.ALL_CLEAR);
        });

        test('should recognize alternative clearance message from OREF', () => {
            const stateManager = new StateManager();
            const userLocations = ['רחובות'];
            
            // Start with alert history (waiting for clearance)
            const alertHistory = [{
                area: 'רחובות',
                alertDate: new Date().toISOString(),
                description: 'ירי רקטות וטילים',
                isActive: false
            }];
            stateManager.updateState([], alertHistory, userLocations);
            expect(stateManager.getState()).toBe(states.WAITING_CLEAR);
            
            // Partial clearance message should keep us in WAITING_CLEAR
            const partialClearanceHistory = [{
                area: 'רחובות',
                alertDate: new Date().toISOString(),
                description: 'ניתן לצאת מהמרחב המוגן אך יש להישאר בקרבתו',
                isActive: false
            }];
            stateManager.updateState([], partialClearanceHistory, userLocations);
            expect(stateManager.getState()).toBe(states.WAITING_CLEAR);
            
            // Full clearance should move to JUST_CLEARED
            const fullClearanceHistory = [{
                area: 'רחובות',
                alertDate: new Date().toISOString(),
                description: 'ירי רקטות וטילים - האירוע הסתיים',
                isActive: false
            }];
            stateManager.updateState([], fullClearanceHistory, userLocations);
            expect(stateManager.getState()).toBe(states.JUST_CLEARED);
        });

        test('should transition through complete alert lifecycle', () => {
            const stateManager = new StateManager();
            const userLocations = ['תל אביב'];
            const stateChanges = [];

            stateManager.subscribe((oldState, newState) => {
                stateChanges.push({ oldState, newState });
            });

            // Initial state
            expect(stateManager.getState()).toBe(states.ALL_CLEAR);

            // Alert starts
            stateManager.updateState(['תל אביב'], [], userLocations);
            expect(stateManager.getState()).toBe(states.RED_ALERT);
            expect(stateManager.getAlertStartTime()).toBeTruthy();

            // Alert ends with history
            const alertHistory = [{
                area: 'תל אביב',
                alertDate: new Date().toISOString(),
                description: 'ירי רקטות וטילים',
                isActive: false
            }];
            stateManager.updateState([], alertHistory, userLocations);
            expect(stateManager.getState()).toBe(states.WAITING_CLEAR);

            // Clearance received
            const clearanceHistory = [{
                area: 'תל אביב',
                alertDate: new Date().toISOString(),
                description: 'ירי רקטות וטילים - האירוע הסתיים',
                isActive: false
            }];
            stateManager.updateState([], clearanceHistory, userLocations);
            expect(stateManager.getState()).toBe(states.JUST_CLEARED);
            expect(stateManager.getClearanceTime()).toBeTruthy();

            // Verify all transitions were notified
            expect(stateChanges).toHaveLength(3);
            expect(stateChanges[0].newState).toBe(states.RED_ALERT);
            expect(stateChanges[1].newState).toBe(states.WAITING_CLEAR);
            expect(stateChanges[2].newState).toBe(states.JUST_CLEARED);
        });

        test('should recognize warning messages and set ALERT_IMMINENT state', () => {
            const stateManager = new StateManager();
            const userLocations = ['תל אביב'];
            
            // Warning message should trigger ALERT_IMMINENT
            const warningHistory = [{
                area: 'תל אביב',
                alertDate: new Date().toISOString(),
                description: 'בדקות הקרובות צפויות להתקבל התרעות באזורך',
                isActive: false
            }];
            stateManager.updateState([], warningHistory, userLocations);
            expect(stateManager.getState()).toBe(states.ALERT_IMMINENT);
        });

        test('should handle no location selected', () => {
            const stateManager = new StateManager();
            
            // No user locations
            stateManager.updateState(['תל אביב'], [], []);
            
            expect(stateManager.getState()).toBe(states.ALL_CLEAR);
        });

        test('should prioritize primary location when multiple selected', () => {
            const currentState = states.ALL_CLEAR;
            const activeAlerts = ['ירושלים', 'חיפה'];
            const alertHistory = [];
            const userLocations = ['תל אביב', 'ירושלים', 'חיפה'];
            
            const nextState = AlertStateMachine.calculateNextState(
                currentState, activeAlerts, alertHistory, userLocations
            );
            
            // Should NOT trigger alert since primary location (תל אביב) has no alert
            expect(nextState).toBe(states.ALL_CLEAR);
        });
    });

    describe('Time-based State Transitions', () => {
        test('should stay in JUST_CLEARED for 5 minutes after clearance', () => {
            const fourMinutesAgo = new Date(Date.now() - 4 * 60 * 1000 - 59 * 1000); // 4:59
            const currentState = states.WAITING_CLEAR;
            const activeAlerts = [];
            const alertHistory = [{
                area: 'תל אביב',
                alertDate: fourMinutesAgo.toISOString(),
                description: 'ירי רקטות וטילים - האירוע הסתיים',
                isActive: false
            }];
            const userLocations = ['תל אביב'];
            
            const nextState = AlertStateMachine.calculateNextState(
                currentState, activeAlerts, alertHistory, userLocations
            );
            
            expect(nextState).toBe(states.JUST_CLEARED);
        });

        test('should transition to WAITING_CLEAR after 5 minutes', () => {
            const sixMinutesAgo = new Date(Date.now() - 6 * 60 * 1000);
            const currentState = states.JUST_CLEARED;
            const activeAlerts = [];
            const alertHistory = [{
                area: 'תל אביב',
                alertDate: sixMinutesAgo.toISOString(),
                description: 'ירי רקטות וטילים - האירוע הסתיים',
                isActive: false
            }];
            const userLocations = ['תל אביב'];
            
            const nextState = AlertStateMachine.calculateNextState(
                currentState, activeAlerts, alertHistory, userLocations
            );
            
            expect(nextState).toBe(states.WAITING_CLEAR);
        });

        test('should return to ALL_CLEAR after 10 minutes', () => {
            const elevenMinutesAgo = new Date(Date.now() - 11 * 60 * 1000);
            const currentState = states.WAITING_CLEAR;
            const activeAlerts = [];
            const alertHistory = [{
                area: 'תל אביב',
                alertDate: elevenMinutesAgo.toISOString(),
                description: 'ירי רקטות וטילים',
                isActive: false
            }];
            const userLocations = ['תל אביב'];
            
            const nextState = AlertStateMachine.calculateNextState(
                currentState, activeAlerts, alertHistory, userLocations
            );
            
            expect(nextState).toBe(states.ALL_CLEAR);
        });
    });

    describe('Location Matching', () => {
        test('should use exact matching for locations', () => {
            // Test exact matches
            expect(AlertStateMachine.isLocationMatch('תל אביב - יפו', 'תל אביב - יפו')).toBe(true);
            expect(AlertStateMachine.isLocationMatch('גדרה', 'גדרה')).toBe(true);
            
            // Test non-matches (no more variant matching)
            expect(AlertStateMachine.isLocationMatch('תל אביב - דרום העיר ויפו', 'תל אביב')).toBe(false);
            expect(AlertStateMachine.isLocationMatch('תל אביב - מרכז העיר', 'תל אביב')).toBe(false);
            expect(AlertStateMachine.isLocationMatch('אזור תעשייה גדרה', 'גדרה')).toBe(false);
        });

        test('should not match partial location names', () => {
            expect(AlertStateMachine.isLocationMatch('תל', 'תל אביב')).toBe(false);
            expect(AlertStateMachine.isLocationMatch('אביב', 'תל אביב')).toBe(false);
        });

        test('should handle alert object vs string formats', () => {
            const alertObject = { area: 'תל אביב' };
            const alertString = 'תל אביב';
            
            expect(AlertStateMachine.isLocationMatch(alertObject, 'תל אביב')).toBe(true);
            expect(AlertStateMachine.isLocationMatch(alertString, 'תל אביב')).toBe(true);
        });

        test('should handle null and undefined locations', () => {
            expect(AlertStateMachine.isLocationMatch(null, 'תל אביב')).toBe(false);
            expect(AlertStateMachine.isLocationMatch('תל אביב', null)).toBe(false);
            expect(AlertStateMachine.isLocationMatch(undefined, 'תל אביב')).toBe(false);
            expect(AlertStateMachine.isLocationMatch({}, 'תל אביב')).toBe(false);
        });
    });

    describe('State Manager Features', () => {
        test('should track timestamps correctly', () => {
            const stateManager = new StateManager();
            const userLocations = ['תל אביב'];
            
            // Track alert start time
            const beforeAlert = Date.now();
            stateManager.updateState(['תל אביב'], [], userLocations);
            const afterAlert = Date.now();
            
            const alertTime = stateManager.getAlertStartTime().getTime();
            expect(alertTime).toBeGreaterThanOrEqual(beforeAlert);
            expect(alertTime).toBeLessThanOrEqual(afterAlert);
            
            // Track clearance time
            const beforeClearance = Date.now();
            stateManager.updateState([], [{
                area: 'תל אביב',
                alertDate: new Date().toISOString(),
                description: 'ירי רקטות וטילים - האירוע הסתיים',
                isActive: false
            }], userLocations);
            const afterClearance = Date.now();
            
            expect(stateManager.getState()).toBe(states.JUST_CLEARED);
            const clearanceTime = stateManager.getClearanceTime().getTime();
            expect(clearanceTime).toBeGreaterThanOrEqual(beforeClearance);
            expect(clearanceTime).toBeLessThanOrEqual(afterClearance);
        });

        test('should not transition if state unchanged', () => {
            const stateManager = new StateManager();
            const userLocations = ['תל אביב'];
            const stateChanges = [];
            
            stateManager.subscribe((oldState, newState) => {
                stateChanges.push({ oldState, newState });
            });
            
            // Multiple updates with same conditions
            stateManager.updateState([], [], userLocations);
            stateManager.updateState([], [], userLocations);
            stateManager.updateState([], [], userLocations);
            
            // Should have no transitions (already in ALL_CLEAR)
            expect(stateChanges).toHaveLength(0);
        });

        test('should maintain alert time across duplicate updates', () => {
            const stateManager = new StateManager();
            const userLocations = ['חיפה'];
            
            // Set alert
            stateManager.updateState(['חיפה'], [], userLocations);
            const firstAlertTime = stateManager.getAlertStartTime();
            
            // Update with same alert (no change)
            stateManager.updateState(['חיפה'], [], userLocations);
            
            // Alert time should not change
            expect(stateManager.getAlertStartTime()).toBe(firstAlertTime);
            expect(stateManager.getState()).toBe(states.RED_ALERT);
        });

        test('should handle observer errors gracefully', () => {
            const stateManager = new StateManager();
            const goodObserverCalls = [];
            
            // Mock console.error to suppress error messages in test output
            const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
            
            // Bad observer that throws
            stateManager.subscribe(() => {
                throw new Error('Observer error');
            });
            
            // Good observer should still be called
            stateManager.subscribe((old, next) => goodObserverCalls.push({ old, next }));
            
            // Should not throw
            expect(() => {
                stateManager.updateState(['תל אביב'], [], ['תל אביב']);
            }).not.toThrow();
            
            expect(goodObserverCalls).toHaveLength(1);
            
            // Verify error was logged (but suppressed in output)
            expect(consoleErrorSpy).toHaveBeenCalledWith('Observer error:', expect.any(Error));
            
            consoleErrorSpy.mockRestore();
        });
    });
});