let lastUpdate = null;
let newsData = [];
let alertsData = [];
let availableLocations = [];
let selectedLocations = new Set();

// WebSocket connection state
let ws = null;
let wsReconnectAttempts = 0;
let maxReconnectAttempts = 5;
let fallbackPolling = null;

// Initialize the application
document.addEventListener('DOMContentLoaded', function() {
    console.log('War Room initialized');
    loadUserPreferences();
    fetchLocations();
    
    // Initialize WebSocket connection with fallback
    initializeRealTimeUpdates();
    
    // Update time display every second
    setInterval(updateTimeDisplay, 1000);
    
    // Setup location search
    setupLocationSearch();
    
    // Setup location filter button
    setupLocationButton();
});

async function fetchAllData() {
    await Promise.all([fetchNews(), fetchAlerts()]);
    lastUpdate = new Date();
    updateConnectionStatus(true);
}

async function fetchNews() {
    try {
        const newsPanel = document.getElementById('news-content');
        
        const response = await fetch('/api/ynet');
        if (!response.ok) throw new Error('Network response was not ok');
        
        const data = await response.json();
        newsData = data;
        
        renderNews(data);
        animateUpdate('news-panel');
        
    } catch (error) {
        console.error('Error fetching news:', error);
        updateConnectionStatus(false);
        renderError('news-content', 'שגיאה בטעינת חדשות ynet');
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

function renderNews(news) {
    const newsContent = document.getElementById('news-content');
    
    if (!news || news.length === 0) {
        newsContent.innerHTML = '<div class="no-alerts">אין מבזקים חדשים</div>';
        return;
    }
    
    const newsHtml = news.map(item => `
        <div class="news-item">
            <h3>${escapeHtml(item.title)}</h3>
            ${item.description ? `<p>${escapeHtml(item.description.substring(0, 200))}...</p>` : ''}
            <div class="meta">
                <span>${formatDate(item.pubDate)}</span>
                <a href="${item.link}" target="_blank" rel="noopener">קרא עוד ↗</a>
            </div>
        </div>
    `).join('');
    
    newsContent.innerHTML = newsHtml;
}

function renderAlerts(alerts) {
    const alertsContent = document.getElementById('alerts-content');
    
    if (!alerts || alerts.length === 0) {
        alertsContent.innerHTML = '<div class="no-alerts">✅ אין אזעקות פעילות</div>';
        return;
    }
    
    // Handle different alert data structures
    let processedAlerts = [];
    
    if (Array.isArray(alerts)) {
        // Check if it's the oref.org.il format
        if (alerts.length > 0 && typeof alerts[0] === 'string') {
            processedAlerts = alerts.map(alert => ({
                area: alert,
                time: new Date().toISOString(),
                isRecent: true
            }));
        } else {
            // Handle tzevaadom format or other structures
            processedAlerts = alerts.map(alert => ({
                area: alert.data || alert.area || alert.title || alert,
                time: alert.alertDate || alert.time || new Date().toISOString(),
                isRecent: isRecentAlert(alert.alertDate || alert.time)
            }));
        }
    }
    
    // Filter alerts based on selected locations
    const filteredAlerts = filterAlertsByLocation(processedAlerts);
    
    if (filteredAlerts.length === 0 && selectedLocations.size > 0) {
        alertsContent.innerHTML = '<div class="no-alerts">✅ אין אזעקות באזורים הנבחרים</div>';
        return;
    }
    
    const alertsHtml = filteredAlerts.map(alert => `
        <div class="alert-item ${alert.isRecent ? 'recent' : ''}">
            <h3>🚨 ${escapeHtml(alert.area)}</h3>
            <div class="time">${formatDate(alert.time)}</div>
        </div>
    `).join('');
    
    alertsContent.innerHTML = alertsHtml;
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

function updateTimeDisplay() {
    const updateElement = document.getElementById('last-update');
    if (lastUpdate) {
        const timeAgo = formatTimeAgo(lastUpdate);
        updateElement.textContent = `עדכון אחרון: ${timeAgo}`;
    }
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

function formatTimeAgo(date) {
    const now = new Date();
    const diffMs = now - date;
    const diffSecs = Math.floor(diffMs / 1000);
    const diffMins = Math.floor(diffMs / 60000);
    
    if (diffSecs < 60) return `לפני ${diffSecs} שניות`;
    if (diffMins < 60) return `לפני ${diffMins} דקות`;
    
    return date.toLocaleTimeString('he-IL', {
        hour: '2-digit',
        minute: '2-digit'
    });
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
            if (alertArea.includes(selectedLocation) || selectedLocation.includes(alertArea)) {
                return true;
            }
        }
        
        return false;
    });
}

function loadUserPreferences() {
    try {
        const saved = localStorage.getItem('war-room-locations');
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
        localStorage.setItem('war-room-locations', JSON.stringify(Array.from(selectedLocations)));
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

// Service worker removed to avoid 404 errors
// Can be added later for offline functionality if needed

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
                populateLocationDropdown();
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
    const statusElement = document.getElementById('connectionStatus');
    if (!statusElement) {
        // Create status indicator if it doesn't exist
        const header = document.querySelector('.header');
        if (header) {
            const statusDiv = document.createElement('div');
            statusDiv.id = 'connectionStatus';
            statusDiv.style.cssText = 'position: absolute; top: 10px; right: 10px; padding: 5px 10px; border-radius: 5px; font-size: 12px; color: white;';
            header.appendChild(statusDiv);
        }
    }
    
    const statusElement2 = document.getElementById('connectionStatus');
    if (statusElement2) {
        switch (status) {
            case 'connected':
                statusElement2.textContent = '● Real-time';
                statusElement2.style.backgroundColor = '#4CAF50';
                break;
            case 'polling':
                statusElement2.textContent = '◐ Polling';
                statusElement2.style.backgroundColor = '#FF9800';
                break;
            case 'disconnected':
            case 'error':
                statusElement2.textContent = '○ Offline';
                statusElement2.style.backgroundColor = '#F44336';
                break;
        }
    }
}
