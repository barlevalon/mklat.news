
let newsData = [];
let alertsData = [];
let availableLocations = [];
let selectedLocations = new Set();

// WebSocket connection state
let ws = null;
let wsReconnectAttempts = 0;
let maxReconnectAttempts = 5;
let fallbackPolling = null;

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
    
    console.log('Starting fallback polling every 3 seconds');
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
                statusElement.textContent = '● בזמן אמת';
                statusElement.className = 'status-connected';
                break;
            case 'polling':
                statusElement.textContent = '◐ בדיקה';
                statusElement.className = 'status-warning';
                break;
            case 'disconnected':
            case 'error':
                statusElement.textContent = '○ לא מחובר';
                statusElement.className = 'status-error';
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
document.addEventListener('DOMContentLoaded', function() {
    console.log('War Room initialized');
    loadUserPreferences();
    fetchLocations();
    
    // Initialize WebSocket connection with fallback
    initializeRealTimeUpdates();
    
    // Setup location search
    setupLocationSearch();
    
    // Setup location filter button
    setupLocationButton();
});

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
        renderError('alerts-content', 'שגיאה בטעינת אזעקות פיקוד העורף');
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
    
    const newsHtml = news.map(item => `
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
                description: 'אזעקה פעילה'
            }));
        } else {
            processedActiveAlerts = activeAlerts.map(alert => ({
                area: alert.data || alert.area || alert.title || alert,
                time: alert.alertDate || alert.time || new Date().toISOString(),
                isRecent: isRecentAlert(alert.alertDate || alert.time),
                isActive: true,
                description: alert.description || 'אזעקה פעילה'
            }));
        }
    }
    
    // Process historical alerts (already in correct format)
    const processedHistoricalAlerts = historicalAlerts || [];
    
    // Filter active alerts by location
    const filteredActiveAlerts = filterAlertsByLocation(processedActiveAlerts);
    
    // Always show active alerts status at the top
    let html = '';
    if (filteredActiveAlerts.length === 0) {
        if (selectedLocations.size > 0 && processedActiveAlerts.length > 0) {
            html += '<div class="no-alerts">✅ אין אזעקות פעילות באזורים הנבחרים</div>';
        } else {
            html += '<div class="no-alerts">✅ אין אזעקות פעילות</div>';
        }
    } else {
        html += `<div class="active-alerts-status">🚨 ${filteredActiveAlerts.length} אזעקות פעילות</div>`;
    }
    
    // Show historical alerts if available
    if (processedHistoricalAlerts.length > 0) {
        // Combine and sort all alerts  
        const allAlerts = [...processedActiveAlerts, ...processedHistoricalAlerts];
        allAlerts.sort((a, b) => new Date(b.time) - new Date(a.time));
        
        // Filter all alerts based on selected locations
        const filteredAllAlerts = filterAlertsByLocation(allAlerts);
        
        if (filteredAllAlerts.length > 0) {
            html += '<div class="alerts-history-header">היסטוריית אזעקות:</div>';
            
            const alertsHtml = filteredAllAlerts.map(alert => `
                <div class="alert-item ${alert.isRecent ? 'recent' : ''} ${alert.isActive ? 'active' : 'historical'}">
                    <h3>${alert.isActive ? '🚨' : '📍'} ${escapeHtml(alert.area)}</h3>
                    <div class="alert-description">${escapeHtml(alert.description || 'אזעקה')}</div>
                    <div class="time">${formatDate(alert.time)}</div>
                </div>
            `).join('');
            
            html += alertsHtml;
        }
    } else if (filteredActiveAlerts.length > 0) {
        // Only show active alerts if no historical data
        const alertsHtml = filteredActiveAlerts.map(alert => `
            <div class="alert-item ${alert.isRecent ? 'recent' : ''} ${alert.isActive ? 'active' : 'historical'}">
                <h3>${alert.isActive ? '🚨' : '📍'} ${escapeHtml(alert.area)}</h3>
                <div class="alert-description">${escapeHtml(alert.description || 'אזעקה')}</div>
                <div class="time">${formatDate(alert.time)}</div>
            </div>
        `).join('');
        
        html += alertsHtml;
    }
    
    alertsContent.innerHTML = html;
    
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

function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Handle visibility change to pause/resume updates
document.addEventListener('visibilitychange', function() {
    if (!document.hidden) {
        fetchAllData(); // Refresh when tab becomes visible
    }
});

// Keyboard shortcuts
document.addEventListener('keydown', function(e) {
    if (e.key === 'r' && (e.ctrlKey || e.metaKey)) {
        e.preventDefault();
        fetchAllData();
    }
});

// Location Management Functions
async function fetchLocations() {
    try {
        console.log('Fetching locations...');
        const response = await fetch('/api/alert-areas');
        if (!response.ok) throw new Error('Failed to fetch locations');
        
        availableLocations = await response.json();
        console.log('Locations fetched:', availableLocations.length);
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
    
    const locationsHtml = availableLocations.map((location, index) => `
        <div class="location-item">
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
    console.log('Toggling location selector, current classes:', selector.className);
    selector.classList.toggle('show');
    console.log('After toggle, classes:', selector.className);
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
}

function selectAllLocations() {
    selectedLocations.clear();
    availableLocations.forEach(location => selectedLocations.add(location));
    renderLocationList();
    updateSelectedLocationsDisplay();
    saveUserPreferences();
    renderAlerts(alertsData);
}

function clearAllLocations() {
    selectedLocations.clear();
    renderLocationList();
    updateSelectedLocationsDisplay();
    saveUserPreferences();
    renderAlerts(alertsData);
}

function applyLocationSelection() {
    // Close the location selector
    toggleLocationSelector();
    
    // Save preferences and update display
    saveUserPreferences();
    updateSelectedLocationsDisplay();
    
    // Re-render alerts with new filter
    renderAlerts(alertsData);
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
                if (locationName.includes(searchTerm)) {
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

function setupLocationButton() {
    const locationButton = document.querySelector('.location-filter');
    if (locationButton) {
        locationButton.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            console.log('Location button clicked');
            toggleLocationSelector();
        });
    }
    
    const closeButton = document.querySelector('.close-btn');
    if (closeButton) {
        closeButton.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            toggleLocationSelector();
        });
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
        activeCount = alertsData.active.length;
    }
    if (alertsData && alertsData.history) {
        totalCount = alertsData.history.length;
    }
    
    let summaryText;
    if (activeCount > 0) {
        summaryText = `🚨 ${activeCount} אזעקות פעילות`;
    } else if (totalCount > 0) {
        summaryText = `📍 ${totalCount} התרעות בהיסטוריה`;
    } else {
        summaryText = '🟢 אין אזעקות פעילות';
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
window.toggleLocation = toggleLocation;
window.selectAllLocations = selectAllLocations;
window.clearAllLocations = clearAllLocations;
window.applyLocationSelection = applyLocationSelection;
window.fetchNews = fetchNews;
window.fetchAlerts = fetchAlerts;
window.toggleAlertsPanel = toggleAlertsPanel;

// Service worker removed to avoid 404 errors
// Can be added later for offline functionality if needed
