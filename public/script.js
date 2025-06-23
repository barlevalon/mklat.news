
let newsData = [];
let alertsData = [];
let availableLocations = [];
let selectedLocations = new Set();

// WebSocket connection state
let ws = null;
let wsReconnectAttempts = 0;
let maxReconnectAttempts = 5;
let fallbackPolling = null;

// Alert state machine - Pure functions with no side effects


const AlertStateMachine = {
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

        // If it's a clearance (contains "האירוע הסתיים") and within 5 minutes
        if (mostRecent.description?.includes('האירוע הסתיים') && 
            this.isWithinMinutes(mostRecent.alertDate, 5, currentTime)) {
            return this.states.JUST_CLEARED;
        }

        // Otherwise, we're waiting for clearance
        return this.states.WAITING_CLEAR;
    },

    isLocationMatch(alertLocation, userLocation) {
        if (!alertLocation || !userLocation) return false;

        // Extract area if alertLocation is an object
        const alertArea = typeof alertLocation === 'string' ? alertLocation : alertLocation.area;
        if (!alertArea) return false;

        if (alertArea === userLocation) return true;

        // Handle municipal variants
        const baseLocation = userLocation.replace(/\s*-\s*.*$/, '').trim();
        const alertBase = alertArea.replace(/\s*-\s*.*$/, '').trim();

        return alertBase === baseLocation;
    },

    isWithinMinutes(dateStr, minutes, currentTime = new Date()) {
        if (!dateStr) return false;
        const date = new Date(dateStr);
        const diffMs = currentTime - date;
        return diffMs < (minutes * 60 * 1000);
    }
};

// State Manager - Manages state and notifies observers
class StateManager {
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

// Create global state manager instance
const stateManager = new StateManager();

// Subscribe to state changes and update UI
stateManager.subscribe((oldState, newState) => {
    updateStateDisplay();
});

// Keep these for backward compatibility
let currentAlertState = stateManager.getState();
let alertStartTime = stateManager.getAlertStartTime();
let clearanceTime = stateManager.getClearanceTime();
let stateTimer = null;

// Real-time updates with WebSocket and fallback polling
function initializeRealTimeUpdates() {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const wsUrl = `${protocol}//${window.location.host}`;

    console.log('Attempting to connect to WebSocket:', wsUrl);
    connectWebSocket(wsUrl);
}

function connectWebSocket(wsUrl) {
    try {
        ws = new WebSocket(wsUrl);

        // Expose for testing
        if (typeof window !== 'undefined') {
            window.ws = ws;
            window.wsReconnectAttempts = wsReconnectAttempts;
        }

        ws.onopen = function() {
            console.log('WebSocket connected - real-time updates active');
            wsReconnectAttempts = 0;

            // Stop fallback polling if it's running
            if (fallbackPolling) {
                clearInterval(fallbackPolling);
                fallbackPolling = null;
            }

            // Update connection status
            updateWebSocketStatus('connected');
        };

        ws.onmessage = function(event) {
            try {
                const message = JSON.parse(event.data);
                handleWebSocketMessage(message);
            } catch (error) {
                console.error('Error parsing WebSocket message:', error);
            }
        };

        ws.onclose = function() {
            console.log('WebSocket connection closed');
            updateWebSocketStatus('disconnected');
            handleWebSocketReconnect(wsUrl);
        };

        ws.onerror = function(error) {
            console.error('WebSocket error:', error);
            updateWebSocketStatus('error');
        };

    } catch (error) {
        console.error('Failed to create WebSocket connection:', error);
        startFallbackPolling();
    }
}

function handleWebSocketMessage(message) {
    switch (message.type) {
        case 'initial':
            // Handle initial data load
            if (message.data.ynet) {
                newsData = message.data.ynet;
                renderNews(newsData);
                animateUpdate('news-panel');
            }
            if (message.data.alerts) {
                alertsData = message.data.alerts;
                renderAlerts(alertsData);
                animateUpdate('alerts-panel');
            }
            if (message.data.locations) {
                availableLocations = message.data.locations;
                renderLocationList();
            }
            break;

        case 'ynet':
            newsData = message.data;
            renderNews(newsData);
            animateUpdate('news-panel');
            break;

        case 'alerts':
            alertsData = message.data;
            renderAlerts(alertsData);
            animateUpdate('alerts-panel');
            break;

        default:
            console.log('Unknown WebSocket message type:', message.type);
    }
}

function handleWebSocketReconnect(wsUrl) {
    if (wsReconnectAttempts < maxReconnectAttempts) {
        wsReconnectAttempts++;

        // Update global for testing
        if (typeof window !== 'undefined') {
            window.wsReconnectAttempts = wsReconnectAttempts;
        }

        const delay = Math.min(1000 * Math.pow(2, wsReconnectAttempts), 30000); // Exponential backoff, max 30s

        console.log(`Attempting to reconnect WebSocket in ${delay}ms (attempt ${wsReconnectAttempts}/${maxReconnectAttempts})`);

        setTimeout(() => {
            connectWebSocket(wsUrl);
        }, delay);
    } else {
        console.log('Max WebSocket reconnect attempts reached, falling back to polling');
        startFallbackPolling();
    }
}

function startFallbackPolling() {
    if (fallbackPolling) return; // Already polling


    updateWebSocketStatus('polling');

    // Initial data fetch
    fetchAllData();

    // Poll every 3 seconds as fallback
    fallbackPolling = setInterval(fetchAllData, 3000);
}

function updateWebSocketStatus(status) {
    // Use existing connection-status element
    const statusElement = document.getElementById('connection-status');

    if (statusElement) {
        switch (status) {
            case 'connected':
            case 'polling':
                // Hide status when connection is working (either WebSocket or polling)
                statusElement.style.display = 'none';
                break;
            case 'disconnected':
            case 'error':
                // Only show when there's an actual problem
                statusElement.textContent = '⚠️ אין חיבור לשרת';
                statusElement.className = 'status-error';
                statusElement.style.display = 'block';
                break;
        }
    }
}

// Expose WebSocket for testing
if (typeof window !== 'undefined') {
    window.ws = null;
    window.wsReconnectAttempts = 0;
    window.handleWebSocketMessage = handleWebSocketMessage;
    window.initializeRealTimeUpdates = initializeRealTimeUpdates;
    window.handleWebSocketReconnect = handleWebSocketReconnect;
}

// Initialize the application
if (typeof document !== 'undefined') {
    document.addEventListener('DOMContentLoaded', function() {
    console.log('War Room initialized');
    loadUserPreferences();
    fetchLocations();

    // Initialize state display
    updateStateDisplay();

    // Initialize WebSocket connection with fallback
    initializeRealTimeUpdates();

    // Setup location search
    setupLocationSearch();

    // Setup close button for location selector
    const closeButton = document.querySelector('.close-btn');
    if (closeButton) {
        closeButton.addEventListener('click', function() {
            const selector = document.getElementById('location-selector');
            selector.classList.remove('show');
        });
    }
});
}

async function fetchAllData() {
    await Promise.all([fetchNews(), fetchAlerts()]);
    updateConnectionStatus(true);
}

async function fetchNews() {
    try {
        const response = await fetch('/api/ynet');
        if (!response.ok) throw new Error('Network response was not ok');

        const data = await response.json();
        newsData = data;

        renderNews(data);
        animateUpdate('news-panel');

    } catch (error) {
        console.error('Error fetching news:', error);
        updateConnectionStatus(false);
        renderError('news-content', 'שגיאה בטעינת חדשות');
    }
}

async function fetchAlerts() {
    try {
        const response = await fetch('/api/alerts');
        if (!response.ok) throw new Error('Network response was not ok');

        const data = await response.json();
        alertsData = data;

        renderAlerts(data);
        animateUpdate('alerts-panel');

    } catch (error) {
        console.error('Error fetching alerts:', error);
        updateConnectionStatus(false);
        renderError('alerts-content', 'שגיאה בטעינת התרעות פיקוד העורף');
    }
}

function getSourceIcon(source) {
    const faviconUrls = {
        'Ynet': 'https://www.google.com/s2/favicons?domain=ynet.co.il&sz=16',
        'Maariv': 'https://www.google.com/s2/favicons?domain=maariv.co.il&sz=16',
        'Walla': 'https://www.google.com/s2/favicons?domain=walla.co.il&sz=16',
        'Haaretz': 'https://www.google.com/s2/favicons?domain=haaretz.co.il&sz=16'
    };

    const url = faviconUrls[source];
    if (url) {
        return `<img src="${url}" alt="${source}" class="source-favicon">`;
    }
    return '';
}

function renderNews(news) {
    const newsContent = document.getElementById('news-content');

    if (!news || news.length === 0) {
        newsContent.innerHTML = '<div class="no-alerts">אין מבזקים חדשים</div>';
        return;
    }

    // Filter news based on alert state and location
    let filteredNews = news;
    const primaryLocation = Array.from(selectedLocations)[0];

    if (primaryLocation && currentAlertState === AlertStateMachine.states.ALL_CLEAR) {
        // When no alert, only show news mentioning the user's location
        filteredNews = news.filter(item => {
            const text = (item.title + ' ' + (item.description || '')).toLowerCase();
            return text.includes(primaryLocation.toLowerCase());
        });
    } else if (currentAlertState === AlertStateMachine.states.RED_ALERT || currentAlertState === AlertStateMachine.states.WAITING_CLEAR) {
        // During alert, prioritize alert-related news
        const alertKeywords = ['התרעה', 'התרעות', 'טיל', 'טילים', 'יירוט', 'יירוטים', 'רקטה', 'רקטות'];
        filteredNews = news.sort((a, b) => {
            const aText = (a.title + ' ' + (a.description || '')).toLowerCase();
            const bText = (b.title + ' ' + (b.description || '')).toLowerCase();
            const aHasKeyword = alertKeywords.some(keyword => aText.includes(keyword));
            const bHasKeyword = alertKeywords.some(keyword => bText.includes(keyword));

            if (aHasKeyword && !bHasKeyword) return -1;
            if (!aHasKeyword && bHasKeyword) return 1;
            return 0;
        });
    }

    // If no relevant news after filtering, show all news
    if (filteredNews.length === 0) {
        filteredNews = news;
    }

    const newsHtml = filteredNews.map(item => `
        <div class="news-item">
            <div class="news-header">
                <h3>${escapeHtml(item.title)}</h3>
                <span class="news-source" title="${item.source || 'Ynet'}">${getSourceIcon(item.source || 'Ynet')} ${item.source || 'Ynet'}</span>
            </div>
            ${item.description ? `<p>${escapeHtml(item.description.substring(0, 200))}...</p>` : ''}
            <div class="meta">
                <span>${formatDate(item.pubDate)}</span>
                <a href="${item.link}" target="_blank" rel="noopener">קרא עוד ↗</a>
            </div>
        </div>
    `).join('');

    newsContent.innerHTML = newsHtml;
}

function renderAlerts(alertsData) {
    const alertsContent = document.getElementById('alerts-content');

    // Handle new structure with active and historical alerts
    const activeAlerts = alertsData?.active || [];
    const historicalAlerts = alertsData?.history || [];

    // Process active alerts (from current API)
    let processedActiveAlerts = [];
    if (Array.isArray(activeAlerts)) {
        if (activeAlerts.length > 0 && typeof activeAlerts[0] === 'string') {
            processedActiveAlerts = activeAlerts.map(alert => ({
                area: alert,
                time: new Date().toISOString(),
                isRecent: true,
                isActive: true,
                description: 'התרעה פעילה'
            }));
        } else {
            processedActiveAlerts = activeAlerts.map(alert => ({
                area: alert.data || alert.area || alert.title || alert,
                time: alert.alertDate || alert.time || new Date().toISOString(),
                isRecent: isRecentAlert(alert.alertDate || alert.time),
                isActive: true,
                description: alert.description || 'התרעה פעילה'
            }));
        }
    }

    // Process historical alerts (already in correct format)
    const processedHistoricalAlerts = historicalAlerts || [];

    // Filter active alerts by location
    const filteredActiveAlerts = filterAlertsByLocation(processedActiveAlerts);

    // Show active alerts status only if there are active alerts
    let html = '';
    if (filteredActiveAlerts.length > 0) {
        html += `<div class="active-alerts-status">🚨 ${filteredActiveAlerts.length} התרעות פעילות</div>`;
    }

    // Show historical alerts if available
    if (processedHistoricalAlerts.length > 0) {
        // Combine and sort all alerts
        const allAlerts = [...processedActiveAlerts, ...processedHistoricalAlerts];
        allAlerts.sort((a, b) => new Date(b.time) - new Date(a.time));

        // Filter all alerts based on selected locations
        const filteredAllAlerts = filterAlertsByLocation(allAlerts);

        if (filteredAllAlerts.length > 0) {
            const alertsHtml = filteredAllAlerts.map(alert => {
                const isWarning = alert.description && alert.description.includes('בדקות הקרובות צפויות להתקבל התרעות');
                const alertClass = isWarning ? 'warning' : (alert.isActive ? 'active' : 'historical');
                const icon = isWarning ? '⚠️' : (alert.isActive ? '🚨' : '');
                
                return `
                <div class="alert-item ${alert.isRecent ? 'recent' : ''} ${alertClass}">
                    <h3>${icon} ${escapeHtml(alert.description || 'התרעה')}</h3>
                    <div class="alert-location">${escapeHtml(alert.area)}</div>
                    <div class="time">${formatDate(alert.time)}</div>
                </div>
            `}).join('');

            html += alertsHtml;
        }
    } else if (filteredActiveAlerts.length > 0) {
        // Only show active alerts if no historical data
        const alertsHtml = filteredActiveAlerts.map(alert => {
            const isWarning = alert.description && alert.description.includes('בדקות הקרובות צפויות להתקבל התרעות');
            const alertClass = isWarning ? 'warning' : (alert.isActive ? 'active' : 'historical');
            const icon = isWarning ? '⚠️' : (alert.isActive ? '🚨' : '📍');
            
            return `
            <div class="alert-item ${alert.isRecent ? 'recent' : ''} ${alertClass}">
                <h3>${icon} ${escapeHtml(alert.area)}</h3>
                <div class="alert-description">${escapeHtml(alert.description || 'התרעה')}</div>
                <div class="time">${formatDate(alert.time)}</div>
            </div>
        `}).join('');

        html += alertsHtml;
    }

    // Show "no alerts" message only if there are no alerts at all
    if (html === '') {
        if (selectedLocations.size > 0) {
            html = '<div class="no-alerts">✅ אין התרעות באזורים הנבחרים</div>';
        } else {
            html = '<div class="no-alerts">✅ אין התרעות</div>';
        }
    }

    alertsContent.innerHTML = html;

    // Update alert state machine
    updateAlertState(processedActiveAlerts);

    // Update mobile summary when alerts data changes
    updateAlertsSummary();

    // Check if should auto-collapse on mobile
    setTimeout(checkAutoCollapse, 100);
}

function renderError(elementId, message) {
    const element = document.getElementById(elementId);
    element.innerHTML = `<div class="error">${message}</div>`;
}

function updateConnectionStatus(isConnected) {
    const statusElement = document.getElementById('connection-status');
    statusElement.textContent = isConnected ? 'מחובר' : 'לא מחובר';
    statusElement.className = isConnected ? 'status-connected' : 'status-disconnected';
}



function animateUpdate(panelId) {
    const panel = document.getElementById(panelId);
    panel.classList.add('pulse');
    setTimeout(() => panel.classList.remove('pulse'), 500);
}

function formatDate(dateString) {
    if (!dateString) return 'לא ידוע';

    try {
        const date = new Date(dateString);
        const now = new Date();
        const diffMs = now - date;
        const diffMins = Math.floor(diffMs / 60000);
        const diffHours = Math.floor(diffMs / 3600000);

        if (diffMins < 1) return 'עכשיו';
        if (diffMins < 60) return `לפני ${diffMins} דקות`;
        if (diffHours < 24) return `לפני ${diffHours} שעות`;

        return date.toLocaleDateString('he-IL', {
            day: '2-digit',
            month: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        });
    } catch (error) {
        return 'לא ידוע';
    }
}



function isRecentAlert(dateString) {
    if (!dateString) return true; // Assume recent if no date

    try {
        const alertDate = new Date(dateString);
        const now = new Date();
        const diffMs = now - alertDate;
        const diffMins = Math.floor(diffMs / 60000);

        return diffMins < 30; // Consider recent if less than 30 minutes
    } catch (error) {
        return true;
    }
}

function formatRelativeTime(date) {
    if (!date) return '';

    const now = new Date();
    const diffMs = now - date;
    const diffMins = Math.floor(diffMs / 60000);

    if (diffMins < 1) return 'כרגע';
    if (diffMins === 1) return 'לפני דקה';
    return `לפני ${diffMins} דקות`;
}

function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Handle visibility change to pause/resume updates
if (typeof document !== 'undefined') {
    document.addEventListener('visibilitychange', function() {
    if (!document.hidden) {
        fetchAllData(); // Refresh when tab becomes visible
    }
});
}

// Keyboard shortcuts
if (typeof document !== 'undefined') {
    document.addEventListener('keydown', function(e) {
    if (e.key === 'r' && (e.ctrlKey || e.metaKey)) {
        e.preventDefault();
        fetchAllData();
    }
});
}

// Location Management Functions
async function fetchLocations() {
    try {

        const response = await fetch('/api/alert-areas');
        if (!response.ok) throw new Error('Failed to fetch locations');

        availableLocations = await response.json();

        renderLocationList();
    } catch (error) {
        console.error('Error fetching locations:', error);
        document.getElementById('location-list').innerHTML =
            '<div class="error">שגיאה בטעינת רשימת האזורים</div>';
    }
}

function renderLocationList() {
    const locationList = document.getElementById('location-list');

    if (!availableLocations.length) {
        locationList.innerHTML = '<div class="loading">לא נמצאו אזורים</div>';
        return;
    }

    // Sort locations: selected first, then alphabetical
    const sortedLocations = [...availableLocations].sort((a, b) => {
        const aIsSelected = selectedLocations.has(a);
        const bIsSelected = selectedLocations.has(b);

        // Selected items come first
        if (aIsSelected && !bIsSelected) return -1;
        if (!aIsSelected && bIsSelected) return 1;

        // Within same group (selected or unselected), sort alphabetically
        return a.localeCompare(b, 'he');
    });

    const locationsHtml = sortedLocations.map((location, index) => `
        <div class="location-item ${selectedLocations.has(location) ? 'selected' : ''}" data-location="${location}">
            <input type="checkbox"
                   id="loc-${index}"
                   value="${location}"
                   ${selectedLocations.has(location) ? 'checked' : ''}
                   onchange="toggleLocation('${location.replace(/'/g, "\\'")}')">
            <label for="loc-${index}">${location}</label>
        </div>
    `).join('');

    locationList.innerHTML = locationsHtml;
    updateSelectedLocationsDisplay();
}

function toggleLocationSelector() {
    const selector = document.getElementById('location-selector');
    selector.classList.toggle('show');
    
    // If opening the selector, clear the search field
    if (selector.classList.contains('show')) {
        const searchInput = document.getElementById('location-search');
        if (searchInput) {
            searchInput.value = '';
            // Trigger input event to show all locations
            searchInput.dispatchEvent(new Event('input'));
        }
    }
}

function toggleLocation(location) {
    if (selectedLocations.has(location)) {
        selectedLocations.delete(location);
    } else {
        selectedLocations.add(location);
    }

    updateSelectedLocationsDisplay();
    saveUserPreferences();

    // Re-render alerts with new filter
    renderAlerts(alertsData);
    
    // Update state display to show/hide based on selection
    updateStateDisplay();
}

function selectAllLocations() {
    selectedLocations.clear();
    availableLocations.forEach(location => selectedLocations.add(location));
    renderLocationList();
    updateSelectedLocationsDisplay();
    saveUserPreferences();
    renderAlerts(alertsData);
    updateStateDisplay();
}

function clearAllLocations() {
    selectedLocations.clear();
    renderLocationList();
    updateSelectedLocationsDisplay();
    saveUserPreferences();
    renderAlerts(alertsData);
    updateStateDisplay();
}

function applyLocationSelection() {
    // Close the location selector
    toggleLocationSelector();

    // Save preferences and update display
    saveUserPreferences();
    updateSelectedLocationsDisplay();

    // Update primary location text
    const primaryLocation = Array.from(selectedLocations)[0];
    document.getElementById('primary-location-text').textContent = primaryLocation || 'בחר אזור';

    // Re-render alerts with new filter
    renderAlerts(alertsData);
    
    // Update state display to show/hide based on selection
    updateStateDisplay();
}

function updateSelectedLocationsDisplay() {
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
}

function setupLocationSearch() {
    const searchInput = document.getElementById('location-search');
    if (!searchInput) return;

    searchInput.addEventListener('input', function(e) {
        const searchTerm = e.target.value.toLowerCase();
        const locationItems = document.querySelectorAll('.location-item');

        locationItems.forEach(item => {
            const label = item.querySelector('label');
            if (label) {
                const locationName = label.textContent.toLowerCase();
                const location = item.getAttribute('data-location');
                const isSelected = selectedLocations.has(location);

                // Show item if:
                // 1. It's selected (always visible), OR
                // 2. It matches the search term, OR
                // 3. Search term is empty
                if (isSelected || locationName.includes(searchTerm) || searchTerm === '') {
                    item.style.display = 'flex';
                } else {
                    item.style.display = 'none';
                }
            }
        });
    });
}

function filterAlertsByLocation(alerts) {
    if (selectedLocations.size === 0) {
        return alerts; // Show all alerts if no locations selected
    }

    return alerts.filter(alert => {
        const alertArea = alert.area;

        // Check if alert area matches any selected location
        for (const selectedLocation of selectedLocations) {
            // Exact match only
            if (alertArea === selectedLocation) {
                return true;
            }

            // Only allow partial matches for legitimate cases like "תל אביב - יפו" when "תל אביב" is selected
            // This handles municipal areas with additional descriptors
            if (alertArea.includes(selectedLocation)) {
                // Must be at word boundaries and followed by legitimate municipal suffixes
                const index = alertArea.indexOf(selectedLocation);
                const beforeChar = index > 0 ? alertArea.charAt(index - 1) : '';
                const afterIndex = index + selectedLocation.length;
                const afterChar = afterIndex < alertArea.length ? alertArea.charAt(afterIndex) : '';

                // Only allow if at word boundaries and followed by municipal indicators
                const isAtWordBoundary = (beforeChar === '' || /[\s\-,]/.test(beforeChar)) &&
                                        (afterChar === '' || /[\s\-,]/.test(afterChar));

                if (isAtWordBoundary) {
                    const afterText = alertArea.substring(afterIndex).trim();
                    // Only allow municipal suffixes, not street patterns
                    const isMunicipalSuffix = /^(-\s*(יפו|אזור|מרכז|צפון|דרום|מזרח|מערב))?\s*$/.test(afterText);

                    if (isMunicipalSuffix) {
                        return true;
                    }
                }
            }
        }

        return false;
    });
}

function loadUserPreferences() {
    try {
        const saved = localStorage.getItem('mklat-locations');
        if (saved) {
            const savedLocations = JSON.parse(saved);
            selectedLocations = new Set(savedLocations);
        }
    } catch (error) {
        console.error('Error loading preferences:', error);
    }
}

function saveUserPreferences() {
    try {
        localStorage.setItem('mklat-locations', JSON.stringify(Array.from(selectedLocations)));
    } catch (error) {
        console.error('Error saving preferences:', error);
    }
}



// Mobile alerts panel collapse/expand functionality
let alertsPanelCollapsed = false;

function toggleAlertsPanel() {
    const panel = document.getElementById('alerts-panel');
    const collapseBtn = document.getElementById('alerts-collapse-btn');
    const summary = document.getElementById('alerts-summary');

    alertsPanelCollapsed = !alertsPanelCollapsed;

    if (alertsPanelCollapsed) {
        panel.classList.add('collapsed');
        collapseBtn.classList.add('collapsed');
        updateAlertsSummary();
    } else {
        panel.classList.remove('collapsed');
        collapseBtn.classList.remove('collapsed');
    }
}

function updateAlertsSummary() {
    const summaryCountElement = document.getElementById('summary-count');
    if (!summaryCountElement) return;

    let activeCount = 0;
    let totalCount = 0;

    if (alertsData && alertsData.active) {
        // Process active alerts the same way as in renderAlerts
        let processedActiveAlerts = [];
        if (Array.isArray(alertsData.active)) {
            if (alertsData.active.length > 0 && typeof alertsData.active[0] === 'string') {
                processedActiveAlerts = alertsData.active.map(alert => ({
                    area: alert,
                    time: new Date().toISOString(),
                    isRecent: true,
                    isActive: true,
                    description: 'התרעה פעילה'
                }));
            } else {
                processedActiveAlerts = alertsData.active.map(alert => ({
                    area: alert.data || alert.area || alert.title || alert,
                    time: alert.alertDate || alert.time || new Date().toISOString(),
                    isRecent: isRecentAlert(alert.alertDate || alert.time),
                    isActive: true,
                    description: alert.description || 'התרעה פעילה'
                }));
            }
        }
        
        // Filter active alerts by location
        const filteredActiveAlerts = filterAlertsByLocation(processedActiveAlerts);
        activeCount = filteredActiveAlerts.length;
    }
    
    if (alertsData && alertsData.history) {
        // Filter historical alerts by location
        const filteredHistoricalAlerts = filterAlertsByLocation(alertsData.history);
        totalCount = filteredHistoricalAlerts.length;
    }

    let summaryText;
    if (activeCount > 0) {
        summaryText = `🚨 ${activeCount} התרעות פעילות`;
    } else if (totalCount > 0) {
        summaryText = `${totalCount} התרעות בהיסטוריה`;
    } else {
        summaryText = '🟢 אין התרעות פעילות';
    }

    summaryCountElement.textContent = summaryText;
}

// Auto-collapse on mobile if no location filter is active
function checkAutoCollapse() {
    if (window.innerWidth <= 768 && selectedLocations.size === 0) {
        const panel = document.getElementById('alerts-panel');
        const collapseBtn = document.getElementById('alerts-collapse-btn');

        if (!alertsPanelCollapsed) {
            alertsPanelCollapsed = true;
            panel.classList.add('collapsed');
            collapseBtn.classList.add('collapsed');
            updateAlertsSummary();
        }
    }
}



// Global functions for HTML onclick handlers
if (typeof window !== 'undefined') {
    window.toggleLocation = toggleLocation;
    window.selectAllLocations = selectAllLocations;
    window.clearAllLocations = clearAllLocations;
    window.applyLocationSelection = applyLocationSelection;
    window.fetchNews = fetchNews;
    window.fetchAlerts = fetchAlerts;
    window.toggleAlertsPanel = toggleAlertsPanel;
}

// Data will be exposed at the end of the file

// Debug function to test alert states
if (typeof window !== 'undefined') {
    window.simulateAlert = function(state) {
    const primaryLocation = Array.from(selectedLocations)[0] || 'תל אביב';

    switch(state) {
        case 'active':
            alertsData.active = [primaryLocation, 'רחובות', 'אשדוד'];
            alertsData.history = [];
            break;
        case 'cleared':
            alertsData.active = [];
            alertsData.history = [{
                area: primaryLocation,
                description: 'האירוע הסתיים',
                alertDate: new Date().toISOString(),
                time: new Date().toISOString(),
                isActive: false,
                isRecent: true
            }];
            break;
        case 'none':
            alertsData.active = [];
            alertsData.history = [];
            break;
    }

    renderAlerts(alertsData);
};
}

// State management functions
function updateAlertState(activeAlerts) {
    // Get data from current state
    const alertHistory = alertsData?.history || [];
    const userLocations = Array.from(selectedLocations);

    // Update state using the state manager
    stateManager.updateState(activeAlerts, alertHistory, userLocations);

    // Update backward compatibility variables
    currentAlertState = stateManager.getState();
    alertStartTime = stateManager.getAlertStartTime();
    clearanceTime = stateManager.getClearanceTime();

    // Update incident scale
    updateIncidentScale(activeAlerts);

    // Handle no location case
    if (userLocations.length === 0) {
        updateLocationDisplay('בחר אזור', AlertStateMachine.states.ALL_CLEAR);
    }
}

// Removed - now handled by StateManager

function updateStateDisplay() {
    const primaryLocation = Array.from(selectedLocations)[0];
    const stateIndicator = document.getElementById('state-indicator');
    const stateInstruction = document.getElementById('state-instruction');
    const stateTimerEl = document.getElementById('state-timer');

    // Only show state indicator when exactly one location is selected
    if (selectedLocations.size !== 1) {
        stateIndicator.style.display = 'none';
        // Update primary location display
        if (selectedLocations.size === 0) {
            document.getElementById('primary-location-text').textContent = 'בחר אזור';
        } else {
            document.getElementById('primary-location-text').textContent = `${selectedLocations.size} אזורים`;
        }
        return;
    }

    // Show state indicator when exactly one location is selected
    stateIndicator.style.display = '';
    
    // Clear previous state classes
    stateIndicator.className = 'state-indicator';

    const currentState = stateManager.getState();

    switch (currentState) {
        case AlertStateMachine.states.ALL_CLEAR:
            stateIndicator.classList.add('all-clear');
            stateIndicator.innerHTML = '<span class="state-icon">●</span><span class="state-text">אין התרעות</span>';
            stateInstruction.textContent = '';
            stateTimerEl.textContent = '';
            break;

        case AlertStateMachine.states.RED_ALERT:
            stateIndicator.classList.add('red-alert');
            stateIndicator.innerHTML = '<span class="state-icon">🚨</span><span class="state-text">צבע אדום</span>';
            stateInstruction.textContent = 'היכנסו למרחב המוגן';
            updateTimer();
            break;

        case AlertStateMachine.states.WAITING_CLEAR:
            stateIndicator.classList.add('waiting-clear');
            stateIndicator.innerHTML = '<span class="state-icon">◷</span><span class="state-text">המתינו במרחב המוגן</span>';
            stateInstruction.textContent = 'ממתינים לאישור יציאה';
            updateTimer();
            break;

        case AlertStateMachine.states.JUST_CLEARED:
            stateIndicator.classList.add('just-cleared');
            stateIndicator.innerHTML = '<span class="state-icon">✅</span><span class="state-text">האירוע הסתיים</span>';
            stateInstruction.textContent = 'ניתן לצאת מהמרחב המוגן';
            stateTimerEl.textContent = `(${formatRelativeTime(clearanceTime)})`;
            break;
    }

    // Update primary location display
    document.getElementById('primary-location-text').textContent = primaryLocation || 'בחר אזור';
}

function updateTimer() {
    if (stateTimer) clearInterval(stateTimer);

    const updateTimerDisplay = () => {
        const stateTimerEl = document.getElementById('state-timer');
        if (alertStartTime) {
            const elapsed = Math.floor((new Date() - alertStartTime) / 1000);
            const minutes = Math.floor(elapsed / 60);
            const seconds = elapsed % 60;
            stateTimerEl.textContent = `(${minutes}:${seconds.toString().padStart(2, '0')})`;
        }
    };

    updateTimerDisplay();
    stateTimer = setInterval(updateTimerDisplay, 1000);
}

function updateIncidentScale(activeAlerts) {
    const scaleEl = document.getElementById('incident-scale');
    const count = activeAlerts.length;

    if (count === 0) {
        scaleEl.textContent = '';
        scaleEl.classList.remove('has-content');
    } else if (count === 1) {
        scaleEl.textContent = 'התרעה מקומית';
        scaleEl.classList.add('has-content');
    } else if (count < 10) {
        scaleEl.textContent = `גם פעיל ב: ${count - 1} ערים נוספות`;
        scaleEl.classList.add('has-content');
    } else {
        scaleEl.textContent = `⚠️ אירוע נרחב: ${count} ערים`;
        scaleEl.classList.add('has-content');
    }
}

// Use the one from AlertStateMachine
function isWithinMinutes(dateStr, minutes) {
    return AlertStateMachine.isWithinMinutes(dateStr, minutes);
}

// Use the one from AlertStateMachine
function isLocationMatch(alertLocation, userLocation) {
    return AlertStateMachine.isLocationMatch(alertLocation, userLocation);
}

function updateLocationDisplay(location, state) {
    document.getElementById('primary-location-text').textContent = location;
    // Don't directly set state - let the state manager handle it
    if (state) {
        stateManager.transitionTo(state);
    }
    updateStateDisplay();
}

// Service worker removed to avoid 404 errors
// Can be added later for offline functionality if needed

// Expose all functions and data to window for testing
if (typeof window !== 'undefined') {
    window.updateStateDisplay = updateStateDisplay;
    window.updateAlertState = updateAlertState;
    window.selectedLocations = selectedLocations;
    window.alertsData = alertsData;
    window.renderAlerts = renderAlerts;
    // Use getter to always get current value
    Object.defineProperty(window, 'currentAlertState', {
        get: function() { return stateManager.getState(); },
        set: function(value) { stateManager.transitionTo(value); }
    });
}

if (typeof window !== 'undefined') {
    window.AlertStateMachine = AlertStateMachine;
}
if (typeof window !== 'undefined') {
    window.stateManager = stateManager;
    window.isLocationMatch = isLocationMatch;
    window.isWithinMinutes = isWithinMinutes;
}

// Test helpers for controlled testing
if (typeof window !== 'undefined') {
    window.testHelpers = {
    // Set alerts data without triggering side effects
    setAlertsData(data) {
        window.alertsData = data;
    },

    // Trigger state update manually
    updateState() {
        const activeAlerts = window.alertsData?.active || [];
        const alertHistory = window.alertsData?.history || [];
        const userLocations = Array.from(window.selectedLocations);

        // Process active alerts the same way renderAlerts does
        let processedActiveAlerts = [];
        if (Array.isArray(activeAlerts)) {
            if (activeAlerts.length > 0 && typeof activeAlerts[0] === 'string') {
                processedActiveAlerts = activeAlerts;
            } else {
                processedActiveAlerts = activeAlerts.map(alert =>
                    typeof alert === 'string' ? alert : (alert.area || alert.data || alert)
                );
            }
        }

        stateManager.updateState(processedActiveAlerts, alertHistory, userLocations);
    },

    // Get current state
    getCurrentState() {
        return stateManager.getState();
    },

    // Reset state for testing
    resetState() {
        stateManager.transitionTo(AlertStateMachine.states.ALL_CLEAR);
    },

    // Set user locations
    setUserLocations(locations) {
        selectedLocations.clear();
        locations.forEach(loc => selectedLocations.add(loc));
    }
};
}

// Export for testing
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { AlertStateMachine, StateManager };
}
