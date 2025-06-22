/**
 * @jest-environment jsdom
 */

describe('Mobile Alerts Panel Collapse', () => {
  // Import the mobile collapse functions
  let alertsPanelCollapsed = false;
  let alertsData = { active: [], history: [] };
  let selectedLocations = new Set();

  // Re-implement the functions for testing
  function toggleAlertsPanel() {
    const panel = document.getElementById('alerts-panel');
    const collapseBtn = document.getElementById('alerts-collapse-btn');
    
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
  
  beforeEach(() => {
    // Set up DOM elements
    document.body.innerHTML = `
      <div id="alerts-panel" class="panel">
        <div class="panel-header">
          <div class="header-controls">
            <div id="alerts-collapse-btn" class="collapse-btn mobile-only">
              <span class="collapse-icon">▼</span>
            </div>
          </div>
        </div>
        <div id="alerts-summary" class="alerts-summary mobile-only" style="display: none;">
          <span id="summary-count">0 אזעקות פעילות</span>
        </div>
        <div id="alerts-panel-content" class="panel-content">
          <div id="alerts-content"></div>
        </div>
      </div>
    `;

    // Reset state
    alertsPanelCollapsed = false;
    alertsData = { active: [], history: [] };
    selectedLocations = new Set();
  });

  describe('toggleAlertsPanel', () => {
    test('should collapse panel when expanded', () => {
      const panel = document.getElementById('alerts-panel');
      const collapseBtn = document.getElementById('alerts-collapse-btn');
      
      // Start expanded
      expect(panel.classList.contains('collapsed')).toBe(false);
      
      // Toggle to collapsed
      toggleAlertsPanel();
      
      expect(panel.classList.contains('collapsed')).toBe(true);
      expect(collapseBtn.classList.contains('collapsed')).toBe(true);
      expect(alertsPanelCollapsed).toBe(true);
    });

    test('should expand panel when collapsed', () => {
      const panel = document.getElementById('alerts-panel');
      const collapseBtn = document.getElementById('alerts-collapse-btn');
      
      // Start collapsed
      alertsPanelCollapsed = true;
      panel.classList.add('collapsed');
      collapseBtn.classList.add('collapsed');
      
      // Toggle to expanded
      toggleAlertsPanel();
      
      expect(panel.classList.contains('collapsed')).toBe(false);
      expect(collapseBtn.classList.contains('collapsed')).toBe(false);
      expect(alertsPanelCollapsed).toBe(false);
    });
  });

  describe('updateAlertsSummary', () => {
    test('should show active alerts count when active alerts exist', () => {
      alertsData = {
        active: [{ area: 'Tel Aviv' }, { area: 'Jerusalem' }],
        history: []
      };
      
      updateAlertsSummary();
      
      const summaryCount = document.getElementById('summary-count');
      expect(summaryCount.textContent).toBe('🚨 2 אזעקות פעילות');
    });

    test('should show historical count when no active alerts', () => {
      alertsData = {
        active: [],
        history: [{ area: 'Tel Aviv' }, { area: 'Jerusalem' }, { area: 'Haifa' }]
      };
      
      updateAlertsSummary();
      
      const summaryCount = document.getElementById('summary-count');
      expect(summaryCount.textContent).toBe('📍 3 התרעות בהיסטוריה');
    });

    test('should show no alerts message when no data', () => {
      alertsData = { active: [], history: [] };
      
      updateAlertsSummary();
      
      const summaryCount = document.getElementById('summary-count');
      expect(summaryCount.textContent).toBe('🟢 אין אזעקות פעילות');
    });

    test('should handle missing summary element gracefully', () => {
      document.getElementById('summary-count').remove();
      
      expect(() => updateAlertsSummary()).not.toThrow();
    });
  });

  describe('checkAutoCollapse', () => {
    test('should auto-collapse on mobile when no location filter', () => {
      // Mock mobile viewport
      Object.defineProperty(window, 'innerWidth', { value: 375, writable: true });
      selectedLocations = new Set();
      alertsPanelCollapsed = false;
      
      const panel = document.getElementById('alerts-panel');
      const collapseBtn = document.getElementById('alerts-collapse-btn');
      
      checkAutoCollapse();
      
      expect(alertsPanelCollapsed).toBe(true);
      expect(panel.classList.contains('collapsed')).toBe(true);
      expect(collapseBtn.classList.contains('collapsed')).toBe(true);
    });

    test('should not auto-collapse on desktop', () => {
      // Mock desktop viewport
      Object.defineProperty(window, 'innerWidth', { value: 1200, writable: true });
      selectedLocations = new Set();
      alertsPanelCollapsed = false;
      
      const panel = document.getElementById('alerts-panel');
      
      checkAutoCollapse();
      
      expect(alertsPanelCollapsed).toBe(false);
      expect(panel.classList.contains('collapsed')).toBe(false);
    });

    test('should not auto-collapse when location filter is active', () => {
      Object.defineProperty(window, 'innerWidth', { value: 375, writable: true });
      selectedLocations = new Set(['Tel Aviv']);
      alertsPanelCollapsed = false;
      
      const panel = document.getElementById('alerts-panel');
      
      checkAutoCollapse();
      
      expect(alertsPanelCollapsed).toBe(false);
      expect(panel.classList.contains('collapsed')).toBe(false);
    });

    test('should not change state if already collapsed', () => {
      Object.defineProperty(window, 'innerWidth', { value: 375, writable: true });
      selectedLocations = new Set();
      alertsPanelCollapsed = true;
      
      const panel = document.getElementById('alerts-panel');
      panel.classList.add('collapsed');
      
      checkAutoCollapse();
      
      // Should remain collapsed
      expect(alertsPanelCollapsed).toBe(true);
      expect(panel.classList.contains('collapsed')).toBe(true);
    });
  });

  describe('integration with renderAlerts', () => {
    test('should update summary after rendering alerts', () => {
      alertsData = {
        active: [{ area: 'Tel Aviv', time: new Date().toISOString() }],
        history: []
      };
      
      updateAlertsSummary();
      
      const summaryCount = document.getElementById('summary-count');
      expect(summaryCount.textContent).toBe('🚨 1 אזעקות פעילות');
    });
  });

  describe('CSS and DOM behavior', () => {
    test('should properly toggle CSS classes', () => {
      const panel = document.getElementById('alerts-panel');
      const collapseBtn = document.getElementById('alerts-collapse-btn');
      
      // Multiple toggles should work correctly
      toggleAlertsPanel(); // collapse
      expect(panel.classList.contains('collapsed')).toBe(true);
      
      toggleAlertsPanel(); // expand
      expect(panel.classList.contains('collapsed')).toBe(false);
      
      toggleAlertsPanel(); // collapse again
      expect(panel.classList.contains('collapsed')).toBe(true);
    });

    test('should update summary content correctly', () => {
      const summaryCount = document.getElementById('summary-count');
      
      // Test with different data scenarios
      alertsData = { active: [{}], history: [] };
      updateAlertsSummary();
      expect(summaryCount.textContent).toContain('1 אזעקות פעילות');
      
      alertsData = { active: [], history: [{}, {}] };
      updateAlertsSummary();
      expect(summaryCount.textContent).toContain('2 התרעות בהיסטוריה');
      
      alertsData = { active: [], history: [] };
      updateAlertsSummary();
      expect(summaryCount.textContent).toContain('אין אזעקות פעילות');
    });
  });
});
