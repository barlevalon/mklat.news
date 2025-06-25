/**
 * Alert state machine for managing UI states
 * Handles transitions between different alert states based on active alerts and history
 */

import { isLocationMatch } from './location-matcher.js';

// Alert state machine - Pure functions with no side effects
export const AlertStateMachine = {
    states: {
        ALL_CLEAR: 'all-clear',
        ALERT_IMMINENT: 'alert-imminent',
        RED_ALERT: 'red-alert',
        WAITING_CLEAR: 'waiting-clear',
        JUST_CLEARED: 'just-cleared'
    },

    // Pure function - returns new state based on inputs
    calculateNextState(currentState, activeAlerts, alertHistory, userLocations, currentTime = new Date()) {
        const primaryLocation = userLocations[0];
        if (!primaryLocation) {
            return this.states.ALL_CLEAR;
        }

        // Check for active alerts in user's location
        const hasActiveAlert = activeAlerts.some(alert => {
            const alertArea = typeof alert === 'string' ? alert : alert.area;
            return this.isLocationMatch(alertArea, primaryLocation);
        });

        // If there's an active alert, we're in RED_ALERT
        if (hasActiveAlert) {
            return this.states.RED_ALERT;
        }

        // Look for the most recent alert/clearance for this location
        const recentHistory = alertHistory?.filter(alert =>
            this.isLocationMatch(alert.area, primaryLocation)
        ).sort((a, b) => new Date(b.alertDate) - new Date(a.alertDate));


        const mostRecent = recentHistory?.[0];
        
        if (!mostRecent) {
            // If we're in WAITING_CLEAR with no history, stay there
            if (currentState === this.states.WAITING_CLEAR) {
                return this.states.WAITING_CLEAR;
            }
            return this.states.ALL_CLEAR;
        }


        // Check if it's within the last 10 minutes
        if (!this.isWithinMinutes(mostRecent.alertDate, 10, currentTime)) {
            return this.states.ALL_CLEAR;
        }

        // Check for warning message (alert imminent)
        if (mostRecent.description?.includes('בדקות הקרובות צפויות להתקבל התרעות')) {
            return this.states.ALERT_IMMINENT;
        }

        // Check for full clearance
        if (mostRecent.description?.includes('האירוע הסתיים') && 
            this.isWithinMinutes(mostRecent.alertDate, 5, currentTime)) {
            return this.states.JUST_CLEARED;
        }

        // Check for partial clearance (can exit but stay nearby)
        if (mostRecent.description?.includes('ניתן לצאת מהמרחב המוגן')) {
            // This is still a waiting state, just with different instructions
            return this.states.WAITING_CLEAR;
        }

        // Otherwise, we're waiting for clearance
        return this.states.WAITING_CLEAR;
    },

    isLocationMatch(alertLocation, userLocation) {
        return isLocationMatch(alertLocation, userLocation);
    },

    isWithinMinutes(dateStr, minutes, currentTime = new Date()) {
        if (!dateStr) return false;
        const date = new Date(dateStr);
        const diffMs = currentTime - date;
        return diffMs < (minutes * 60 * 1000);
    }
};

// State Manager - Manages state and notifies observers
export class StateManager {
    constructor() {
        this.currentState = AlertStateMachine.states.ALL_CLEAR;
        this.alertStartTime = null;
        this.clearanceTime = null;
        this.observers = [];
        this.stateTimer = null;
    }

    updateState(activeAlerts, alertHistory, userLocations) {
        const newState = AlertStateMachine.calculateNextState(
            this.currentState,
            activeAlerts,
            alertHistory,
            userLocations
        );

        if (newState !== this.currentState) {
            this.transitionTo(newState);
        }
    }

    transitionTo(newState) {
        const oldState = this.currentState;
        this.currentState = newState;

        // Update timestamps
        switch (newState) {
            case AlertStateMachine.states.RED_ALERT:
                this.alertStartTime = new Date();
                this.clearanceTime = null;
                break;
            case AlertStateMachine.states.JUST_CLEARED:
                this.clearanceTime = new Date();
                break;
        }

        // Notify observers
        this.notifyObservers(oldState, newState);
    }

    subscribe(observer) {
        this.observers.push(observer);
    }

    notifyObservers(oldState, newState) {
        this.observers.forEach(observer => {
            try {
                observer(oldState, newState);
            } catch (error) {
                console.error('Observer error:', error);
            }
        });
    }

    getState() {
        return this.currentState;
    }

    getAlertStartTime() {
        return this.alertStartTime;
    }

    getClearanceTime() {
        return this.clearanceTime;
    }
}